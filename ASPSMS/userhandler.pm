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
my ($barejid) = split (/\//, $from);
my $passfile = "$config::passwords/$barejid";
my $user = {};

open(F, "<$passfile");
seek(F, 0, 0);
local $/ = "\n";

while (<F>) 
 {
  chop;
  ($user->{gateway}, $user->{name}, $user->{password}, $user->{phone},$user->{signature}) = split(':');
  
  aspsmst_log('notice',"getUserPass($barejid): id:$aspsmst_transaction_id Got password, yeah ... groovy ;)");
 }

$user->{name}           = '' if ( ! $user->{name} );
$user->{password}       = '' if ( ! $user->{password} );
$user->{phone}          = 'aspsms-t' if ( ! $user->{phone} );
$user->{signature}      = $banner if (! $user->{signature} );

return $user;

}
########################################################################




##########################################################################
sub CheckNewUser { 
###########################################################################

my $username =	shift;
my $password = 	shift;
my @answer;

aspsmst_log('info',"handler::CheckNewUser(): Check new user on aspsms xml-server $username/$password");
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

aspsmst_log('info',"handler::CheckNewUser(): Result for $username is: $ErrorDescription");
$ErrorDescription = "This user does\'n exist at aspsms.com. Please register first an user on http://www.aspsms.com then try again.";

return ($ErrorCode,$ErrorDescription);


}


1;

