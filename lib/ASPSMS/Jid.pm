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

aspsms-t - convert jid to bare jid

=head1 DESCRIPTION

This module converts a jid user@domain.tld/ressource to a normal jid without
ressource user@domain.tld which is used for most actions in aspsms-t.

=head1 METHODS

=cut

package ASPSMS::Jid;

use strict;
use ASPSMS::config;
use vars qw(@EXPORT @ISA);
use Exporter;

@ISA 			= qw(Exporter);
@EXPORT 		= qw(get_barejid);

use Sys::Syslog;
use ASPSMS::aspsmstlog;

=head2 get_barejid()

my $barejid = get_barejid($jid);

=cut

sub get_barejid
 {
   my $jid = shift;
   my ($barejid)                 = split (/\//, $jid);
   return $barejid;
 } # END of get_barejid

1;

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2012 Marco Balmer <marco@balmer.name>

The Debian packaging is licensed under the 
GPL, see `/usr/share/common-licenses/GPL-2'.

=cut
