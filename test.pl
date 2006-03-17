#!/usr/bin/perl -w

my $conf 	= @ARGV[0];
my $opt 	= @ARGV[1];

use strict;

use ASPSMS::Storage;
use config;
use ASPSMS::aspsmstlog;

set_config($conf);
my @data = get_data_from_storage("read",$opt);
print "\n\nDATA: @data\n\n";
