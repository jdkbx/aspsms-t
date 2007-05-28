# aspsms-t by Marco Balmer <mb@micressor.ch> @2006
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

package ASPSMS::UCS2;

use strict;
use config;
use vars qw(@EXPORT @ISA);
use Exporter;

@ISA 			= qw(Exporter);
@EXPORT 		= qw(utf8_to_ucs2);


use Sys::Syslog;
use ASPSMS::aspsmstlog;
use ASPSMS::Jid;


use Unicode::String qw(utf8 latin1 utf16);

sub utf8_to_ucs2
#
# Description: Encoding utf8 --> UCS2
# Example: "Hello" in UCS2 is: "00480065006c006c006f"
#
 {
  my $msg = shift;
  my $utf8 = utf8($msg);
  my $ucs2 = $utf8->hex;
  
  #
  # Remove not necessary characters from
  # U+0048 U+0065 U+006c U+006c U+006f
  # to
  # 00480065006c006c006f
  #
  $ucs2 =~ s/\+//g;
  $ucs2 =~ s/U//g;
  $ucs2 =~ s/\s//g;

  return $ucs2;

 } ### END of encode_ucs2

1;
