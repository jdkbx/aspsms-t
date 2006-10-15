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

package InMessage;

use strict;
use vars qw(@EXPORT @ISA);

use ASPSMS::aspsmstlog;
use ASPSMS::Sendaspsms;
use ASPSMS::Jid;
use ASPSMS::SendContactStatus;
use ASPSMS::Message;
use Presence;

use Exporter;
use Sys::Syslog;

openlog($config::ident,'','user');


@ISA 				= qw(Exporter);
@EXPORT 			= qw(InMessage);



sub InMessage {
  # Incoming message. Let's try to send it via SMS.
  # If error we've got, we log it... ;-)


  
  	
	$config::aspsmst_stat_stanzas++;
	$config::aspsmst_in_progress=1;

	#
	# Random transaction number for message
	#
	my $sid 		= shift;
	my $message 		= shift;
	my $from 		= $message->GetFrom();
	my $to 			= $message->GetTo();
	my $body 		= $message->GetBody();
	my $msg_type 		= $message->GetType();
	my $msg_id		= $message->GetID();
	my ($number) 		= split(/@/, $to);
	my ($barejid) 		= split (/\//, $from);
  	my $aspsmst_transaction_id = int( rand(10000)) + 10000;

	aspsmst_log('notice',"id:$aspsmst_transaction_id InMessage($barejid): Begin job");
	aspsmst_log('notice',"id:$aspsmst_transaction_id InMessage($barejid): \$msg_id=$msg_id");

	unless($config::aspsmst_flag_shutdown eq "0")
 	 {
	  sendError($message, $from, $to, 404, "Sorry, $config::ident has a lot of work or is shutting down at the moment, please try again later. Thanks.");
	  $config::aspsmst_in_progress=0;
	  return -1;
	 }


       if ( $to eq $config::service_name or $to eq "$config::service_name/registered" ) 
        {
	 aspsmst_log('notice',"InMessage(): id:$aspsmst_transaction_id Sending welcome message for $from");
  	 WelcomeMessage($from);

	 #
	 # Send all messages addressed to the transport jid also to the 
	 # transport admin.
	 #

	 sendAdminMessage("info","Message from $from directly addressed to $config::service_name:\n\n$body");

	 $config::aspsmst_in_progress=0;
	 return;
	} # end of welcome message
	
       if ( $to eq $config::service_name."/notification" and $barejid eq $config::notificationjid) 
        {
	 my $msg		= new Net::Jabber::Message();
	 # Get the <stream/> from aspsms.notification.pl
	 my @stattmp 		= split(/,,,/, $body);
	 my $streamtype		= $stattmp[0];
	 my $transid 		= $stattmp[1];
	 my $msg_id 		= $stattmp[2];
	 my $msg_type 		= $stattmp[3];
	 my $userkey 		= $stattmp[4];
	 my $number 		= "+" . $stattmp[5];
	 my $notify_message 	= $stattmp[6];
	 my $now 		= localtime;

	 my $userdata		= get_record("userkey",$userkey);
	 my $to_jid 		= $userdata->{jid};

	 #
	 # If $streamtype is notify via aspsms.notification.pl
	 #
         if ($streamtype eq 'notify')
	  {
	   if ($to_jid eq "No userkey file")
	    {
	   	aspsmst_log("info","InMessage(): id:$transid Can not find file for userkey $userkey");
		sendAdminMessage("info","id:$transid Can not find file for userkey $userkey");
	        $config::aspsmst_in_progress=0;
		return undef;
	    } ### END of if ($to_jid eq "No userkey file")

	   aspsmst_log("notice","InMessage(): id:$transid \$notify_message=$notify_message");

	   if ($notify_message eq 'Delivered')
	    {
	     #sendContactStatus($to_jid,"$number"."@".$config::service_name,'online',"Message $transid successfully delivered. Now I am idle...");
	    } ### END of if ($notify_message eq 'Delivered')  ###

	   # send contact status
	   if ($notify_message eq 'Buffered')
	    {
	     #sendContactStatus($to_jid,"$number"."@".$config::service_name,'online',"Sorry, message buffered, waiting for better results ;-)");
	    } ### END of if ($notify_message eq 'Buffered')  ###

	   aspsmst_log('info',"InMessage($to_jid): id:$transid Send `$notify_message` notification for message  $transid");

	   SendMessage(	"$number\@$config::service_name",
	   		$to_jid,
			$transid,
			$msg_id,
			$msg_type,
			"$notify_message status for message $transid",
			"SMS with transaction number `$transid` sent to number $number 
			
has status: $notify_message @ $now");

          } # END of if ($streamtype eq 'notify')
	
	 #
	 # If $streamtype is twoway via aspsms.notification.pl
	 #
	 if ($streamtype eq 'twoway')
	  {
	   
  	   $number =~ s/\+00/\+/g;

	   aspsmst_log('info',"InMessage(): Incoming two-way message from $number to $to_jid");
 	   SendMessage("$number\@$config::service_name",$to_jid,$transid,$msg_id,$msg_type,"Global Two-Way Message from $number",$notify_message);

	  } ### END of if ($streamtype eq 'twoway')

	 #
	 # If $streamtype is direct via aspsms.notification.pl
	 #
	 if ($streamtype eq 'direct')
	  {
	   # Direct notify example
	   # http://url/aspsms.notification.pl?xml=direct,,,1234random,,,1234msgid,,,<Originator>,,,mysecret,,,<MessageData>

	   # Get the <stream/> from aspsms.notification.pl
	   my $number		= $stattmp[3];
	   my $to_jid 		= $stattmp[5];
	   my $direct_body	= $stattmp[5];
	   $to_jid 		=~ s/([^\s]+)(.*)/$1/;
	   $direct_body		=~ s/([^\s]+)(.*)/$2/;

	   if($userkey eq $config::transport_secret)
	    {
	     aspsmst_log('info',"InMessage(): Incoming direct message from $number to $to_jid");
	     if ($to_jid =~ /@/)
	      { SendMessage("$number\@$config::service_name",$to_jid,$transid,$msg_id,$msg_type,"Direct message from $number",$direct_body); }
	     else
	      { aspsmst_log('info',"InMessage(): Not a valid jid `$to_jid`"); }
	    }
	   else
	    {
	     aspsmst_log('info',"InMessage(): Incoming direct message not delivered: secret:`$userkey` does not match");
	    }

	  } ### END of if ($streamtype eq 'direct')

	$config::aspsmst_stat_notification_counter++;
	$config::aspsmst_in_progress=0;
	return;
        } ### END of if ( $to eq $config::service_name or $to eq "$co.....



	if ($msg_type eq 'error') {
		aspsmst_log('info',"InMessage(): Error received: \n\n" . $message->GetXML());
		sendAdminMessage("info","InMessage: Error received:\n\n".$message->GetXML()); 
		$config::aspsmst_in_progress=0;
		return;
	}
  	if ( $number !~ /^\+[0-9]{3,50}$/ ) {
		my $msg = "Invalid number $number got, try a number like: +41xxx\@$config::service_name";
		sendError($message, $from, $to, 404, $msg);
		$config::aspsmst_in_progress=0;
		return;
	}

	if ( $body eq "" ) {
		aspsmst_log("info","id:$aspsmst_transaction_id InMessage(): Dropping empty message from `$from' to number `$number'");
		$config::aspsmst_in_progress=0;
		return;
	}

	
	my $from_barejid	= get_barejid($from);
	aspsmst_log('info',"id:$aspsmst_transaction_id InMessage($from_barejid): To  number `$number'.");
	#sendContactStatus($from,$to,'dnd',"Working on delivery for $number. Please wait...");

	# no send the real sms message by Sendaspsms();
	my ($result,$ret,$Credits,$CreditsUsed,$transid) = Sendaspsms(	$number,
									$barejid, 
									$body,
									$aspsmst_transaction_id,
									$msg_id,
									$msg_type);

	# If we have no success from aspsms.com, send an error
	unless($result == 1)
	 {
	  sendContactStatus($from,$to,'online',$ret);
	  #
	  # If we do not have a result error number
	  # send a standard 404 error message stanza
	  #
	  unless($result eq "")
	   {
	    aspsmst_log('info',"InMessage($from_barejid): id:$aspsmst_transaction_id \$result=$result from Sendaspsms()");
	    $config::aspsmst_stat_error_counter++;
	    sendError($message, $from, $to, 404, $ret);
	   }
	  else
	   {
	    #
	    # Normal error message stanza with $result
	    # code.
	    #
	    $config::aspsmst_stat_error_counter++;
	    sendError($message, $from, $to, $result, $ret);
	   }
	   
	 } ### END OF unless($result ==1)
        else
	 {
	   SendMessage(	"$number\@$config::service_name",
	   		$from,
			$transid,
			$msg_id,
			$msg_type,
			"Delivered to aspsms.com",
			"SMS with transaction number `$transid` sent to number $number 
			
Credits used: $CreditsUsed
Credits total: $Credits
");
	  #sendContactStatus($from,$to,'away',"Delivered to aspsms.com, waiting for delivery status notification
#Balance: $Credits Used: $CreditsUsed");
	   $config::aspsmst_stat_message_counter++;

	 } ### END OF else if($result==1)

	 #}; ### END OF EVAL
		
$config::aspsmst_in_progress=0;
aspsmst_log('notice',"id:$aspsmst_transaction_id InMessage($from): End job");
} ### END of InMessage

1;

