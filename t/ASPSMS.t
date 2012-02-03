# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ASPSMS.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 21;
BEGIN { use_ok('ASPSMS::xmlmodel') };
BEGIN { use_ok('ASPSMS::aspsmstlog') };
BEGIN { use_ok('ASPSMS::CheckNotification') };
BEGIN { use_ok('ASPSMS::config') };
BEGIN { use_ok('ASPSMS::ConnectionASPSMS') };
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
BEGIN { use_ok('ASPSMS::xmlmodel') };
