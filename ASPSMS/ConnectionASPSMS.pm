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

package ASPSMS::ConnectionASPSMS;

use strict;
use vars qw(@EXPORT @ISA);
use Exporter;

@ISA                    = qw(Exporter);
@EXPORT                 = qw(	
				ConnectAspsms
				DisconnectAspsms
				exec_ConnectionASPSMS 
				parse_aspsms_response
				);

use config;
use IO::Socket;
use ASPSMS::aspsmstlog;

use Sys::Syslog;

openlog($config::ident,'','user');

sub exec_ConnectionASPSMS
 {
  my $completerequest 		= shift;
  my $aspsmst_transaction_id 	= shift;
  aspsmst_log('debug',"id:$aspsmst_transaction_id exec_ConnectionASPSMS(): ".
  "Begin");
	
  # /Generate SMS Request
  unless(ConnectAspsms($aspsmst_transaction_id) eq '0') 
   { return ('-1',"Sorry, $config::ident transport is up and running but it ".
   		"is not able to reach one of the aspsms servers for ".
		"delivering your sms message. Please try again later. ".
		"Thank you!"); }
 
  # Send request to socket
  aspsmst_log('debug',"id:$aspsmst_transaction_id exec_ConnectionASPSMS(): ".
  "Sending: $completerequest");
  print $config::aspsmssocket $completerequest;

  my @answer;

  eval 
   {
    # Timeout alarm
    alarm(10);
    @answer = <$config::aspsmssocket>;
    aspsmst_log('debug',"id:$aspsmst_transaction_id ".
    "exec_ConnectionASPSMS(): \@answer=@answer");
    alarm(0);
   };

   # If alarm do action
   if($@) 
    {
     aspsmst_log('warning',"id:$aspsmst_transaction_id ".
     "exec_ConnectionASPSMS(): No response of aspsms after sent request");

     return ('-21','exec_ConnectionASPSMS(): No response of aspsms after ".
     "sent request. Please try again later or contact your transport ".
     "administrator.');

    } ### END of exec_ConnectionASPSMS ###

    DisconnectAspsms($aspsmst_transaction_id);
    aspsmst_log('debug',"id:$aspsmst_transaction_id ".
    "exec_ConnectionASPSMS(): End");

    return (@answer);
 } ### END of exec_ConnectionASPSMS ###


########################################################################
sub ConnectAspsms {
########################################################################

my $aspsmst_transaction_id 	= shift;
my $status			= undef;
my $connect_retry 		= 0;
my $max_connect_retry		= 4;
my $connection_num		= 0;

#
# If connection failed we are trying to reconnect on another
# aspsms xml server
#

while ()
 {
  #
  # Select on of the 4 servers
  #
  $connection_num++;


  aspsmst_log('debug',"id:$aspsmst_transaction_id ConnectAspsms(): Connecting ".
  "to server $connection_num ".
  "(".$config::aspsms_connection{"host_$connection_num"}.
  ":".$config::aspsms_connection{"port_$connection_num"}.
  ") \$connect_retry=$connect_retry");

  #
  # Setup a socket connection to the selected
  # server
  # 
  $config::aspsmssocket 
  = IO::Socket::INET->new( 
  PeerAddr => $config::aspsms_connection{"host_$connection_num"},
  PeerPort => $config::aspsms_connection{"port_$connection_num"},
  Proto    => 'tcp',
  Timeout  => 3,
  Type     => SOCK_STREAM) or $status = -1;

  aspsmst_log('debug',"id:$aspsmst_transaction_id ConnectAspsms(): ".
  "status=$status");
  
  #
  # Increment connection retry
  #
  $connect_retry++;

  aspsmst_log('debug',"id:$aspsmst_transaction_id ConnectAspsms(): ".
  "\$status=$status \$connection_retry=$connect_retry");

  if($connect_retry > $max_connect_retry)
   {
    aspsmst_log('warning',"id:$aspsmst_transaction_id ConnectAspsms(): ".
    "status=$status Max connect retry reached");
    last; 
   }

  if($status == -1)
   { 
    aspsmst_log('info',"id:$aspsmst_transaction_id ConnectAspsms(): Connecting".
    "to server $connection_num ".
    "(".$config::aspsms_connection{"host_$connection_num"}.
    ":".$config::aspsms_connection{"port_$connection_num"}.
    ") failed \$status=$status \$connect_retry=$connect_retry");
    $status = undef;
   }
  else
   {
    #
    # Return connection sucessfully
    #
    return 0;
   }

   $status = undef; 
  } ### END of 


return $status;
}

sub DisconnectAspsms {
my $aspsmst_transaction_id = shift;
aspsmst_log('debug',"id:$aspsmst_transaction_id DisconnectAspsms()");
close($config::aspsmssocket);

########################################################################
}
########################################################################

sub parse_aspsms_response
 {
   my $pointer_xml 			= shift;
   my $aspsmst_transaction_id 		= shift;
   my @xml				= @{$pointer_xml};
   my $tmp;

   foreach $_ (@xml)
    {
     aspsmst_log("debug","id:$aspsmst_transaction_id parse_aspsms_response():".
     "$_");
     $tmp .= $_;
    }
   
   $tmp =~ s/(.*(<aspsms>.*<\/aspsms>).*|.*)/$2/gis;
   aspsmst_log("debug","id:$aspsmst_transaction_id parse_aspsms_response(): ".
   "Return: $tmp");
   return $tmp;
 }

1;

