#!/usr/bin/perl
#

use Storage;

my $data = get_data_from_storage("read","micressor\@swissjabber.ch");

print "DATA: $data \n\n";
