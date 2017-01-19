#!/usr/bin/perl

$ENV{HTTPS_CA_DIR} = '/etc/ssl/certs';

use SOAP::Lite;

unless($ARGV[0] and $ARGV[1])
 {
   print "Please configure the script ./aspsms.soapCheck.pl
   Usage: ./aspsms.soapCheckCredits.pl login password\n";
   exit(-1);
 }

my $soap = SOAP::Lite->new( proxy => 'https://soap.aspsms.com/aspsmsx2.asmx'
, ssl_opts => {
	SSL_ca_path => '/etc/ssl/certs'
}
);

my $login               = $ARGV[0];
my $password            = $ARGV[1];

$soap->on_action( sub { "https://webservice.aspsms.com/aspsmsx2.asmx/CheckCredits" });
 $soap->autotype(0);
$soap->default_ns('https://webservice.aspsms.com/aspsmsx2.asmx');
my $som = $soap->call('CheckCredits',
    SOAP::Data->name('UserKey')->value($login),
    SOAP::Data->name('Password')->value($password)
);
die $som->faultstring if ($som->fault);
print $som->result, "\n";
