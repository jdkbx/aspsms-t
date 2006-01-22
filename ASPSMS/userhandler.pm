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
use vars qw(@EXPORT @ISA);
use Exporter;

use Sys::Syslog;


@ISA 			= qw(Exporter);
@EXPORT 		= qw(getUserPass);


use constant PASSWORDS	=> $config::passwords;

openlog($config::ident,'','$config::facility');


########################################################################
sub getUserPass {
########################################################################
my ($from,$banner) = @_;
my ($barejid) = split (/\//, $from);
my $passfile = PASSWORDS."/$barejid";
my $user = {};

open(F, "<$passfile");
seek(F, 0, 0);
local $/ = "\n";

while (<F>) 
 {
  chop;
  ($user->{gateway}, $user->{name}, $user->{password}, $user->{phone},$user->{signature}) = split(':');
  
  aspsmst_log('notice',"getUserPass($barejid): Got password, yeah ... groovy ;)");
 }

$user->{name}           = '' if ( ! $user->{name} );
$user->{password}       = '' if ( ! $user->{password} );
$user->{phone}          = 'aspsms-t' if ( ! $user->{phone} );
$user->{signature}      = $user->{signature};

return $user;

}
########################################################################



1;

