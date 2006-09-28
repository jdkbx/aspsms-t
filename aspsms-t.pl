#!/usr/bin/perl 
# aspsms-t by Marco Balmer <mb@micressor.ch> @2006
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

use strict;
use lib "./";

use config;
use Iq;
use Presence;
use ASPSMS::Jid;

use Net::Jabber qw(Component);

use XML::Parser;
use XML::Smart;

use ASPSMS::Message;
use ASPSMS::Sendaspsms;
use ASPSMS::Connection;
use ASPSMS::userhandler;
use ASPSMS::xmlmodel;
use ASPSMS::UCS2;
use ASPSMS::aspsmstlog;

				  
### BEGIN CONFIGURATION ###

print "\naspsms-t $config::release";

unless ($ARGV[0] eq '-c')
 {
  print "\nUsage: ./aspsms-t.pl -c aspsms.xml\n\n";
  exit(-1);
 }
else
 {
  aspsmst_log("info","Starting up...");
  set_config($ARGV[1]);
 }

use Sys::Syslog;
openlog($config::ident,'',"$config::facility");

# Initialisation timer for message and notification statistic to syslog
# Every 300 seconds, it will generate a syslog entry with statistic infos
my $timer					= 295;
my $transport_uptime				= 0;
my $aspsmst_flag_shutdown			= 0;
my $aspsmst_stat_msg_per_hour			= 0;

$config::aspsmst_stat_message_counter 		= 0;
$config::aspsmst_stat_error_counter 		= 0;
$config::aspsmst_stat_notification_counter 	= 0;

### END BASIC CONFIGURATION ###


aspsmst_log('info',"init(): $config::service_name - Version $config::release`");
aspsmst_log('info',"init(): Using XML-Spec `$config::xmlspec`");
aspsmst_log('info',"init(): Using AffilliateId `$config::affiliateid`");
aspsmst_log('info',"init(): Using Notifcation URL `$config::notificationurl`");
aspsmst_log('info',"init(): Using admin jid `$config::admin_jid`");


umask(0177);

$SIG{KILL} 	= sub { $aspsmst_flag_shutdown="KILL"; 	};
$SIG{TERM} 	= sub { $aspsmst_flag_shutdown="TERM"; 	};
$SIG{INT} 	= sub { $aspsmst_flag_shutdown="INT"; 	};
$SIG{ABRT} 	= sub { $aspsmst_flag_shutdown="ABRT"; 	};
$SIG{SEGV} 	= sub { $aspsmst_flag_shutdown="SEGV"; 	};
$SIG{ALRM} 	= sub { die "Unexepted Timeout" 	};

SetupConnection();
Connect();

sendAdminMessage("info","Init(): \$service_name=$config::service_name \$release=$config::release");

#
# aspsms-t main loop until we're finished.
#
while () 
 {

  $transport_uptime++;$timer++;

  #
  # Check every second for work (Process(1))
  #

  ReConnect() unless defined($config::Connection->Process(1));
  if($timer == 300)
   {
     #
     # Calculate messages per hour
     #
     $aspsmst_stat_msg_per_hour  = $config::aspsmst_stat_message_counter / ($transport_uptime/3600);
     $aspsmst_stat_msg_per_hour  = sprintf("%.3f",$aspsmst_stat_msg_per_hour);
     #
     # Logging status message
     #
     aspsmst_log('info',"main(): [stat] Uptime: $transport_uptime secs Notifications: $config::aspsmst_stat_notification_counter Errors: $config::aspsmst_stat_error_counter Stanzas: $config::aspsmst_stat_stanzas\n");
     aspsmst_log('info',"main(): [stat] SMS Successfully: $config::aspsmst_stat_message_counter\n");
     aspsmst_log('info',"main(): [stat] SMS Notifications: $config::aspsmst_stat_notification_counter\n");
     aspsmst_log('info',"main(): [stat] SMS delivery errors: $config::aspsmst_stat_error_counter\n");
     aspsmst_log('info',"main(): [stat] XMPP/Jabber stanzas counter: $config::aspsmst_stat_stanzas\n");
     aspsmst_log('info',"main(): [stat] Messages/hour: $aspsmst_stat_msg_per_hour\n");
     aspsmst_log('info',"main(): [stat] \$aspsmst_flag_shutdown=$aspsmst_flag_shutdown\n");
    $timer = 0;
   } 

 #
 # Entry point for shutdown if flag is set
 #
 unless($aspsmst_flag_shutdown eq "0")
  {
   Stop($aspsmst_flag_shutdown);
  }
   
 } ### END of Loop

