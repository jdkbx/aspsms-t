# aspsms-t by Marco Balmer <mb@micressor.ch> @2007
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

package ASPSMS::GetNetworksFees;

use strict;
use vars qw(@EXPORT @ISA);

use Exporter;
use Sys::Syslog;

openlog($config::ident,'','user');

@ISA 				= qw(Exporter);
@EXPORT 			= qw(update_networks_fees);

use ASPSMS::config;
use ASPSMS::aspsmstlog;
use LWP::UserAgent;
use URI::URL;

sub update_networks_fees
 {
 
  # List of supported networks:
  # http://xml1.aspsms.com:5061/opinfo/networks.xml
  #
  # List of networks with termination fees:
  # http://xml1.aspsms.com:5061/opinfo/fees.xml

  aspsmst_log("info","update_networks_fees();");

  check_for_file_update("networks.xml");
  check_for_file_update("fees.xml");

 } ### END of update_networks_fees()

sub check_for_file_update
 {
  my $filename	= shift;

  my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
         $atime,$mtime,$ctime,$blksize,$blocks)
   = stat("./etc/$filename");

  my $diff = time() - $ctime;

  #
  # 604800 seconds = 1 week
  #
  my $next_update = 604800;
  if($diff > $next_update)
   {
    do_file_update($filename);
   } ### if($diff > 300)
  else
   {
    my $left = $next_update - $diff;
    aspsmst_log("info","check_for_file_update(): Not necessary to update ".
    " $filename: ($left seconds left)"); 
   }
 
 } ### END of check_for_file_update()

sub do_file_update
 {

  my $filename	= shift;
   
  system("wget -q http://xml1.aspsms.com:5061/opinfo/$filename -O ".
  "./etc/$filename.new");

  unless($? == 0)
   {
    aspsmst_log("debug","do_file_update(): Failed to download $filename ".
    "from aspsms.com.");
   }
  else
   {
    aspsmst_log("info","do_file_update(): Download of $filename was".
    " successfully.");
    system("mv ./etc/$filename.new ./etc/$filename");
   }

 } ### do_file_update()

1;

