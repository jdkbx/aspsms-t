# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ASPSMS.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 29;
BEGIN { use_ok('ASPSMS::soapmodel') };
BEGIN { use_ok('ASPSMS::aspsmstlog') };
BEGIN { use_ok('ASPSMS::CheckNotification') };
BEGIN { use_ok('ASPSMS::config') };
BEGIN { use_ok('ASPSMS::Connection') };
BEGIN { use_ok('ASPSMS::ContactCredits') };
BEGIN { use_ok('ASPSMS::DiscoNetworks') };
BEGIN { use_ok('ASPSMS::GetNetworksFees') };
BEGIN { use_ok('ASPSMS::InMessage') };
BEGIN { use_ok('ASPSMS::Iq') };
BEGIN { use_ok('ASPSMS::Jid') };
BEGIN { use_ok('ASPSMS::Message') };
BEGIN { use_ok('ASPSMS::Presence') };
BEGIN { use_ok('ASPSMS::Regex') };
BEGIN { use_ok('ASPSMS::Sendaspsms') };
BEGIN { use_ok('ASPSMS::ShowBalance') };
BEGIN { use_ok('ASPSMS::Storage') };
BEGIN { use_ok('ASPSMS::UCS2') };
BEGIN { use_ok('ASPSMS::userhandler') };
BEGIN { use_ok('File::Pid') };
BEGIN { use_ok('Net::Jabber') };
BEGIN { use_ok('XML::Parser') };
BEGIN { use_ok('XML::Smart') };
BEGIN { use_ok('Sys::Syslog') };
BEGIN { use_ok('LWP::UserAgent') };
BEGIN { use_ok('Sys::Syslog') };
BEGIN { use_ok('SOAP::Lite') };
BEGIN { use_ok('Log::Log4perl') };
BEGIN { use_ok('Getopt::Long') };
#BEGIN { use_ok('HTTP::Server::Simple') };

