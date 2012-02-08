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

aspsms-t - connection handler

=head1 SYNOPSIS

=head1 DESCRIPTION

This module create io sockets and transport the sms message to the
xml gateway of aspsms.com.

=cut

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

use ASPSMS::config;
use IO::Socket;
use ASPSMS::aspsmstlog;

use Sys::Syslog;

openlog($ASPSMS::config::ident,'','user');

=head1 METHODS

=head2 exec_ConnectionASPSMS()

=over 2

my $response = exec_ConnectionASPSMS($complete_http_request,
   $aspsmst_transaction_id)

=back

This function send a complete http+xml request to the aspsms.com 
xml service. 

=cut

sub exec_ConnectionASPSMS
 {
  my $completerequest 		= shift;
  my $aspsmst_transaction_id 	= shift;
  aspsmst_log('debug',"id:$aspsmst_transaction_id exec_ConnectionASPSMS(): ".
  "Begin");
	
=head2

An exeption handler gives response back to the jabber user

=cut

  # /Generate SMS Request
  unless(ConnectAspsms($aspsmst_transaction_id) eq '0') 
   { return ('-1',"Sorry, $ASPSMS::config::ident transport is up and running but it ".
   		"is not able to reach one of the aspsms servers for ".
		"delivering your sms message. Please try again later. ".
		"Thank you!"); }

 
  # Send request to socket
  aspsmst_log('debug',"id:$aspsmst_transaction_id exec_ConnectionASPSMS(): ".
  "Sending: $completerequest");
  print $ASPSMS::config::aspsmssocket $completerequest;

  my @answer;

  eval 
   {
    # Timeout alarm
    alarm(10);
    @answer = <$ASPSMS::config::aspsmssocket>;
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

=head2 ConnectAspsms()

Connect to one of the configured aspsms.com xml services. If connection
failed, the function trying to reconnect to another xml service ip.

=cut

while ()
 {
  $connection_num++;


  aspsmst_log('debug',"id:$aspsmst_transaction_id ConnectAspsms(): Connecting ".
  "to server $connection_num ".
  "(".$ASPSMS::config::aspsms_connection{"host_$connection_num"}.
  ":".$ASPSMS::config::aspsms_connection{"port_$connection_num"}.
  ") \$connect_retry=$connect_retry");

=head2

The function create a socket connection to the selected server.

=cut

  $ASPSMS::config::aspsmssocket 
  = IO::Socket::INET->new( 
  PeerAddr => $ASPSMS::config::aspsms_connection{"host_$connection_num"},
  PeerPort => $ASPSMS::config::aspsms_connection{"port_$connection_num"},
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
    "(".$ASPSMS::config::aspsms_connection{"host_$connection_num"}.
    ":".$ASPSMS::config::aspsms_connection{"port_$connection_num"}.
    ") failed \$status=$status \$connect_retry=$connect_retry");
    $status = undef;
   }
  else
   {
=head2

If connection was successfully, function will return 0.

=cut

    return 0;
   }

   $status = undef; 
  } ### END of 


return $status;
}

sub DisconnectAspsms {
my $aspsmst_transaction_id = shift;
aspsmst_log('debug',"id:$aspsmst_transaction_id DisconnectAspsms()");
close($ASPSMS::config::aspsmssocket);

########################################################################
}
########################################################################

sub parse_aspsms_response
 {
   my $pointer_xml 			= shift;
   my $aspsmst_transaction_id 		= shift;
   my @xml				= @{$pointer_xml};
   my $tmp;

=head2 parse_aspsms_response()

From the http+xml response this function cuts all what we do not need.
All between <aspsms> and </aspsms> is interessting for this function.

=cut

   foreach $_ (@xml)
    {
     aspsmst_log("debug","id:$aspsmst_transaction_id parse_aspsms_response():".
     "$_");
     $tmp .= $_;
    }
   
   $tmp =~ s/(.*(<aspsms>.*<\/aspsms>).*|.*)/$2/gis;
   aspsmst_log("debug","id:$aspsmst_transaction_id parse_aspsms_response(): ".
   "Return: $tmp");
=head2

Return is cutted result.

=cut

   return $tmp;
 }

1;

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2012 Marco Balmer <marco@balmer.name>

The Debian packaging is licensed under the 
GPL, see `/usr/share/common-licenses/GPL-2'.

=cut
