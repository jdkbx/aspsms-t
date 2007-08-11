# aspsms-t by Marco Balmer <mb@micressor.ch> @2004
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

package ASPSMS::userhandler;

use strict;
use config;
use ASPSMS::aspsmstlog;
use ASPSMS::Connection;
use ASPSMS::xmlmodel;
use ASPSMS::Storage;
use ASPSMS::Jid;
use vars qw(@EXPORT @ISA);
use Exporter;

use Sys::Syslog;


@ISA 			= qw(Exporter);
@EXPORT 		= qw(getUserPass CheckNewUser);



openlog($config::ident,'','$config::facility');


########################################################################
sub getUserPass {
########################################################################
my ($from,$banner,$aspsmst_transaction_id) = @_;
my $barejid	= get_barejid($from);
my $passfile 	= "$config::passwords/$barejid";
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


print $config::aspsmssocket $completerequest;
@answer = <$config::aspsmssocket>;
DisconnectAspsms();

my $ret_parsed_response = parse_aspsms_response(\@answer);

my $ErrorStatus         =       XML::Smart->new($ret_parsed_response);
my $ErrorCode           =       $ErrorStatus->{aspsms}{ErrorCode};
my $ErrorDescription    =       $ErrorStatus->{aspsms}{ErrorDescription};

aspsmst_log('info',"CheckNewUser(): Result for $username is: $ErrorDescription");

return ($ErrorCode,$ErrorDescription);


}


1;

