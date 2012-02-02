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

aspsms-t - ucs2 converter

=head1 METHODS

=cut

package ASPSMS::UCS2;

use strict;
use ASPSMS::config;
use vars qw(@EXPORT @ISA);
use Exporter;

@ISA 			= qw(Exporter);
@EXPORT 		= qw(	
				convert_to_ucs2
				check_for_ucs2
			    );


use Sys::Syslog;
use ASPSMS::aspsmstlog;
use ASPSMS::Jid;


use Unicode::String qw(utf8 latin1 utf16);

sub convert_to_ucs2
 {
  my $msg = shift;
  my $utf8 = utf8($msg);
  my $ucs2 = $utf8->hex;

=head2 convert_to_ucs2()

This function convert an utf-8 string to an UCS2 string. It looks like:

"Hello" in UCS2 is: "00480065006c006c006f"

=cut

  
  $ucs2 = remove_ucs2_overhead($ucs2);

  return $ucs2;

 } ### END of convert_to_ucs2()

sub check_for_ucs2
 {
  my $msg	= shift;

=head2 check_for_ucs2()

This function checks, when ucs2 encoding is necessary to deliver an sms. It 
returns 1 if ucs2 encoding is necessary and 0 if it can be sent as a normal
sms.

=cut


  #
  # Split string $utf8 into an array @data
  #
  my @data = split(//,$msg);

  my $data_length = length($msg);
  my $check_chr;
  #
  # Check each char in string.
  #
  for (my $c=0; $c < $data_length; $c++) 
   {
    if(ord($data[$c]) > 255)
     {
      #
      # Yes, UCS2 encoding is necessary.
      #
      return 1;
     } ### if(ord($data[$c]) >255);
   } ### for (my $c=0; $c < $data_length; $c++)
  #
  # No, UCS2 encoding is not necessary.
  #
  return 0;
 } ### check_for_ucs2()

sub remove_ucs2_overhead
#
# Desription: Remove ucs2 overhead
#
 {
  my $ucs2	= shift;

=head2 remove_ucs2_overhead()

This function removes not necessary characters from an ucs2 string.

=over 4

=item * U+0048 U+0065 U+006c U+006c U+006f

=item * to

=item * 00480065006c006c006f

=back

=cut
  $ucs2 =~ s/\+//g;
  $ucs2 =~ s/U//g;
  $ucs2 =~ s/\s//g;

  return $ucs2;
 } ### remove_ucs2_overhead()

1;

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2012 Marco Balmer <marco@balmer.name>

The Debian packaging is licensed under the 
GPL, see `/usr/share/common-licenses/GPL-2'.

=cut
