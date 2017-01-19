# http://www.swissjabber.ch/
# https://github.com/micressor/aspsms-t
#
# Copyright (C) 2006-2012 Marco Balmer <marco@balmer.name>
# adapted by jdkbx from xmlmodel.pm
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

=head1 NAME

aspsms-t - soap model/templates for aspsms webservice.

=head1 METHODS

=cut

package ASPSMS::soapmodel;

use strict;
use vars qw(@EXPORT @ISA);
use Exporter;

@ISA 			= qw(Exporter);
@EXPORT 		= qw(soapShowCredits soapSendTextSMS soapSendBinarySMS soapSendWAPPushSMS soapGetStatusCodeDescription);

use SOAP::Lite;
use ASPSMS::aspsmstlog;

########################################################################
sub soapGetStatusCodeDescription {
########################################################################

my $statusCode = shift;

=head2 soapGetStatusCodeDescription()

This function gets the errordescription to an errorcode through an
aspsms soap request.

my $errmessage = soapGetStatusCodeDescription($errorcode)

=cut
	
my $soap = SOAP::Lite->new( proxy => "$ASPSMS::config::aspsmsserver"
  , ssl_opts => {
    SSL_ca_path => '/etc/ssl/certs'
  }
);

$soap->on_action( sub { "https://webservice.aspsms.com/aspsmsx2.asmx/GetStatusCodeDescription" });
$soap->autotype(0);
$soap->default_ns('https://webservice.aspsms.com/aspsmsx2.asmx');
my $som = $soap->call('GetStatusCodeDescription',
  SOAP::Data->name('StatusCode')->value($statusCode)
);

return $som->result;

}


########################################################################
sub soapShowCredits {
########################################################################

my $login 		= shift;
my $password		= shift;

=head2 soapShowCredits()

This function contains an aspsms soap request to query credit balance.

=cut

my $soap = SOAP::Lite->new( proxy => "$ASPSMS::config::aspsmsserver"
  , ssl_opts => {
    SSL_ca_path => '/etc/ssl/certs'
  }
);

$soap->on_action( sub { "https://webservice.aspsms.com/aspsmsx2.asmx/CheckCredits" });
$soap->autotype(0);
$soap->default_ns('https://webservice.aspsms.com/aspsmsx2.asmx');
my $som = $soap->call('CheckCredits',
  SOAP::Data->name('UserKey')->value($login),
  SOAP::Data->name('Password')->value($password)
);

my $credits             =       $som->result;
my $ErrorCode           = 1;
my $ErrorDescription    = "OK";

unless (substr($credits, 0, 8) eq "Credits:" ) {
 $ErrorCode        = substr($credits, 11, length($credits) - 11);
 $ErrorDescription = soapGetStatusCodeDescription($ErrorCode);
}

unless($ErrorCode == 1)
 {
  return $ErrorDescription;
 } ### unless($ErrorCode == 1)

=head2

And finally we return the parsed credit balance back.

=cut

return (substr($credits, 8, length($credits) - 8));

########################################################################
}
########################################################################

########################################################################
sub soapSendTextSMS {
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

=head2 soapSendTextSMS()

This function contains an aspsms soap request to send a normal text sms.

=cut

aspsmst_log('debug',"id:$random soapSendTextSMS(): " .
	"Begin");

aspsmst_log('debug',"id:$random notificationurl: " .
	"$ASPSMS::config::notificationurl");

my $soap = SOAP::Lite->new( proxy => "$ASPSMS::config::aspsmsserver"
  , ssl_opts => {
    SSL_ca_path => '/etc/ssl/certs'
  }
);

$soap->on_action( sub { "https://webservice.aspsms.com/aspsmsx2.asmx/SendTextSMS" });
$soap->autotype(0);
$soap->default_ns('https://webservice.aspsms.com/aspsmsx2.asmx');
my $som = $soap->call('SendTextSMS',
  SOAP::Data->name('UserKey')->value($login),
  SOAP::Data->name('Password')->value($password),
  SOAP::Data->name('Recipients')->value($target.":".$random),
  SOAP::Data->name('Originator')->value($originator),
  SOAP::Data->name('MessageText')->value($mess),
#  SOAP::Data->name('DeferredDeliveryTime')->value(''),
#  SOAP::Data->name('FlashingSMS')->value(''),
#  SOAP::Data->name('TimeZone')->value(''),
  SOAP::Data->name('URLBufferedMessageNotification')->value($ASPSMS::config::notificationurl."?xml=notify,,,".$random.",,,".$msg_id.",,,".$msg_type.",,,".$login.",,,".$numbernotification.",,,Buffered,,,"),
  SOAP::Data->name('URLDeliveryNotification')->value($ASPSMS::config::notificationurl."?xml=notify,,,".$random.",,,".$msg_id.",,,".$msg_type.",,,".$login.",,,".$numbernotification.",,,Delivered,,,"),
  SOAP::Data->name('URLNonDeliveryNotification')->value($ASPSMS::config::notificationurl."?xml=notify,,,".$random.",,,".$msg_id.",,,".$msg_type.",,,".$login.",,,".$numbernotification.",,,NonDelivered,,,")
#  SOAP::Data->name('AffiliateId')->value($affiliateid)
);

aspsmst_log('debug',"id:$random soapSendTextSMS(): " .
	"End");

return $som;

########################################################################
}
########################################################################

