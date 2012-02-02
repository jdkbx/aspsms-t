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

aspsms-t - jabber message handler

=head1 METHODS

=cut

package ASPSMS::InMessage;

use strict;
use vars qw(@EXPORT @ISA);

use ASPSMS::aspsmstlog;
use ASPSMS::Sendaspsms;
use ASPSMS::Jid;
use ASPSMS::Message;
use ASPSMS::Storage;
use ASPSMS::ShowBalance;
use ASPSMS::Presence;

use Exporter;
use Sys::Syslog;

openlog($ASPSMS::config::ident,'','user');


@ISA 				= qw(Exporter);
@EXPORT 			= qw(InMessage);



sub InMessage {

=head2 InMessage()

This function is called via a hook of the main program. Let's send this via
sms to the requested destination.

=cut
  
  	
	$ASPSMS::config::aspsmst_stat_stanzas++;
	$ASPSMS::config::aspsmst_in_progress=1;

=head2

=over 4

=item * The function gives us all necessary information to handle this call. A
random transaction number we get via get_transaction_id().

=back

=cut
	my $sid 		= shift;
	my $message 		= shift;
	my $from 		= $message->GetFrom();
	my $to 			= $message->GetTo();
	my $body 		= $message->GetBody();
	my $msg_type 		= $message->GetType();
	my $msg_id		= $message->GetID();
	my ($number) 		= split(/@/, $to);
	my ($barejid) 		= split (/\//, $from);
  	my $aspsmst_transaction_id = get_transaction_id();

	aspsmst_log('debug',"id:$aspsmst_transaction_id InMessage($barejid): Begin job");
	aspsmst_log('debug',"id:$aspsmst_transaction_id InMessage($barejid): \$msg_id=$msg_id");

	unless($ASPSMS::config::aspsmst_flag_shutdown eq "0")
 	 {
	  sendError($message, $from, $to, 503, "Sorry, $ASPSMS::config::ident has a lot of work or is shutting down at the moment, please try again later. Thanks.");
	  $ASPSMS::config::aspsmst_in_progress=0;
	  return -1;
	 }

=head2

=over 4

=item * If a user type '!credits` we call ShowBalance($barejid) to get
users current credit balance.

=back

=cut

       if ($body eq "!credits") 
        {
	 my $Credits_of_barejid = ShowBalance($barejid);
  	 ShowBalanceMessage(	$from,
	 			$to,
	 			$Credits_of_barejid,
				$aspsmst_transaction_id);
	 $ASPSMS::config::aspsmst_in_progress=0;
	 return 0;
	} ### END of  if ($body eq "!credits")

=head2

=over 4

=item * If a user type '!help` or send a message direct to the transport 
address so we call HelpMessage().

=back

=cut
       if (    $to eq $ASPSMS::config::service_name 
            or $to eq "$ASPSMS::config::service_name/registered"
	    or $body eq "!help")
	{
  	 HelpMessage(		$from,
	 			$to,
				$aspsmst_transaction_id);
	 $ASPSMS::config::aspsmst_in_progress=0;
	 return 0;
	} ### if (    $to eq $ASPSMS::config::service_name...

=head2

=over 4

=item * Delivery notification from aspsms.com we receive via http request. The
perl binary aspsms-t.notify uses a jabber account and send this information
to aspsms.domain.tld/notification. There is also a test function implemented.

=back

=cut
	   
       if ( $to eq $ASPSMS::config::service_name."/notification" and $barejid eq $ASPSMS::config::notificationjid) 
        {
	 my $msg		= new Net::Jabber::Message();
	 # Get the <stream/> from aspsms-t.notify binary
	 my @stattmp 		= split(/,,,/, $body);
	 my $streamtype		= $stattmp[0];
	  #
	  # If test of aspsms-t.notify binary, make log entry and
	  # return 0
	  #
	  if($streamtype eq "test")
	   {
	    aspsmst_log('info',"web-notify.pl is configured successfully");
	    $ASPSMS::config::aspsmst_in_progress=0;
	    return 0;
	   }

 	 #
	 # Ok, let's read the stream parameters which comes via aspsms-t.notify
	 #

	 my $transid 		= $stattmp[1];
	 my $msg_id 		= $stattmp[2];
	 my $msg_type 		= $stattmp[3];
	 my $userkey 		= $stattmp[4];
	 my $number 		= "+" . $stattmp[5];
	 my $notify_message 	= $stattmp[6];
	 my $now 		= localtime;

	 my $userdata		= get_record("userkey",$userkey);

=head2

=over 4

=item * If no registered aspsms-t user was found, InMessage() send an error
back via jabber.

=back

=cut
	 unless($userkey eq $ASPSMS::config::transport_secret)
	  {
	   if($userdata == -2)
	    {
	     aspsmst_log("alert","id: $transid InMessage(): No user found for userkey=$userkey");
	     $ASPSMS::config::aspsmst_in_progress=0;
	     return -2;
	    } ### END OF if($userdata == -2)

	  } ### END OF unless($streamtype eq $ASPSMS::config::transport_secret)

	 #
	 # If $streamtype is notify via aspsms-t.notify
	 #
         if ($streamtype eq 'notify')
	  {
	   my $to_jid = $userdata->{jid};
	   if ($to_jid eq "No userkey file")
	    {
	   	aspsmst_log("info","id: $transid InMessage(): Can not find file for userkey $userkey");
		sendAdminMessage("info","id:$transid InMessage(): Can not find file for userkey $userkey");
	        $ASPSMS::config::aspsmst_in_progress=0;
		return undef;
	    } ### END of if ($to_jid eq "No userkey file")

	   aspsmst_log('info',"id:$transid InMessage($to_jid): Send `$notify_message` notification");

=head2

=over 4

=item * If $streamtype was 'notify`, we send back a delivery notification to
the jabber user.

=back

=cut

	   SendMessage(	"$number\@$ASPSMS::config::service_name",
	   		$to_jid,
			$transid,
			$msg_id,
			$msg_type,
			"Notification",
			"
SMS recipient: $number 
Delivery status: === $notify_message ===
Date & Time: $now");

          } # END of if ($streamtype eq 'notify')
=head2

=over 4

=item * If $streamtype is 'twoway` via aspsms-t.notify, we send incoming 
sms via http to the jabber user via jabber.

=back

=cut
	 if ($streamtype eq 'twoway')
	  {
	   my $to_jid = $userdata->{jid};
	   
  	   $number =~ s/\+00/\+/g;

	   aspsmst_log('info',"InMessage(): Incoming two-way message from $number to $to_jid");
 	   SendMessage("$number\@$ASPSMS::config::service_name",$to_jid,$transid,$msg_id,$msg_type,"Global Two-Way Message from $number",$notify_message);

	  } ### END of if ($streamtype eq 'twoway')

	 #
	 # If $streamtype is direct via web-notify.pl
	 #
	 if ($streamtype eq 'direct')
	  {
	   # Direct notify example
	   # http://url/web-notify.pl?xml=direct,,,1234random,,,1234msgid,,,<Originator>,,,mysecret,,,<MessageData>

	   # Get the <stream/> from web-notify.pl
	   my $number		= $stattmp[3];
	   my $to_jid 		= $stattmp[5];
	   my $direct_body	= $stattmp[5];
	   $to_jid 		=~ s/([^\s]+)(.*)/$1/;
	   $direct_body		=~ s/([^\s]+)(.*)/$2/;
	   #
	   # Remove whitespaces from $number
	   #
	   $number		=~ s/\s/\_/g;

	   if($userkey eq $ASPSMS::config::transport_secret)
	    {
	     aspsmst_log('info',"InMessage(): Incoming direct message from $number to $to_jid");
	     if ($to_jid =~ /@/)
	      { 
	       SendMessage(	"$number\@$ASPSMS::config::service_name",
	       			$to_jid,
				$transid,
				$msg_id,
				$msg_type,
				"Direct message from $number",
				$direct_body); 
	      }
	     else
	      { aspsmst_log('info',"InMessage(): Not a valid jid `$to_jid`"); }
	    }
	   else
	    {
	     aspsmst_log('info',"InMessage(): Incoming direct message not delivered: secret:`$userkey` $ASPSMS::config::transport_secret does not match");
	    }

	  } ### END of if ($streamtype eq 'direct')

	$ASPSMS::config::aspsmst_stat_notification_counter++;
	$ASPSMS::config::aspsmst_in_progress=0;
	return;
        } ### END of if ( $to eq $ASPSMS::config::service_name or $to eq "$co.....



	if ($msg_type eq 'error') {
		aspsmst_log('debug',"InMessage(): Error received: \n\n" . $message->GetXML());
		sendAdminMessage("debug","InMessage: Error received:\n\n".$message->GetXML()); 
		$ASPSMS::config::aspsmst_in_progress=0;
		return;
	}
  	if ( $number !~ /^\+[0-9]{3,50}$/ ) {
		my $msg = "Invalid number $number got, try a number like: +41xxx\@$ASPSMS::config::service_name";
		sendError($message, $from, $to, 400, $msg);
		$ASPSMS::config::aspsmst_in_progress=0;
		return;
	}

	if ( $body eq "" ) {
		aspsmst_log("info","id:$aspsmst_transaction_id InMessage(): Dropping empty message from `$from' to number `$number'");
		$ASPSMS::config::aspsmst_in_progress=0;
		return;
	}

	
	my $from_barejid	= get_barejid($from);
	aspsmst_log('info',"id:$aspsmst_transaction_id InMessage($from_barejid): To  number `$number'.");

=head2

=over 4

=item * Now we send the real sms message via Sendaspsms() through aspsms.com.

=back

=cut
	my ($result,$ret,$Credits,$CreditsUsed,$transid) = 
	  Sendaspsms(	$number,
			$barejid, 
			$body,
			$aspsmst_transaction_id,
			$msg_id,
			$msg_type);

	# If we have no success from aspsms.com, send an error
	unless($result == 1)
	 {
	  #
	  # If we do not have a result error number
	  # send a standard 404 error message stanza
	  #
	  unless($result eq "")
	   {
	    aspsmst_log('info',"id:$aspsmst_transaction_id InMessage($from_barejid): \$result=$result from Sendaspsms()");
	    $ASPSMS::config::aspsmst_stat_error_counter++;
	    sendError($message, $from, $to, 400, $ret);
	   }
	  else
	   {
	    #
	    # Normal error message stanza with $result
	    # code.
	    #
	    $ASPSMS::config::aspsmst_stat_error_counter++;
	    sendError($message, $from, $to, $result, $ret);
	   }
	   
	 } ### END OF unless($result ==1)
        else
	 {
	   SendMessage(	"$number\@$ASPSMS::config::service_name",
	   		$from,
			$transid,
			$msg_id,
			$msg_type,
			"Notification",
			"
SMS recipient: $number
Credits Used: $CreditsUsed / Balance:$Credits / Id: $transid");

	   $ASPSMS::config::aspsmst_stat_message_counter++;
	 } ### END OF else if($result==1)

	 #}; ### END OF EVAL
		
$ASPSMS::config::aspsmst_in_progress=0;
aspsmst_log('debug',"id:$aspsmst_transaction_id InMessage($from): End job");
} ### END of InMessage

1;

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2012 Marco Balmer <marco@balmer.name>

The Debian packaging is licensed under the 
GPL, see `/usr/share/common-licenses/GPL-2'.

=cut
