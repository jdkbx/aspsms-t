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
my $timer				= 295;

$config::stat_message_counter 		= 0;
$config::stat_error_counter 		= 0;
$config::stat_notification_counter 	= 0;

### END BASIC CONFIGURATION ###


aspsmst_log('info',"init(): $config::service_name - Version $config::release");
aspsmst_log('info',"init(): Using XML-Spec: $config::xmlspec");
aspsmst_log('info',"init(): Using AffilliateId: $config::affiliateid");
aspsmst_log('info',"init(): Using Notifcation URL: $config::notificationurl");
aspsmst_log('info',"init(): Using admin jid: $config::admin_jid");
aspsmst_log('info',"init(): Using banner $config::banner");


umask(0177);

$SIG{KILL} 	= \&Stop;
$SIG{TERM} 	= \&Stop;
$SIG{INT} 	= \&Stop;
$SIG{ALRM} 	= sub { die "Unexepted Timeout" };



# SMS Gateway Associations
use constant DEFAULT_GATEWAY => 'aspsms';
#my %sms_callbacks 	= ("aspsms"	=> \&Sendaspsms	);


SetupConnection();
Connect();

sendAdminMessage("info","Starting up...");

# Loop until we're finished.
while () 
 {
  $timer++;
  ReConnect() unless defined($config::Connection->Process(1));
  #aspsmst_log('info',"Main: Timer: $timer");
  if($timer == 300)
   {
    aspsmst_log('info',"main(): [stat] Successfully: $config::stat_message_counter Notifications: $config::stat_notification_counter Errors: $config::stat_error_counter Stanzas: $config::stat_stanzas\n");
    $timer = 0;
   } 
 }

aspsmst_log('info',"main(): The connection was killed...\n");

exit(0);

sub InMessage {
  # Incoming message. Let's try to send it via SMS.
  # If error we've got, we log it... ;-)
  	
	$config::stat_stanzas++;

	my $sid 		= shift;
	my $message 		= shift;
	my $from 		= $message->GetFrom();
	my $to 			= $message->GetTo();
	my $body 		= $message->GetBody();
	my $type 		= $message->GetType();
	my $thread		= $message->GetThread();
	my ($number) 		= split(/@/, $to);
	my ($barejid) 		= split (/\//, $from);
	



	aspsmst_log('notice',"InMessage($from): Begin job");
	
       if ( $to eq $config::service_name or $to eq "$config::service_name/registered" ) 
        {
	 #my $msg		= new Net::Jabber::Message();
         
	 aspsmst_log('notice',"InMessage(): Sending welcome message for $from");
  	 WelcomeMessage($from);

	 #
	 # Send all messages addressed to the transport jid also to the 
	 # transport admin.
	 #

	 sendAdminMessage("info","Message from $from directly addressed to $config::service_name:\n\n$body");

	 return;
	} # end of welcome message
	
	#eval {

	
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

	 my $to_jid 		= get_jid_from_userkey($userkey);

	 if ($to_jid eq "No userkey file")
	  {
	   	aspsmst_log("info","InMessage(): Can not find file for userkey $userkey");
		sendAdminMessage("info","Can not find file for userkey $userkey");
		return undef;
	  }

	 my $now 		= localtime;

         if ($streamtype eq 'notify')
	  {

	   aspsmst_log("notice","InMessage(): \$notify_message=$notify_message");

	   if ($notify_message eq 'Delivered')
	    {
	     sendContactStatus($to_jid,"$number"."@".$config::service_name,'online',"Message $transid successfully delivered. Now I am idle...");
	    } ### END of if ($notify_message eq 'Delivered')  ###

	   # send contact status
	   if ($notify_message eq 'Buffered')
	    {
	     sendContactStatus($to_jid,"$number"."@".$config::service_name,'online',"Sorry, message buffered, waiting for better results ;-)");
	    } ### END of if ($notify_message eq 'Buffered')  ###

	   aspsmst_log('info',"InMessage($to_jid): Send `$notify_message` notification for message  $transid");

	   SendMessage(	"$number\@$config::service_name",
	   		$to_jid,
			"$notify_message status for message $transid",
			"SMS with transaction number `$transid` sent to number $number 
			
has status: $notify_message @ $now");

          } # END of if ($streamtype eq 'notify')
	
	 if ($streamtype eq 'twoway')
	  {
	   
  	   $number =~ s/\+00/\+/g;
	   aspsmst_log('info',"InMessage(): Incoming two-way message from $number to $to_jid");
	   $msg->SetMessage(	type    =>"",
	 			subject =>"Global Two-Way Message from $number",
				to      =>$to_jid,
				from    =>"$number\@$config::service_name",
				body    =>"$number wrote @ $now :

$notify_message

$config::ident Gateway system v$config::release

Project-Page: 
http://www.micressor.ch/content/projects/aspsms-t
");
  	   $config::Connection->Send($msg);
	  } ### END of if ($streamtype eq 'twoway')

	$config::stat_notification_counter++;
	return;
        } ### END of if ( $to eq $config::service_name or $to eq "$co.....



	if ($type eq 'error') {
		aspsmst_log('info',"InMessage(): Error received: \n\n" . $message->GetXML());
		sendAdminMessage("info","InMessage: Error received:\n\n".$message->GetXML()); 
		return;
	}
  	if ( $number !~ /^\+[0-9]{3,50}$/ ) {
		my $msg = "Invalid number $number got, try a number like: +41xxx\@$config::service_name";
		sendError($message, $from, $to, 404, $msg);
		return;
	}

	if ( $body eq "" ) {
		aspsmst_log('info',"InMessage(): Dropping empty message from `$from' to number `$number'");
		return;
	}

	
	my $from_barejid	= get_barejid($from);
	aspsmst_log('info',"InMessage($from_barejid): To  number `$number'.");
	
	#my ($barejid) = split(/\//, $from);

	sendContactStatus($from,$to,'dnd',"Working on delivery for $number. Please wait...");

	# no send the real sms message by Sendaspsms();
	my ($result,$ret,$Credits,$CreditsUsed,$transid) = Sendaspsms($number, $barejid, $body);

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
	  sendContactStatus($from,$to,'away',"Delivered to aspsms.com, waiting for delivery status notification
Balance: $Credits Used: $CreditsUsed");

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
 #sendPresence($workpresence, $from, $to, 'available',$show,$status);
 }


sub Stop {
# Terminate the SMS component's current run.
my $err = shift;

aspsmst_log('info',"Stop(): Shutting down aspsms-t because sig: $err");
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

#$Connection->Connect();
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
