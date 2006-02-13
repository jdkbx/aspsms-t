#!/usr/bin/perl -w

use strict;

use ASPSMS::Storage;
use config;
use ASPSMS::aspsmstlog;

set_config('jabberd.transport.aspsmstest.xml');
my @data = get_data_from_storage("read","micressor\@swissjabber.ch");
print "\n\nDATA: @data\n\n";
