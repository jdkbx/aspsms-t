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

package ASPSMS::Connection;

use strict;
use vars qw(@EXPORT @ISA);
use Exporter;

@ISA                    = qw(Exporter);
@EXPORT                 = qw(exec_SendTextSMS);

use ASPSMS::config;
use IO::Socket;
use ASPSMS::aspsmstlog;
use ASPSMS::xmlmodel;
use ASPSMS::ShowBalance;
use ASPSMS::ConnectionASPSMS;
use ASPSMS::Regex;
use ASPSMS::UCS2;
use Sys::Syslog;

openlog($config::ident,'','user');

sub exec_SendTextSMS 
 {
	my $number              	= shift;
	my $numbernotification 		= $number;
	my $mess                	= shift;
	my $login               	= shift;
	my $password            	= shift;
	my $phone               	= shift;
	my $signature           	= shift;
	my $jid				= shift;
	my $aspsmst_transaction_id 	= shift; 
	my $msg_id			= shift;
	my $msg_type			= shift;
        aspsmst_log('debug',"id:$aspsmst_transaction_id ".
	"exec_SendTextSMS(): Begin");

	# Generate SMS Request
	my $aspsmsrequest;
	my $flag_ucs2_mess = check_for_ucs2($mess);
        aspsmst_log('debug',"id:$aspsmst_transaction_id exec_SendTextSMS(): " .
	"check_for_ucs2(): $flag_ucs2_mess");

	#
	# If flag_ucs2_mess is 1, send the message as binary.
	#


        if($flag_ucs2_mess == 1)
	 {
	  $mess 	 = convert_to_ucs2($mess);
	  #
	  # Check length of message.
	  #
	  my $mess_length = length($mess);
	  if($mess_length > 160)
	   {
		
		return (	501,
				"Arabic & other oriental characters are only up to 83 characteres supported",
				undef,
				undef,
				$aspsmst_transaction_id);
	   } ### END of if($mess_length > 160)
	  $aspsmsrequest = xmlSendBinarySMS(	$login,
						$password,
						$phone,
						$number,
						$mess,
						$aspsmst_transaction_id ,
						$jid,
						$numbernotification,
						$config::affiliateid,
						$msg_id,
						$msg_type);

 	 } ### if($flag_ucs2_mess == 1)
	else
	 {

	#
	# If flag_ucs2_mess is 0, send the message normal text message.
	#

	  ($mess,$number,$signature) 	= regexes($mess,$number,$signature);
	  $aspsmsrequest = xmlSendTextSMS(	$login,
						$password,
						$phone,
						$number,
						$mess,
						$aspsmst_transaction_id ,
						$jid,
						$numbernotification,
						$config::affiliateid,
						$msg_id,
						$msg_type);

	 } ### if($flag_ucs2_mess == 1)

	my $completerequest     = xmlGenerateRequest($aspsmsrequest);
	my @ret_CompleteRequest 
	= exec_ConnectionASPSMS($completerequest,
				$aspsmst_transaction_id);

	if($ret_CompleteRequest[0] eq "-1")
	 {
	  #
	  # We have a problem with connection and will stop
	  # here processing.
	  #
	  return ($ret_CompleteRequest[0],$ret_CompleteRequest[1]);
	 }

# Parse XML of SMS request
my $ret_parsed_response = parse_aspsms_response(\@ret_CompleteRequest,
						$aspsmst_transaction_id);

my $DeliveryStatus      =       XML::Smart->new($ret_parsed_response);
my $ErrorCode           =       $DeliveryStatus->{aspsms}{ErrorCode};
my $ErrorDescription    =       $DeliveryStatus->{aspsms}{ErrorDescription};
my $CreditsUsed         =       $DeliveryStatus->{aspsms}{CreditsUsed};

##########################################################################
# Generate ShowCredits Request
##########################################################################

my $Credits = ShowBalance($jid,$aspsmst_transaction_id);

aspsmst_log('debug',"id:$aspsmst_transaction_id exec_SendTextSMS(): ".
"return ($ErrorCode,$ErrorDescription,$Credits,$CreditsUsed,".
"$aspsmst_transaction_id)");

return (	$ErrorCode,
		$ErrorDescription,
		$Credits,
		$CreditsUsed,
		$aspsmst_transaction_id);

} ### END of exec_SendTextSMS()

1;

