# aspsms-t by Marco Balmer <mb@micressor.ch> @2004
# http://web.swissjabber.ch/
# http://www.micressor.ch/content/projects/aspsms-t/
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

package ASPSMS::handler;

use strict;
use vars qw(@EXPORT @ISA);
use ASPSMS::aspsmstlog;
use Exporter;
use IO::Socket;

use ASPSMS::userhandler;
use ASPSMS::xmlmodel;

use Sys::Syslog;

openlog($config::ident,'','user');


@ISA 				= qw(Exporter);
@EXPORT 			= qw(Sendaspsms CheckNewUser);


my $banner			= 	$config::banner;
my $aspsmssocket		= 	$config::aspsmssocket;
my $aspsms_ip                   =       $config::aspsms_ip;
my $aspsms_port                 =       $config::aspsms_port;



########################################################################
sub Sendaspsms {
########################################################################
my ($number, $from, $msg) = @_;
my $xmppanswer;
$number = substr($number, 1, 50);

my $user = getUserPass($from,$banner);

if($user->{name} eq '')
                        {
                            aspsmst_log('info',"hander::sendaspsms(): \"First, you  need to register for using aspsms gateway\" sent to $from");
                            return (99,"First, you need to register for using aspsms.");
                        }


aspsmst_log('notice',"handler::sendaspsms(): sending message to number $number");

my ($result,$resultdesc,$Credits,$CreditsUsed,$random) = send_aspsms($number, $msg, $user->{name}, $user->{password},$user->{phone},$user->{signature},$from);


if ($result == 1) { $config::Message_Counter++; } else { $config::Message_Counter_Error++; }

my ($xmppanswerlog);
$xmppanswerlog = "SMS from $from to $number (Balance: $Credits Used: $CreditsUsed) has status --> $result ($resultdesc)";

if ($result == 1) {

$xmppanswer = "
Status(for SMS $random) --> $resultdesc 

Balance: $Credits / Used: $CreditsUsed 

SMS (for $number):
$msg

$config::ident Gateway system v$config::release
";

$resultdesc = $xmppanswer;
}

aspsmst_log('notice',"hander.sendaspsms(): $xmppanswerlog");

return ($result,$resultdesc,$Credits,$CreditsUsed);

########################################################################
}
########################################################################

########################################################################
sub send_aspsms {
########################################################################
my $number              = shift;
my $mess                = shift;
my $login               = shift;
my $password            = shift;
my $phone               = shift;
my $signature           = shift;
my $jid			= shift;
my $numbernotification 	= $number;
($mess,$number,$signature) = regexes($mess,$number,$signature);

##########################################################################
# Generate SMS Request
##########################################################################
my $aspsmsrequest;

my $random = int( rand(1000)) + 1000;

$aspsmsrequest          = xmlSendTextSMS($login,$password,$phone,$number,$mess,$random,$jid,$numbernotification,$config::affiliateid);
my $completerequest     = xmlGenerateRequest($aspsmsrequest);

##########################################################################
# /Generate SMS Request
##########################################################################


unless(connect_aspsms() eq '0') {
return ('-1','Sorry, aspsms are temporary not available. Please try again later or contact your administrator of http://www.aspsms.com'); }

print $aspsmssocket $completerequest;

my @answer;

eval {

alarm(60);

@answer = <$aspsmssocket>;

alarm(0);

     };

# If alarm do action
if($@) {
aspsmst_log('info',"aspsmshandler:send_aspsms(): No response of aspsms after sent request");
return ('-21','No response of aspsms after sent request. Please try again later or contact your transport administrator.');
}


disconnect_aspsms();

# Parse XML of SMS request
my $DeliveryStatus      =       XML::Smart->new($answer[10]);
my $ErrorCode           =       $DeliveryStatus->{aspsms}{ErrorCode};
my $ErrorDescription    =       $DeliveryStatus->{aspsms}{ErrorDescription};
my $CreditsUsed         =       $DeliveryStatus->{aspsms}{CreditsUsed};

##########################################################################
# Generate ShowCredits Request
##########################################################################

$aspsmsrequest          = xmlShowCredits($login,$password);
$completerequest     = xmlGenerateRequest($aspsmsrequest);

##########################################################################
# /Generate ShowCredits Request
##########################################################################

unless(connect_aspsms() eq '0') {
my $value1 = $_[0]; my $value2 = $_[1];
return ($value1,$value2); }
print $aspsmssocket $completerequest;

@answer = <$aspsmssocket>;

disconnect_aspsms();

my $CreditStatus        =       XML::Smart->new($answer[10]);
my $Credits             =       $CreditStatus->{aspsms}{Credits};


return ($ErrorCode,$ErrorDescription,$Credits,$CreditsUsed,$random);
########################################################################
}
########################################################################

########################################################################
sub connect_aspsms {
########################################################################


$aspsmssocket = IO::Socket::INET->new(     PeerAddr => $aspsms_ip,
                                        PeerPort => $aspsms_port,
                                        Proto    => 'tcp',
                                        Timeout  => 5,
                                        Type     => SOCK_STREAM) or return -1;

return 0;

}

sub disconnect_aspsms {


close($aspsmssocket);

########################################################################
}
########################################################################

##########################################################################
sub CheckNewUser { 
###########################################################################

my $username =	shift;
my $password = 	shift;
my @answer;

aspsmst_log('info',"handler::CheckNewUser(): Check new user on aspsms xml-server $username/$password");
unless(connect_aspsms() eq '0') {
my $value1 = $_[0]; my $value2 = $_[1];
return ($value1,$value2); }

my $aspsmsrequest       = xmlShowCredits($username,$password);
my $completerequest    	= xmlGenerateRequest($aspsmsrequest);


print $aspsmssocket $completerequest;
@answer = <$aspsmssocket>;
disconnect_aspsms();

my $ErrorStatus         =       XML::Smart->new($answer[10]);
my $ErrorCode           =       $ErrorStatus->{aspsms}{ErrorCode};
my $ErrorDescription    =       $ErrorStatus->{aspsms}{ErrorDescription};

aspsmst_log('info',"handler::CheckNewUser(): Result for $username is: $ErrorDescription");
$ErrorDescription = "This user does\'n exist at aspsms.com. Please register first an user on http://www.aspsms.com then try again.";

return ($ErrorCode,$ErrorDescription);


}


########################################################################
sub regexes {
########################################################################
my $mess        = shift;
my $number      = shift;
my $signature   = shift;

        # Translations / Substitutionen
        $number         = "00" . $number;
        $mess =~ s/\xC3(.)/chr(ord($1)+64)/egs;

	# stupid aspsms xmlsrv failure fixes. These are characters,
	# the aspsms xml server has problems. 
	$mess =~ s/\:/\;/g;
	$mess =~ s/\;\;/\:/g;
	$mess =~ s/\&//g;
	$mess =~ s/\|//g;
	$mess =~ s/\>//g;
	$mess =~ s/\<//g;
	$mess =~ s/\'//g;
        
	my $mess_length = length($mess);
        my $signature_length    = length($signature);

        my $sms_length =  $mess_length + $signature_length;

        if ($sms_length <=160)
                                {
                                aspsmst_log('notice',"handler::regexes(): Signature: enabled");
                                $mess = $mess . " " . $signature;
                                }
return ($mess,$number);
########################################################################
}
########################################################################


1;

