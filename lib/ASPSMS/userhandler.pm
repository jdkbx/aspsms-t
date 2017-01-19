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

aspsms-t - userhandler

=head1 METHODS

=cut

package ASPSMS::userhandler;

use strict;
use ASPSMS::config;
use ASPSMS::aspsmstlog;
use ASPSMS::Connection;
use ASPSMS::soapmodel;
use ASPSMS::Storage;
use ASPSMS::Jid;
use vars qw(@EXPORT @ISA);
use Exporter;

use Sys::Syslog;


@ISA 			= qw(Exporter);
@EXPORT 		= qw(getUserPass CheckNewUser);



openlog($ASPSMS::config::ident,'','$ASPSMS::config::facility');


########################################################################
sub getUserPass {
########################################################################
my ($from,$banner,$aspsmst_transaction_id) = @_;
my $barejid	= get_barejid($from);
my $passfile 	= "$ASPSMS::config::passwords/$barejid";
my $user = {}; my $ret;

=head2 getUserPass()

This function read a user object based on the jid (jabber-id). If no user
exists, this function return -2 otherwise the user object.

=cut

$user = get_record("jid",$barejid);

if($user == -2)
 {
  aspsmst_log("warning","getUserPass(): No registered user found for $barejid");
  return -2;
 }

aspsmst_log('debug',"getUserPass($barejid): Got ".$user->{name}."/".$user->{phone});
return $user;

}
########################################################################




##########################################################################
sub CheckNewUser { 
###########################################################################

my $username =	shift;
my $password = 	shift;
my @answer;

=head2 CheckNewUser()

This function checks the given user/pass with the aspsms server. In
this case we use an already existing function soapShowCredits() to do 
that. 

=cut

aspsmst_log('info',"CheckNewUser(): Check new user on aspsms server $username/$password");
my $credits = soapShowCredits($username,$password);
my $ErrorCode           = 1;
my $ErrorDescription    = "OK";

unless (substr($credits, 0, 8) eq "Credits:" ) {
$ErrorCode = substr($credits, 11, length($credits) - 11);
$ErrorDescription = soapGetErrorDescription($credits);
}

aspsmst_log('info',"CheckNewUser(): Result for $username is: $ErrorDescription");

return ($ErrorCode,$ErrorDescription);


}


1;

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2012 Marco Balmer <marco@balmer.name>

The Debian packaging is licensed under the 
GPL, see `/usr/share/common-licenses/GPL-2'.

=cut