Stop("The connection was killed...");
#
# END Main script
#

sub InMessage {
  # Incoming message. Let's try to send it via SMS.
  # If error we've got, we log it... ;-)


  
  	
	$config::aspsmst_stat_stanzas++;
	$config::aspsmst_in_progress=1;

	#
	# Random transaction number for message
	#
  	my $aspsmst_transaction_id = int( rand(10000)) + 10000;
	my $sid 		= shift;
	my $message 		= shift;
	my $from 		= $message->GetFrom();
	my $to 			= $message->GetTo();
	my $body 		= $message->GetBody();
	my $type 		= $message->GetType();
	my $thread		= $message->GetThread();
	my ($number) 		= split(/@/, $to);
	my ($barejid) 		= split (/\//, $from);

	aspsmst_log('notice',"InMessage($from): id:$aspsmst_transaction_id Begin job");
	
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
	
       if ( $to eq $config::service_name."/notification" and $barejid eq $config::notificationjid ) 
        {
	 my $msg		= new Net::Jabber::Message();
	 # Get the <stream/> from aspsms.notification.pl
	 my @stattmp 		= split(/,,,/, $body);
	 my $streamtype		= $stattmp[0];
	 my $transid 		= $stattmp[1];
	 my $userkey 		= $stattmp[2];
	 my $number 		= "+" . $stattmp[3];
	 my $notify_message 	= $stattmp[4];

	 my $to_jid 		= get_jid_from_userkey($userkey,$aspsmst_transaction_id);

	 if ($to_jid eq "No userkey file")
	  {
	   	aspsmst_log("info","InMessage(): id:$transid Can not find file for userkey $userkey");
		sendAdminMessage("info","id:$transid Can not find file for userkey $userkey");
	        $config::aspsmst_in_progress=0;
		return undef;
	  }

	 my $now 		= localtime;

	 #
	 # If $streamtype is notify via aspsms.notification.pl
	 #
         if ($streamtype eq 'notify')
	  {

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
 	   SendMessage("$number\@$config::service_name",$to_jid,"Global Two-Way Message from $number",$notify_message);

	  } ### END of if ($streamtype eq 'twoway')

	 #
	 # If $streamtype is direct via aspsms.notification.pl
	 #
	 if ($streamtype eq 'direct')
	  {
	   my @http_stream 	= split(/,,,/, $body);
	   $body 		= $http_stream[4];
	   $body 		=~ s/([^\s]+)(.*)/$2/;
	   my $to_jid 		= $http_stream[4];
	   $to_jid 		=~ s/([^\s]+)(.*)/$1/;
  	   $number 		=~ s/\+00/\+/g;
	   my $userkey_secret	= $http_stream[2];

	   if($userkey_secret eq $config::transport_secret)
	    {
	     aspsmst_log('info',"InMessage(): Incoming direct message from $number to $to_jid");
	     if ($to_jid =~ /@/)
	      { SendMessage("$number\@$config::service_name",$to_jid,"Direct message from $number",$body); }
	     else
	      { aspsmst_log('info',"InMessage(): Not a valid jid `$to_jid`"); }
	    }
	   else
	    {
	     aspsmst_log('info',"InMessage(): Incoming direct message not delivered: secret:`$userkey_secret` does not match");
	    }

	  } ### END of if ($streamtype eq 'direct')

	$config::aspsmst_stat_notification_counter++;
	$config::aspsmst_in_progress=0;
	return;
        } ### END of if ( $to eq $config::service_name or $to eq "$co.....



	if ($type eq 'error') {
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
		aspsmst_log('info',"InMessage(): Dropping empty message from `$from' to number `$number'");
		$config::aspsmst_in_progress=0;
		return;
	}

	
	my $from_barejid	= get_barejid($from);
	aspsmst_log('info',"InMessage($from_barejid): id:$aspsmst_transaction_id To  number `$number'.");
	#sendContactStatus($from,$to,'dnd',"Working on delivery for $number. Please wait...");

	# no send the real sms message by Sendaspsms();
	my ($result,$ret,$Credits,$CreditsUsed,$transid) = Sendaspsms($number,$barejid, $body,$aspsmst_transaction_id);

	# If we have no success from aspsms.com, send an error
	unless($result == 1)
	 {
	  sendContactStatus($from,$to,'online','Last message failed');
	  sendError($message, $from, $to, $result, $ret);
	 }
        else
	 {
	   SendMessage(	"$number\@$config::service_name",
	   		$from,
			"Delivered to aspsms.com",
			"SMS with transaction number `$transid` sent to number $number 
			
Credits used: $CreditsUsed
Credits total: $Credits
");
	  #sendContactStatus($from,$to,'away',"Delivered to aspsms.com, waiting for delivery status notification
#Balance: $Credits Used: $CreditsUsed");
	   $config::aspsmst_stat_message_counter++;

	 }

	 #}; ### END OF EVAL
		
aspsmst_log('notice',"InMessage($from): End job");
}

sub sendContactStatus
 {
  my $from 		= shift;
  my $to		= shift;
  my $show		= shift;
  my $status		= shift;
  my $from_barejid	= get_barejid($from);

 my $workpresence = new Net::Jabber::Presence();
 aspsmst_log('notice',"sendContactStatus($from_barejid): Sending `$status'");
 sendPresence(undef,$from,$to,undef,$show,$status,5);
 }


sub Stop {
# Terminate the SMS component's current run.
my $err = shift;
aspsmst_log('info',"Stop(): Shutting down aspsms-t \$aspsmst_in_progress=$config::aspsmst_in_progress \$aspsmst_flag_shutdown=$aspsmst_flag_shutdown");


unless($config::aspsmst_in_progress==0)
 {
  aspsmst_log('info',"Stop(): Waiting for shutdown, aspsms-t is still working");
  return -1;
 }

sendAdminMessage("info","Stop(): \$aspsmst_in_progress=$config::aspsmst_in_progress \$aspsmst_flag_shutdown=$aspsmst_flag_shutdown \$err=$err");
aspsmst_log('info',"Stop(): Shutting down aspsms-t because sig: $err\n");
$config::Connection->Disconnect();
exit(0);
}

sub SetupConnection {

$config::Connection = new Net::Jabber::Component(debuglevel=>0, debugfile=>"stdout");

my $status = $config::Connection->Connect("hostname" => $config::server, "port" => $config::port, "secret" => $config::secret, "componentname" => $config::service_name);
$config::Connection->AuthSend("secret" => $config::secret);

if (!(defined($status))) {
  aspsmst_log("info","SetupConnection(): Error: Jabber server is down or connection was not allowed. $!\n");
}

$config::Connection->SetCallBacks("message" => \&InMessage, "presence" => \&InPresence, "iq" => \&InIQ);

} # END of sub SetupConnection;


sub Connect {

my $status = $config::Connection->Connected();
aspsmst_log('info',"Connect(): Transport connected to jabber-server $config::server:$config::port") if($status == 1);
aspsmst_log('info',"Connect(): aspsms-t running and ready for queries") if ($status == 1) ;


if ($status == 0)
	{

		aspsmst_log('info',"Connect(): Transport not connected, waiting 5 seconds...");
		sleep(5);
		Connect();
	}

} # END of sub Connect

sub ReConnect {

aspsmst_log('info',"ReConnect(): Connection to jabber lost, waiting 2 seconds...");
sleep(2);
aspsmst_log('info',"ReConnect(): Reconnecting...");
SetupConnection();
Connect();

}
