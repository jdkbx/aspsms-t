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

package ASPSMS::Sendaspsms;

use strict;
use vars qw(@EXPORT @ISA);
use ASPSMS::aspsmstlog;
use ASPSMS::Connection;
use ASPSMS::userhandler;
use ASPSMS::xmlmodel;
use ASPSMS::Regex;

use Exporter;
use IO::Socket;


use Sys::Syslog;

openlog($config::ident,'','user');


@ISA 				= qw(Exporter);
@EXPORT 			= qw(Sendaspsms);


my $banner			= 	$config::banner;
my $aspsmssocket		= 	$config::aspsmssocket;
my $aspsms_ip                   =       $config::aspsms_ip;
my $aspsms_port                 =       $config::aspsms_port;



########################################################################
sub Sendaspsms {
# #######################################################################
aspsmst_log('notice',"Sendaspsms(): Begin");
my ($number, $from, $msg) = @_;
my $xmppanswer;
$number = substr($number, 1, 50);

my $user = getUserPass($from,$banner);

if($user->{name} eq '')
                        {
                            aspsmst_log('info',"Sendaspsms(): \"First, you  need to register for using aspsms gateway\" sent to $from");
                            return (99,"First, you need to register for using aspsms gateway system on http://www.aspsms.com");
                        }


aspsmst_log('notice',"Sendaspsms(): sending message to number $number");

my ($result,$resultdesc,$Credits,$CreditsUsed,$random) = exec_SendTextSMS($number, $msg, $user->{name}, $user->{password},$user->{phone},$user->{signature},$from);


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

aspsmst_log('notice',"Sendaspsms(): End $xmppanswerlog");
return ($result,$resultdesc,$Credits,$CreditsUsed);

########################################################################
}
########################################################################

1;

