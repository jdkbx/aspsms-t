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

package ASPSMS::ShowBalance;

use strict;
use vars qw(@EXPORT @ISA);
use Exporter;

@ISA                    = qw(Exporter);
@EXPORT                 = qw(	ShowBalance );

use config;
use IO::Socket;
use ASPSMS::aspsmstlog;
use ASPSMS::userhandler;
use ASPSMS::xmlmodel;
use ASPSMS::Connection;
use ASPSMS::ConnectionASPSMS;
#use ASPSMS::Regex;
#use ASPSMS::UCS2;
use Sys::Syslog;

openlog($config::ident,'','user');

sub ShowBalance 
 {
  my $barejid			= shift;
  my $aspsms_transaction_id	= shift;

  aspsmst_log('debug',"id:$aspsms_transaction_id ShowBalance():");

  my $userdata = getUserPass($barejid,"null",$aspsms_transaction_id);

  if($userdata == -2)
   { return $userdata; }

  my $login 	=	$userdata->{name};
  my $password 	= 	$userdata->{password};

  my $aspsms_request	= xmlShowCredits($login,$password);
  my $request_xml	= xmlGenerateRequest($aspsms_request);

  my @ret_ShowCredits = 
			exec_ConnectionASPSMS(	$request_xml,
						$aspsms_transaction_id);

# Parse XML of SMS request
my $ret_parsed_response_ShowCredits = 
			parse_aspsms_response(	\@ret_ShowCredits,
						$aspsms_transaction_id);

DisconnectAspsms($aspsms_transaction_id);

my $CreditStatus        =       XML::Smart->new($ret_parsed_response_ShowCredits);
my $Credits             =       $CreditStatus->{aspsms}{Credits};
my $ErrorCode		=       $CreditStatus->{aspsms}{ErrorCode};
my $ErrorDescription	=       $CreditStatus->{aspsms}{ErrorDescription};

#
# If we are not authorized, send error back to user.
#

unless($ErrorCode == 1)
 {
  return $ErrorDescription;
 } ### unless($ErrorCode == 1)

return ($Credits);

} ### END of ShowBalance()


1;

