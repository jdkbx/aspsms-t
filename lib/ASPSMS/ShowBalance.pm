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

aspsms-t - How much credits do I have?

=head1 METHODS

=cut

package ASPSMS::ShowBalance;

use strict;
use vars qw(@EXPORT @ISA);
use Exporter;

@ISA                    = qw(Exporter);
@EXPORT                 = qw(	ShowBalance );

use ASPSMS::config;
use IO::Socket;
use ASPSMS::aspsmstlog;
use ASPSMS::userhandler;
use ASPSMS::soapmodel;
use ASPSMS::Connection;
use ASPSMS::ConnectionASPSMS;
use Sys::Syslog;

openlog($ASPSMS::config::ident,'','user');

sub ShowBalance 
 {
  my $barejid			= shift;
  my $aspsms_transaction_id	= shift;

=head2 ShowBalance()

What we get from the caller is a barejid. Is the user existing, checked
by getUserPass().

=cut

  aspsmst_log('debug',"id:$aspsms_transaction_id ShowBalance():");

  my $userdata = getUserPass($barejid,"null",$aspsms_transaction_id);

  if($userdata == -2)
   { return $userdata; }

  my $login 	=	$userdata->{name};
  my $password 	= 	$userdata->{password};

  my $ret_ShowCredits = soapShowCredits($login,$password);

=head2

And finally we return the parsed credit balance back.

=cut

return $ret_ShowCredits;

} ### END of ShowBalance()


1;

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2012 Marco Balmer <marco@balmer.name>

The Debian packaging is licensed under the 
GPL, see `/usr/share/common-licenses/GPL-2'.

=cut
