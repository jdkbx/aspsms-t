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

package ASPSMS::xmlmodel;

use strict;
use vars qw(@EXPORT @ISA);
use Exporter;

@ISA 			= qw(Exporter);
@EXPORT 		= qw(xmlShowCredits xmlSendTextSMS xmlSendWAPPushSMS xmlGenerateRequest);

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
$config::notificationurl =~ s/\:/\&\#58\;/g;

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
	<URLDeliveryNotification>$config::notificationurl?xml=notify,,,".$random.",,,".$msg_id.",,,".$msg_type.",,,".$login.",,,".$numbernotification.",,,Delivered,,,</URLDeliveryNotification>
	<URLNonDeliveryNotification>$config::notificationurl?xml=notify,,,".$random.",,,".$msg_id.",,,".$msg_type.",,,".$login.",,,".$numbernotification.",,,NonDelivered,,,</URLNonDeliveryNotification>
	<URLBufferedMessageNotification>$config::notificationurl?xml=notify,,,".$random.",,,".$msg_id.",,,".$msg_type.",,,".$login.",,,".$numbernotification.",,,Buffered,,,</URLBufferedMessageNotification>
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
$config::notificationurl =~ s/\:/\&\#58\;/g;

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

my $completerequest = $aspsmsheader . $aspsmsrequest;


return $completerequest;

########################################################################
}
########################################################################

########################################################################
sub PrepareCharSet {
########################################################################
my $data = shift;

$data =~ s/:/&#58;/g;

return $data;

########################################################################
}
########################################################################

1;

