# aspsms-t
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

package ASPSMS::userhandler;

use strict;
use ASPSMS::config;
use ASPSMS::aspsmstlog;
use ASPSMS::Connection;
use ASPSMS::ConnectionASPSMS;
use ASPSMS::xmlmodel;
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

aspsmst_log('info',"CheckNewUser(): Check new user on aspsms xml-server $username/$password");
unless(ConnectAspsms() eq '0') {
my $value1 = $_[0]; my $value2 = $_[1];
return ($value1,$value2); }

my $aspsmsrequest       = xmlShowCredits($username,$password);
my $completerequest    	= xmlGenerateRequest($aspsmsrequest);


print $ASPSMS::config::aspsmssocket $completerequest;
@answer = <$ASPSMS::config::aspsmssocket>;
DisconnectAspsms();

my $ret_parsed_response = parse_aspsms_response(\@answer);

my $ErrorStatus         =       XML::Smart->new($ret_parsed_response);
my $ErrorCode           =       $ErrorStatus->{aspsms}{ErrorCode};
my $ErrorDescription    =       $ErrorStatus->{aspsms}{ErrorDescription};

aspsmst_log('info',"CheckNewUser(): Result for $username is: $ErrorDescription");

return ($ErrorCode,$ErrorDescription);


}


1;

