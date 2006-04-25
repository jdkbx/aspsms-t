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

package ASPSMS::Connection;

use strict;
use vars qw(@EXPORT @ISA);
use Exporter;

@ISA                    = qw(Exporter);
@EXPORT                 = qw(exec_SendTextSMS ConnectAspsms DisconnectAspsms exec_ConnectionASPSMS);

use config;
use IO::Socket;
use ASPSMS::aspsmstlog;
use ASPSMS::xmlmodel;
use ASPSMS::Regex;


use Sys::Syslog;

openlog($config::ident,'','user');





sub exec_SendTextSMS 
 {
   aspsmst_log('notice',"exec_SendTextSMS(): Begin");
	my $number              = shift;
	my $numbernotification 	= $number;
	my $mess                = shift;
	my $login               = shift;
	my $password            = shift;
	my $phone               = shift;
	my $signature           = shift;
	my $jid			= shift;
	($mess,$number,$signature) = regexes($mess,$number,$signature);

	# Generate SMS Request
	my $aspsmsrequest;
	my $random = int( rand(10000)) + 10000;
	$aspsmsrequest = xmlSendTextSMS(	$login,
						$password,
						$phone,
						$number,
						$mess,
						$random,
						$jid,
						$numbernotification,
						$config::affiliateid);

	my $completerequest     = xmlGenerateRequest($aspsmsrequest);
	my @ret_CompleteRequest = exec_ConnectionASPSMS($completerequest);


# Parse XML of SMS request
my $DeliveryStatus      =       XML::Smart->new($ret_CompleteRequest[10]);
my $ErrorCode           =       $DeliveryStatus->{aspsms}{ErrorCode};
my $ErrorDescription    =       $DeliveryStatus->{aspsms}{ErrorDescription};
my $CreditsUsed         =       $DeliveryStatus->{aspsms}{CreditsUsed};

##########################################################################
# Generate ShowCredits Request
##########################################################################

$aspsmsrequest          = xmlShowCredits($login,$password);
$completerequest     = xmlGenerateRequest($aspsmsrequest);

my @ret_CompleteRequest_ShowCredits = exec_ConnectionASPSMS($completerequest);

DisconnectAspsms();

my $CreditStatus        =       XML::Smart->new($ret_CompleteRequest_ShowCredits[10]);
my $Credits             =       $CreditStatus->{aspsms}{Credits};


aspsmst_log('info',"exec_SendTextSMS($jid): TransID: $random");
aspsmst_log('notice',"exec_SendTextSMS(): return ($ErrorCode,$ErrorDescription,$Credits,$CreditsUsed,$random)");
return ($ErrorCode,$ErrorDescription,$Credits,$CreditsUsed,$random);
########################################################################
}
########################################################################

sub exec_ConnectionASPSMS
 {
  aspsmst_log('debug',"exec_ConnectionASPSMS(): Begin");
  my $completerequest = shift;
	
  # /Generate SMS Request
  unless(ConnectAspsms() eq '0') 
   { return ('-1','Sorry, aspsms are temporary not available. Please try again later or contact your administrator of http://www.aspsms.com'); }
 
  # Send request to socket
  aspsmst_log('debug',"exec_ConnectionASPSMS(): Sending: $completerequest");
  print $config::aspsmssocket $completerequest;

  my @answer;

  eval 
   {
    # Timeout alarm
    alarm(10);
    @answer = <$config::aspsmssocket>;
    aspsmst_log('debug',"exec_ConnectionASPSMS(): \@answer=@answer");
    alarm(0);
   };

   # If alarm do action
   if($@) 
    {
     aspsmst_log('info',"exec_ConnectionASPSMS(): No response of aspsms after sent request");
     return ('-21','exec_ConnectionASPSMS(): No response of aspsms after sent request. Please try again later or contact your transport administrator.');
    } ### END of exec_ConnectionASPSMS ###

    DisconnectAspsms();
    aspsmst_log('notice',"exec_ConnectionASPSMS(): End");
    return (@answer);
 } ### END of exec_ConnectionASPSMS ###


########################################################################
sub ConnectAspsms {
########################################################################
my $status = 0;


aspsmst_log('debug',"ConnectAspsms(): Connecting to $config::aspsms_ip:$config::aspsms_port");
$config::aspsmssocket = IO::Socket::INET->new(     	PeerAddr => $config::aspsms_ip,
                                        		PeerPort => $config::aspsms_port,
                                        		Proto    => 'tcp',
                                        		Timeout  => 5,
                                        		Type     => SOCK_STREAM) or $status = -1;

aspsmst_log('notice',"ConnectAspsms(): status=$status");
return $status;
}

sub DisconnectAspsms {
aspsmst_log('notice',"DisconnectAspsms()");
close($config::aspsmssocket);

########################################################################
}
########################################################################

1;

