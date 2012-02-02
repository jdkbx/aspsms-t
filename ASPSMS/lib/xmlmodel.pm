# aspsms-t
# http://www.swissjabber.ch/
# https://github.com/micressor/aspsms-t
#
# Copyright (C) 2006-2012 Marco Balmer <marco@balmer.name>
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published
# by the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301,
# USA.

package ASPSMS::xmlmodel;

use strict;
use vars qw(@EXPORT @ISA);
use Exporter;

@ISA 			= qw(Exporter);
@EXPORT 		= qw(xmlShowCredits xmlSendTextSMS xmlSendBinarySMS xmlSendWAPPushSMS xmlGenerateRequest);

########################################################################
sub xmlShowCredits {
########################################################################

my $login 		= shift;
my $password		= shift;

my $aspsmsrequest = 

"<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>
<aspsms>
 <Userkey>" . $login ."</Userkey>
 <Password>" . $password . "</Password>
 <Action>ShowCredits</Action>
</aspsms>
\r\n\r\r\n";

return $aspsmsrequest;

########################################################################
}
########################################################################

########################################################################
sub xmlSendTextSMS {
########################################################################

my $login               = shift;
my $password            = shift;
my $originator		= shift;
my $target		= shift;
my $mess		= shift;
my $random		= shift;
my $jid			= shift;
my $numbernotification	= shift;
my $affiliateid		= shift;
my $msg_id		= shift;
my $msg_type		= shift;

#
# fix right url encoding for aspsms xmlsrv
#
$ASPSMS::config::notificationurl = PrepareCharSet($ASPSMS::config::notificationurl);

#
# Prepare charset
#
$mess 	= PrepareCharSet($mess);

my $aspsmsrequest =

"<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>
<aspsms>
 <Userkey>" . $login ."</Userkey>
 <Password>" . $password . "</Password>
 <Originator>" . $originator  . "</Originator>
 <Recipient>
  <PhoneNumber>" . $target . "</PhoneNumber>
  <TransRefNumber>" . $random ."</TransRefNumber>
 </Recipient>
 <URLDeliveryNotification>$ASPSMS::config::notificationurl?xml=notify,,,".$random.",,,".$msg_id.",,,".$msg_type.",,,".$login.",,,".$numbernotification.",,,Delivered,,,</URLDeliveryNotification>
 <URLNonDeliveryNotification>$ASPSMS::config::notificationurl?xml=notify,,,".$random.",,,".$msg_id.",,,".$msg_type.",,,".$login.",,,".$numbernotification.",,,NonDelivered,,,</URLNonDeliveryNotification>
 <URLBufferedMessageNotification>$ASPSMS::config::notificationurl?xml=notify,,,".$random.",,,".$msg_id.",,,".$msg_type.",,,".$login.",,,".$numbernotification.",,,Buffered,,,</URLBufferedMessageNotification>
 <MessageData>" .$mess . "</MessageData>
 <Action>SendTextSMS</Action>
 <UsedCredits>1</UsedCredits>
 <AffiliateId>$affiliateid</AffiliateId>
</aspsms>
\r\n\r\r\n";


return $aspsmsrequest;

########################################################################
}
########################################################################

########################################################################
sub xmlSendBinarySMS {
########################################################################

my $login               = shift;
my $password            = shift;
my $originator		= shift;
my $target		= shift;
my $mess		= shift;
my $random		= shift;
my $jid			= shift;
my $numbernotification	= shift;
my $affiliateid		= shift;
my $msg_id		= shift;
my $msg_type		= shift;

#
# fix right url encoding for aspsms xmlsrv
#
$ASPSMS::config::notificationurl = PrepareCharSet($ASPSMS::config::notificationurl);

#
# Prepare charset
#
$mess 	= PrepareCharSet($mess);

my $aspsmsrequest =

"<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>
<aspsms>
 <Userkey>" . $login ."</Userkey>
 <Password>" . $password . "</Password>
 <Originator>" . $originator  . "</Originator>
 <Recipient>
  <PhoneNumber>" . $target . "</PhoneNumber>
  <TransRefNumber>" . $random ."</TransRefNumber>
 </Recipient>
 <URLDeliveryNotification>$ASPSMS::config::notificationurl?xml=notify,,,".$random.",,,".$msg_id.",,,".$msg_type.",,,".$login.",,,".$numbernotification.",,,Delivered,,,</URLDeliveryNotification>
 <URLNonDeliveryNotification>$ASPSMS::config::notificationurl?xml=notify,,,".$random.",,,".$msg_id.",,,".$msg_type.",,,".$login.",,,".$numbernotification.",,,NonDelivered,,,</URLNonDeliveryNotification>
 <URLBufferedMessageNotification>$ASPSMS::config::notificationurl?xml=notify,,,".$random.",,,".$msg_id.",,,".$msg_type.",,,".$login.",,,".$numbernotification.",,,Buffered,,,</URLBufferedMessageNotification>
 <MessageData>" .$mess . "</MessageData>
 <XSer>020108</XSer>
 <Action>SendBinaryData</Action>
 <UsedCredits>1</UsedCredits>
 <AffiliateId>$affiliateid</AffiliateId>
</aspsms>
\r\n\r\r\n";


return $aspsmsrequest;

########################################################################
} ### xmlSendBinarySMS
########################################################################

########################################################################
sub xmlSendWAPPushSMS {
########################################################################

my $login               = shift;
my $password            = shift;
my $originator		= shift;
my $target		= shift;
my $mess		= shift;
my $url			= shift;
my $random		= shift;
my $jid			= shift;
my $numbernotification	= shift;
my $affiliateid		= shift;
my $msg_id		= shift;
my $msg_type		= shift;

$mess 	= PrepareCharSet($mess);
$url 	= PrepareCharSet($url);


# fix right url encoding for aspsms xmlsrv
$ASPSMS::config::notificationurl = PrepareCharSet($ASPSMS::config::notificationurl);

my $aspsmsrequest =

"<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>
<aspsms>
 <Userkey>" . $login ."</Userkey>
 <Password>" . $password . "</Password>
 <Originator>" . $originator  . "</Originator>
 <Recipient>
  <PhoneNumber>" . $target . "</PhoneNumber>
  <TransRefNumber>" . $random ."</TransRefNumber>
 </Recipient>
 <WAPPushDescription>" .$mess . "</WAPPushDescription>
 <WAPPushURL>".$url."</WAPPushURL>
 <Action>SendWAPPushSMS</Action>
 <AffiliateId>$affiliateid</AffiliateId>
</aspsms>
\r\n\r\r\n";


return $aspsmsrequest;

########################################################################
}
########################################################################

########################################################################
sub xmlGenerateRequest {
########################################################################

my $aspsmsrequest	= shift;
my $requestlength 	= length($aspsmsrequest);

my $aspsmsheader = "
POST /xmlsvr.asp HTTP/1.0
Content-Type: text/xml
Content-Length: $requestlength \r\n";

my $completerequest = $aspsmsheader . "\n". $aspsmsrequest;


return $completerequest;

########################################################################
}
########################################################################

########################################################################
sub PrepareCharSet {
########################################################################
my $data = shift;

#
# With this line enabled, delivery notification does not work.
# /maba 24.09.2007
#
#$data =~ s/\&/\&\#38\;/g;

$data =~ s/\:/\&\#58\;/g;
$data =~ s/\</\&\#60\;/g;
$data =~ s/\>/\&\#62\;/g;

return $data;

########################################################################
}
########################################################################

1;

