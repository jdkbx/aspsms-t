#!/usr/bin/perl

$ENV{HTTPS_CA_DIR} = '/etc/ssl/certs';

use SOAP::Lite;

unless($ARGV[0] and $ARGV[1] and $ARGV[2] and $ARGV[3] and $ARGV[4])
 {
    print "Please configure the script ./aspsms.soapsendUnicodeSMS.pl
    Usage: ./aspsms.soapSendUnicodeSMS.pl login password destination originator \"text\"\n";
    exit(-1);
 }

my $soap = SOAP::Lite->new( proxy => 'https://soap.aspsms.com/aspsmsx2.asmx'
, ssl_opts => {
	SSL_ca_path => '/etc/ssl/certs'
}
);

my $login               = $ARGV[0];
my $password            = $ARGV[1];
my $originator		= $ARGV[3];
my $target		= $ARGV[2];
my $mess		= $ARGV[4];
my $random		= '11460';
my $jid			= '';
my $numbernotification	= '223';
my $affiliateid		= '';
my $msg_id		= '2323';
my $msg_type		= 'chat';

$soap->on_action( sub { "https://webservice.aspsms.com/aspsmsx2.asmx/SendUnicodeSMS" });
 $soap->autotype(0);
$soap->default_ns('https://webservice.aspsms.com/aspsmsx2.asmx');
my $som = $soap->call('SendUnicodeSMS',
    SOAP::Data->name('UserKey')->value($login),
    SOAP::Data->name('Password')->value($password),
    SOAP::Data->name('Recipients')->value($target.":".$random),
    SOAP::Data->name('Originator')->value($originator),
    SOAP::Data->name('MessageText')->value($mess),
#    SOAP::Data->name('DeferredDeliveryTime')->value(''),
#    SOAP::Data->name('FlashingSMS')->value(''),
#    SOAP::Data->name('TimeZone')->value(''),
    SOAP::Data->name('URLBufferedMessageNotification')->value("https://jdkbx.no-ip.biz/aspsms/aspsms-t.notify?xml=notify,,,".$random.",,,".$msg_id.",,,".$msg_type.",,,".$login.",,,".$numbernotification.",,,Buffered,,,"),
    SOAP::Data->name('URLDeliveryNotification')->value("https://jdkbx.no-ip.biz/aspsms/aspsms-t.notify?xml=notify,,,".$random.",,,".$msg_id.",,,".$msg_type.",,,".$login.",,,".$numbernotification.",,,Delivered,,,"),
    SOAP::Data->name('URLNonDeliveryNotification')->value("https://jdkbx.no-ip.biz/aspsms/aspsms-t.notify?xml=notify,,,".$random.",,,".$msg_id.",,,".$msg_type.",,,".$login.",,,".$numbernotification.",,,NonDelivered,,,")
#    SOAP::Data->name('AffiliateId')->value('')
);
die $som->faultstring if ($som->fault);
print $som->result, "\n";
