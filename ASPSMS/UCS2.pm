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
@EXPORT 		= qw(encode_ucs2);


use Sys::Syslog;
use ASPSMS::aspsmstlog;
use ASPSMS::Jid;


use Unicode::String qw(utf8 latin1 utf16);

sub encode_ucs2
 {
  my $msg = shift;
  my  $u = utf8($msg);

  # convert to various external formats
  #print $u->ucs4."\n";      # 4 byte characters
  #print $u->utf16;     # 2 byte characters + surrogates
  #print $u->utf8;      # 1-4 byte characters
  #print $u->utf7;      # 7-bit clean format
  #print $u->latin1;    # lossy


  my $u2 = $u->hex;       # a hexadecimal string
  $u2 =~ s/U\+//g;
  $u2 =~ s/\s//g;

  return $u2;

 } ### END of encode_ucs2

1;
