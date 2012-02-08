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

aspsms-t - regex functions for xml interface

=head1 METHODS

=cut

package ASPSMS::Regex;

use strict;
use vars qw(@EXPORT @ISA);
use ASPSMS::aspsmstlog;

use Exporter;
use Sys::Syslog;

openlog($ASPSMS::config::ident,'','user');


@ISA 				= qw(Exporter);
@EXPORT 			= qw(regexes);



########################################################################
sub regexes {
########################################################################
my $mess        = shift;
my $number      = shift;
my $signature   = shift;

=head2 regexes()

Prepare message and add optional signatur to the message, if it can
be placed in one sms (<160).

=cut

        # Translations / Substitutionen
        $number         = "00" . $number;
        $mess =~ s/\xC3(.)/chr(ord($1)+64)/egs;

=head2

This function cut's some characters away with wich has aspsms.com xml 
server problems.

=cut
	$mess =~ s/\&//g;
	$mess =~ s/\|//g;
	$mess =~ s/\>//g;
	$mess =~ s/\<//g;
	$mess =~ s/\'//g;
        
	my $mess_length = length($mess);
        my $signature_length    = length($signature);

        my $sms_length =  $mess_length + $signature_length;

        if ($sms_length <=160)
                                {
                                aspsmst_log('debug',"regexes(): Signature: enabled");
                                $mess = $mess . " " . $signature;
                                }
return ($mess,$number);
########################################################################
}
########################################################################

1;

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2012 Marco Balmer <marco@balmer.name>

The Debian packaging is licensed under the 
GPL, see `/usr/share/common-licenses/GPL-2'.

=cut