########################################################################
sub soapSendBinarySMS {
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

=head2 soapSendBinarySMS()

This function contains an aspsms soap request to send a binary sms.

=cut

my $soap = SOAP::Lite->new( proxy => "$ASPSMS::config::aspsmsserver"
  , ssl_opts => {
    SSL_ca_path => '/etc/ssl/certs'
  }
);

$soap->on_action( sub { "https://webservice.aspsms.com/aspsmsx2.asmx/SendUnicodeSMS" });
$soap->autotype(0);
$soap->default_ns('https://webservice.aspsms.com/aspsmsx2.asmx');
my $som = $soap->call('SendUnicodeSMS',
  SOAP::Data->name('UserKey')->value($login),
  SOAP::Data->name('Password')->value($password),
  SOAP::Data->name('Recipients')->value($target.":".$random),
  SOAP::Data->name('Originator')->value($originator),
  SOAP::Data->name('MessageText')->value($mess),
#  SOAP::Data->name('DeferredDeliveryTime')->value(''),
#  SOAP::Data->name('FlashingSMS')->value(''),
#  SOAP::Data->name('TimeZone')->value(''),
  SOAP::Data->name('URLBufferedMessageNotification')->value($ASPSMS::config::notificationurli."?xml=notify,,,".$random.",,,".$msg_id.",,,".$msg_type.",,,".$login.",,,".$numbernotification.",,,Buffered,,,"),
  SOAP::Data->name('URLDeliveryNotification')->value($ASPSMS::config::notificationurl."?xml=notify,,,".$random.",,,".$msg_id.",,,".$msg_type.",,,".$login.",,,".$numbernotification.",,,Delivered,,,"),
  SOAP::Data->name('URLNonDeliveryNotification')->value($ASPSMS::config::notificationurl."?xml=notify,,,".$random.",,,".$msg_id.",,,".$msg_type.",,,".$login.",,,".$numbernotification.",,,NonDelivered,,,")
#  SOAP::Data->name('AffiliateId')->value($affiliateid)
);

return $som;


########################################################################
} ### soapSendBinarySMS
########################################################################

########################################################################
sub soapSendWAPPushSMS {
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

=head2 soapSendWAPPushSMS()

This function contains an aspsms soap request to send a wap push sms.

=cut

my $soap = SOAP::Lite->new( proxy => "$ASPSMS::config::aspsmsserver"
  , ssl_opts => {
    SSL_ca_path => '/etc/ssl/certs'
  }
);

$soap->on_action( sub { "https://webservice.aspsms.com/aspsmsx2.asmx/SimpleWAPPush" });
$soap->autotype(0);
$soap->default_ns('https://webservice.aspsms.com/aspsmsx2.asmx');
my $som = $soap->call('SimpleWAPPush',
  SOAP::Data->name('UserKey')->value($login),
  SOAP::Data->name('Password')->value($password),
  SOAP::Data->name('Recipients')->value($target.":".$random),
  SOAP::Data->name('Originator')->value($originator),
  SOAP::Data->name('WapDescription')->value($mess),
  SOAP::Data->name('WapURL')->value($url),
#  SOAP::Data->name('DeferredDeliveryTime')->value(''),
#  SOAP::Data->name('FlashingSMS')->value(''),
#  SOAP::Data->name('TimeZone')->value(''),
  SOAP::Data->name('URLBufferedMessageNotification')->value($ASPSMS::config::notificationurl."?xml=notify,,,".$random.",,,".$msg_id.",,,".$msg_type.",,,".$login.",,,".$numbernotification.",,,Buffered,,,"),
  SOAP::Data->name('URLDeliveryNotification')->value($ASPSMS::config::notificationurl."?xml=notify,,,".$random.",,,".$msg_id.",,,".$msg_type.",,,".$login.",,,".$numbernotification.",,,Delivered,,,"),
  SOAP::Data->name('URLNonDeliveryNotification')->value($ASPSMS::config::notificationurl."?xml=notify,,,".$random.",,,".$msg_id.",,,".$msg_type.",,,".$login.",,,".$numbernotification.",,,NonDelivered,,,")
#  SOAP::Data->name('AffiliateId')->value($affiliateid)
);

return $som;

########################################################################
}
########################################################################

1;

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2012 Marco Balmer <marco@balmer.name>
Adapted by jdkbx from xmlmodel.pm

The Debian packaging is licensed under the 
GPL, see `/usr/share/common-licenses/GPL-2'.

=cut
