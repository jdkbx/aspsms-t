# http://www.swissjabber.ch/
# https://github.com/micressor/aspsms-t
#
# Copyright (C) 2006-2012 Marco Balmer <marco@balmer.name>
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

aspsms-t - networks/fees updater

=head1 DESCRIPTION

This module downloads every week updated networks.xml and fees.xml files
from aspsms.com. This credit costs and supported network lists are published
via jabber service discovery and on the status line from each aspsms-t
jabber conntact.

=head1 METHODS

=cut

package ASPSMS::GetNetworksFees;

use strict;
use vars qw(@EXPORT @ISA);

use Exporter;
use Sys::Syslog;

openlog($ASPSMS::config::ident,'','user');

@ISA 				= qw(Exporter);
@EXPORT 			= qw(update_networks_fees);

use ASPSMS::config;
use ASPSMS::aspsmstlog;

sub update_networks_fees
 {

=head2 update_networks_fees()

This function calls:

check_for_file_update("networks.xml");
check_for_file_update("fees.xml");

to get updated files.

List of supported networks:
http://xml1.aspsms.com:5061/opinfo/networks.xml

List of networks with termination fees:
http://xml1.aspsms.com:5061/opinfo/fees.xml

=cut

  aspsmst_log("info","update_networks_fees();");

  check_for_file_update("networks.xml");
  check_for_file_update("fees.xml");

 } ### END of update_networks_fees()

sub check_for_file_update
 {
  my $filename	= shift;

  my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
         $atime,$mtime,$ctime,$blksize,$blocks)
   = stat("$ASPSMS::config::cachedir/$filename");

  my $diff = time() - $ctime;

=head2 check_for_file_update()

Every 604800 seconds (1 week), this function calls do_file_update() which
do the real download.

=cut

  my $next_update = 604800;
  if($diff > $next_update)
   {
    do_file_update($filename);
   } ### if($diff > 604800)
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
   
=head2 do_file_update()

The real download with os command wget.

=cut

  system("wget -q http://xml1.aspsms.com:5061/opinfo/$filename -O ".
  "$ASPSMS::config::cachedir/$filename.new");

  unless($? == 0)
   {
    aspsmst_log("debug","do_file_update(): Failed to download $filename ".
    "from aspsms.com.");
   }
  else
   {
    aspsmst_log("info","do_file_update(): Download of $filename was".
    " successfully.");
    system("mv $ASPSMS::config::cachedir/$filename.new $ASPSMS::config::cachedir/$filename");
   }

 } ### do_file_update()

1;

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2012 Marco Balmer <marco@balmer.name>

The Debian packaging is licensed under the 
GPL, see `/usr/share/common-licenses/GPL-2'.

=cut
