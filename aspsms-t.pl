#!/usr/bin/perl 
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

use strict;
use lib "./";

use config;
use ASPSMS::aspsmstlog;
use ASPSMS::Message;
use ASPSMS::Debug;
				  
### BEGIN CONFIGURATION ###
use constant SERVICE_NAME 	=> 	$config::service_name;
use constant SERVER       	=> 	$config::server;
use constant PORT         	=> 	$config::port;
use constant SECRET       	=> 	$config::secret;
use constant PASSWORDS    	=> 	$config::passwords;
use constant RELEASE      	=> 	$config::release;
use constant XMLSPEC		=> 	$config::xmlspec;
my $aspsmssocket		= 	$config::aspsmssocket;
my $banner			= 	$config::banner;
my $admin_jid			= 	$config::admin_jid;
my $spooldir			=	$config::passwords;

# Initialisation timer for message and notification statistic to syslog
# Every 300 seconds, it will generate a syslog entry with statistic infos
my $timer				= 295;

$config::Message_Counter 		= 0;
$config::Message_Counter_Error 		= 0;
$config::Message_Notification_Counter 	= 0;
### END BASIC CONFIGURATION ###

use Sys::Syslog;

openlog($config::ident,'',"$config::facility");

aspsmst_log("info","Starting up...");
aspsmst_log('info',"init(): ".SERVICE_NAME." - Version ".RELEASE);
aspsmst_log('info',"init(): Using XML-Spec: ".XMLSPEC);
aspsmst_log('info',"init(): Using AffilliateId: $config::affiliateid");
aspsmst_log('info',"init(): Using Notifcation URL: $config::notificationurl");
aspsmst_log('info',"init(): Using admin jid: $admin_jid");
aspsmst_log('info',"init(): Using banner $banner");

use Net::Jabber qw(Component);
use XML::Parser;
use XML::Smart;
use ASPSMS::xmlmodel;
use ASPSMS::userhandler;
use ASPSMS::handler;
#use strict;

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

 my $initialmsg                = new Net::Jabber::Message();
 $initialmsg->SetMessage(      type    =>"",
                               subject =>"Wecome to $config::ident",
			       to      =>$config::admin_jid,
			       from    =>SERVICE_NAME,
			       body    =>"$config::ident Starting up v".RELEASE);
 $config::Connection->Send($initialmsg);

# Loop until we're finished.
while () 
 {
  $timer++;
  ReConnect() unless defined($config::Connection->Process(1));
  #aspsmst_log('info',"Main: Timer: $timer");
  if($timer == 300)
   {
    aspsmst_log('info',"main(): Message deliveries: Success: $config::Message_Counter Notifications: $config::Message_Notification_Counter Error: $config::Message_Counter_Error\n");
    $timer = 0;
   } 
 }

aspsmst_log('info',"main(): The connection was killed...\n");

exit(0);

sub InMessage {
  # Incoming message. Let's try to send it via SMS.
  # If error we've got, we log it... ;-)

	my $sid 		= shift;
	my $message 		= shift;
	my $from 		= $message->GetFrom();
	my $to 			= $message->GetTo();
	my $body 		= $message->GetBody();
	my $type 		= $message->GetType();
	my $thread		= $message->GetThread();
	my ($number) 		= split(/@/, $to);
	my ($barejid) 		= split (/\//, $from);
	



	aspsmst_log('info',"InMessage($from): Begin job");
	
       if ( $to eq SERVICE_NAME or $to eq SERVICE_NAME."/registered" ) 
        {
	 my $msg		= new Net::Jabber::Message();
         
	 aspsmst_log('notice',"InMessage(): Sending welcome message for $from");
  	 
	 $msg->SetMessage(	type    =>"",
	 			subject =>"Wecome to $config::ident",
				to      =>$from,
				from    =>SERVICE_NAME,
				body    =>
"Hello, this is $config::ident at $config::service_name. 
It is a sms-transport gateway. If you wish to operate with it, please 
register an https://www.aspsms.com account, afterwards you can use 
it to send sms like +4178xxxxxxx@".SERVICE_NAME."

$config::ident Gateway system v$config::release

Project-Page: 
http://www.micressor.ch/content/projects/aspsms-t

");
				
	 $config::Connection->Send($msg);
	 return;
	} # end of welcome message
	
	eval {

	
       if ( $to eq SERVICE_NAME."/notification" and $barejid eq $config::notificationjid ) 
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
	 my $now 		= localtime;

         if ($streamtype eq 'notify')
	  {
	   if ($notify_message eq 'Delivered')
	    {
	     sendContactStatus($to_jid,"$number"."@".SERVICE_NAME,'online',"Message $transid successfully delivered. Now I am idle...");
	    } ### END of if ($notify_message eq 'Delivered')  ###
	   # send contact status
	   if ($notify_message eq 'Buffered')
	    {
	     sendContactStatus($to_jid,"$number"."@".SERVICE_NAME,'xa','Sorry, message buffered, waiting for better results ;-)');
	    } ### END of if ($notify_message eq 'Buffered')  ###

	   aspsmst_log('info',"InMessage($to_jid): Send `$notify_message` notification for message  $transid");
	   $msg->SetMessage(	type    =>"",
	 			subject =>"$notify_message status for message $transid",
				to      =>$to_jid,
				from    =>"$number"."@".SERVICE_NAME,
				body    =>"SMS $transid for $number has status: $notify_message @ $now

$config::ident Gateway system v$config::release
");	
  	   $config::Connection->Send($msg);


          } # END of if ($streamtype eq 'notify')
	
	 if ($streamtype eq 'twoway')
	  {
	   
  	   $number =~ s/\+00/\+/g;
	   aspsmst_log('info',"InMessage(): Notification.Two-Way: Message from $number to $to_jid");
	   $msg->SetMessage(	type    =>"",
	 			subject =>"Global Two-Way Message from $number",
				to      =>$to_jid,
				from    =>"$number"."@".SERVICE_NAME,
				body    =>"$number wrote @ $now :

$notify_message

$config::ident Gateway system v$config::release
");
  	   $config::Connection->Send($msg);
	  }
	

		$config::Message_Notification_Counter++;
	return;
        }

	if ($type eq 'error') {
		aspsmst_log('info',"InMessage(): Error received: \n\n" . $message->GetXML());
		return;
	}
  	if ( $number !~ /^\+[0-9]{3,50}$/ ) {
		my $msg = "Invalid number $number got, try a number like: +41xxx@".SERVICE_NAME;
		sendError($message, $from, $to, 404, $msg);
		return;
	}

	if ( $body eq "" ) {
		aspsmst_log('info',"InMessage(): Dropping empty message from `$from' to number `$number'");
		return;
	}

	
	aspsmst_log('info',"InMessage($from): To  number `$number'.");
	
	my ($barejid) = split(/\//, $from);

	sendContactStatus($from,$to,'dnd',"Working on delivery for $number. Please wait...");

	# no send the real sms message by Sendaspsms();
	my ($result,$ret,$Credits,$CreditsUsed) = Sendaspsms($number, $barejid, $body);

	# If we have no success from aspsms.com, send an error
	unless($result == 1)
	 {
	  sendContactStatus($from,$to,'online','Last message failed');
	  sendError($message, $from, $to, $result, $ret);
	 }
        else
	 {
	  sendContactStatus($from,$to,'away',"Delivered to aspsms.com, waiting for delivery status notification
Balance: $Credits Used: $CreditsUsed");

	  # Otherwise we send a delivery notification
	  #$message->SetTo("$from");
	  #$message->SetSubject("Delivery status");
	  #$message->SetBody($ret);
	  #$message->SetFrom("$to");
	  #$message->SetThread($thread);
	  #$Connection->Send($message);
	 }
	 }; ### END OF EVAL
	 if($?) { core_debug($?); } 
		
aspsmst_log('info',"InMessage($from): End job");
}

sub InIQ {
# Incoming IQ. Handle jabber:iq:registration with add/remove source dialog, return error 501 for other NS's.

my $sid 	= shift;
my $iq 		= shift;
my $from 	= $iq->GetFrom();
my $to 		= $iq->GetTo();
my $id 		= $iq->GetID();
my $type 	= $iq->GetType();
my $query 	= $iq->GetQuery();
my $xml		= $iq->GetXML();
return unless $query;

# If error in <iq/> 
if ($type eq 'error') 
{
 aspsmst_log('info',"InIQ(): Error: " . $iq->GetXML());
 return;
}

my $xmlns = $query->GetXMLNS();
my $barejid=get_barejid($from);
aspsmst_log('notice',"InIQ(): Incoming from $barejid");
aspsmst_log('debug',"InIQ(): $xml");
if ($xmlns eq 'jabber:iq:register') 
 {
  my $ret = jabber_register($sid,$iq,$from,$to,$id,$type,$query,$xml);
 } ### END jabber:iq:register ###
elsif ($xmlns eq 'jabber:iq:gateway') 
 {
  my $ret = jabber_iq_gateway($sid,$iq,$from,$to,$id,$type,$query,$xml);
 } ### END jabber:iq:gateway ###
elsif ($xmlns eq 'jabber:iq:browse') 
 {
  my $ret = jabber_iq_browse($sid,$iq,$from,$to,$id,$type,$query,$xml);
 } ### END jabber:iq:browse ###
elsif ($xmlns eq 'http://jabber.org/protocol/disco#info')
 {
   my $ret = jabber_iq_disco_info($sid,$iq,$from,$to,$id,$type,$query,$xml);
 }
elsif ($xmlns eq 'http://jabber.org/protocol/disco#items')
 {
  my $ret = jabber_iq_disco_items($sid,$iq,$from,$to,$id,$type,$query,$xml);
 }
elsif ($xmlns eq 'jabber:iq:version') 
  {
   if ($type eq 'get') 
    {
     $iq->SetType('result');
     $iq->SetFrom($iq->GetTo());
     $iq->SetTo($from);
     $query->SetName($config::browseservicename);
     $query->SetVer('R'.RELEASE);
     $query->SetOS($^O);
     $config::Connection->Send($iq);
    }
   else 
    {
     sendError($iq, $from, $to, 501, 'Not Implemented');
    }
   }
  else 
   {
    sendError($iq, $from, $to, 501, 'Not implemented (working on it ;-))');
   }
  }

sub sendError {
my ($msg, $to, $from, $code, $text) = @_;
	
$msg->SetType('error');
$msg->SetFrom($from);
$msg->SetTo($to);
$msg->SetErrorCode($code);
$msg->SetError($text);
$config::Connection->Send($msg);

aspsmst_log('info',"sendError(): Message to \"$to $code,$text\"");

}

sub sendPresence {
my ($pres, $to, $from, $type, $show, $status) = @_;

$pres->SetType($type);
$pres->SetShow($show);
$pres->SetStatus($status);
$pres->SetTo($to);
$pres->SetFrom($from);

my $to_barejid = get_barejid($to);
aspsmst_log('notice',"sendPresence($to_barejid): Sending presence type `$type' and status `$status'");

$config::Connection->Send($pres);

}

sub sendContactStatus
 {
  my $from 	= shift;
  my $to	= shift;
  my $show	= shift;
  my $status	= shift;

 my $workpresence = new Net::Jabber::Presence();
 aspsmst_log('info',"sendContactStatus($from): Sending `$status'");
 sendPresence($workpresence, $from, $to, 'available',$show,$status);
 }

# send presences for given number with resources indicating gateways
sub sendGWNumPresences {
my ($number, $to) = @_;	
my $prefix = substr($number, 1, 5);
my $presence = new Net::Jabber::Presence();

$presence->SetType('available');
$presence->SetShow(undef);
$presence->SetStatus(undef);
$presence->SetTo($to);

    $presence->SetFrom($number."@".SERVICE_NAME);
    $presence->SetPriority(5);
    aspsmst_log('notice',"sendGWNumPresences(): Sending presence from ".$presence->GetFrom()." to $to.");
    $config::Connection->Send($presence);
} ### END of sendGWNumPresences ###

sub InPresence {
# Incoming presence. Reply to subscription requests with proper subscription 
# actions, reply to probe presence with gateways presence.
# On registration requests, accept and send a gateways status presence update.

my $sid = shift;
my $presence = shift;
my $from = $presence->GetFrom();
my $to = $presence->GetTo();
my ($number) = split(/@/, $to);
my $type = $presence->GetType();
my $status = $presence->GetStatus();

my $barejid = get_barejid($from);
aspsmst_log('notice',"InPresence(): Got `$type' type presence from $barejid");

if ($type eq 'subscribe') 
 {
  if ( ($number !~ /^\+[0-9]{3,50}$/) && ($to ne SERVICE_NAME.'/registered') ) 
   {
    aspsmst_log('info',"InPresence(): Error: Invalid number `$number' got.");

    sendPresence($presence, $from, $to, 'unsubscribed');
    return;
   }
  
  sendPresence($presence, $from, $to, 'subscribed', );
  if ($to eq SERVICE_NAME.'/registered') 
   {
    sendPresence($presence, $from, $to, 'available', );
   } 
  else 
   {
    sendGWNumPresences($number, $from);
   }
 } 
elsif (($type eq 'available') or ($type eq 'probe')) 
 {
  if ( $number =~ /^\+[0-9]{3,50}$/ ) 
   {
    sendGWNumPresences($number, $from);
   }
  
  if ($to eq SERVICE_NAME.'/registered') 
   {
    sendPresence($presence, $from, $to, 'available', );
   }
 } 
elsif ($type eq 'unsubscribe') 
 {
  sendPresence($presence, $from, $to, 'unsubscribed');
 }
elsif ($type eq 'unavailable')
 {
  sendPresence($presence, $from, $to, 'unavailable');
 }
  


} ### END of InPresence ###

sub Stop {
# Terminate the SMS component's current run.
my $err = shift;

aspsmst_log('info',"Stop(): Shutting down aspsms-t because sig: $err");
$config::Connection->Disconnect();
exit(0);

}

sub SetupConnection {

$config::Connection = new Net::Jabber::Component(debuglevel=>0, debugfile=>"stdout");

my $status = $config::Connection->Connect("hostname" => SERVER, "port" => PORT, "secret" => SECRET, "componentname" => SERVICE_NAME);
$config::Connection->AuthSend("secret" => SECRET);

if (!(defined($status))) {
  aspsmst_log("info","SetupConnection(): Error: Jabber server is down or connection was not allowed. $!\n");
}

$config::Connection->SetCallBacks("message" => \&InMessage, "presence" => \&InPresence, "iq" => \&InIQ);

} # END of sub SetupConnection;


sub Connect {

#$Connection->Connect();
my $status = $config::Connection->Connected();
aspsmst_log('info',"Connect(): Transport connected to jabber-server " . SERVER . ":" . PORT) if($status == 1);
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

sub SendIQError {
my $id		= shift;
my $to	  	= shift;
my $errorcode 	= shift;
my $error 	= shift;
my $iq;

  aspsmst_log('info',"SendIQError(): Sending IQ to $to");
  $iq = new Net::Jabber::IQ();

  $iq->SetIQ(		type		=>"error",
                       	to		=>$to,
                       	errorcode	=>$errorcode,
                       	error		=>$error,
			from		=>SERVICE_NAME,
                      	id		=>$id);			


$config::Connection->Send($iq);
}

sub jabber_register

{
my $sid = shift;
my $iq = shift;
my $from = $iq->GetFrom();
my $to = $iq->GetTo();
my $id = $iq->GetID();
my $type = $iq->GetType();
my $query = $iq->GetQuery();
my $xml		= $iq->GetXML();


  if ($type eq 'get') 
   {
    $iq->SetType('result');
    $iq->SetFrom($iq->GetTo());
    $iq->SetTo($from);
    aspsmst_log('info',"jabber_register(): RegistrationManager.getForm: to $from");
    $query->SetInstructions('SMS gateway via aspsms.com

IMPORTANT: This gateway will only operate with an account from http://www.aspsms.com

Please enter UserKey (https://www.aspsms.ch/userkey.asp) and password of your 
aspsms.com account:');

    my $user = getUserPass($from,$banner);
    $query->SetUsername($user->{name});
    $query->SetURL($user->{signature});
    $query->SetPhone($user->{phone});
    $query->SetPassword('');
    $config::Connection->Send($iq);
   }
  elsif ($type eq 'set') 
   {
    my $gateway = 'aspsms'; # TODO! ->GetName() but only one gateway with passwords so far
    my $name 	= $query->GetUsername();
    my $phone 	= $query->GetPhone();
    my $pass 	= $query->GetPassword();
    my $signature = $query->GetURL();
    my $remove	= $query->GetRemove();
			
    # check aspsms user trough gateway of aspsms.com
    my ($ErrorCode,$ErrorDescription) = CheckNewUser($name,$pass);
    unless($ErrorCode == 1)
     {
      SendIQError($id,$from,$ErrorCode,$ErrorDescription);
      return;
     };

			
  my ($barefrom)  = split (/\//, $from);
  $phone          =~ s/\+/00/g;
  my $passfile = PASSWORDS."/$barefrom";

  # Remove = 1 ?????
  aspsmst_log('notice',"jabber_register(): remove flag: $remove for $from");
  unless ($remove == 1) 
   {
    aspsmst_log('info',"jabber_register(): Execute remove registration: for $from");
    # remove file	
    unlink($passfile);
	
    # send unsubscribe presence
    my $presence = new Net::Jabber::Presence;	
    sendPresence($presence, $from,SERVICE_NAME.'/registered', 'unsubscribe');
    # send iq result
    my $iq	= new Net::Jabber::IQ;
    $iq->SetIQ(	type	=>"result",
              	to	=>$barefrom,
		from	=>SERVICE_NAME,
               	id	=>$id);			

    $config::Connection->Send($iq);

    my $message = new Net::Jabber::Message();
    $message->SetMessage(
			type	=>"",
			to	=>$barefrom,
			from	=>SERVICE_NAME,
			body	=>"Sucessfully unregistred" );

    $config::Connection->Send($message);

    return;
   } # if ($remove) {

  open(F, ">$passfile") or aspsmst_log('notice',"jabber_register(): Couldn't open `$passfile' for writing");
  print(F "$gateway:$name:$pass:$phone:$signature\n");
  aspsmst_log('info',"jabber_register(): RegisterManager.Execute: for $from");

  $iq->SetType('result');
  $iq->SetFrom($iq->GetTo());
  $iq->SetTo($from);
  $config::Connection->Send($iq);
  my $confirm = new Net::Jabber::Message();
  $confirm->SetTo($admin_jid);
  $confirm->SetType('message');
  $confirm->SetFrom(SERVICE_NAME);
  $confirm->SetBody("RegisterManager.Complete: for \n\n$from $name:$phone:$pass:$signature \n\non $config::service_name");
  $config::Connection->Send($confirm);
  my $presence = new Net::Jabber::Presence();
  
  aspsmst_log('info',"jabber_register(): RegisterManager.Complete: for $from $name:$phone:$pass:$signature");
  
  close(F);
  sendPresence($presence, $from,SERVICE_NAME.'/registered', 'subscribe');
 } else 
    {
     sendError($iq, $from, $to, 501, 'jabber:iq:register request not implemented');
    }
} # END of jabber_register

### jabber_iq_gateway ####
sub jabber_iq_gateway 
{
my $sid = shift;
my $iq = shift;
my $from = $iq->GetFrom();
my $to = $iq->GetTo();
my $id = $iq->GetID();
my $type = $iq->GetType();
my $query = $iq->GetQuery();
my $xml		= $iq->GetXML();

     if ($type eq 'get') 
     {
      $iq->SetType('result');
      $iq->SetFrom($iq->GetTo());
      $iq->SetTo($from);
      $query->SetDesc('Choose your destination number like: +4179xxxxxxx');
      $query->SetPrompt('Number');
      $config::Connection->Send($iq);

      aspsmst_log('info',"jabber_iq_gateway(): Request: Gateway from $from");
     } 
    elsif ($type eq 'set') 
     {
      my $number = $query->GetPrompt();
      if ( $number =~ /\+[0-9]{3,50}/ ) 
       { }
      else
       {
        sendError($iq, $from, $to, 406, 'Number format not acceptable');		
       }

   $iq->SetType('result');
   $iq->SetFrom($iq->GetTo());
   $iq->SetTo($from);
   $query->SetPrompt("$number@".SERVICE_NAME);
   $query->SetJID("$number@".SERVICE_NAME);
   $config::Connection->Send($iq);
  }
 else 
  {
   sendError($iq, $from, $to, 501, 'Not Implemented');
  }
} ### END of jabber_iq_gateway

### jabber_iq_browse ###
sub jabber_iq_browse
{
my $sid 	= shift;
my $iq 		= shift;
my $from 	= $iq->GetFrom();
my $to 		= $iq->GetTo();
my $id 		= $iq->GetID();
my $type 	= $iq->GetType();
my $query 	= $iq->GetQuery();
my $xml		= $iq->GetXML();

  my $namespaces = [ 'jabber:iq:register', 'jabber:iq:gateway','jabber:iq:version' ];

  if ($type eq 'get') 
   {
    aspsmst_log('notice',"jabber_iq_browse(): Processing browse query for $from");
    $iq->SetType('result');
    $iq->SetFrom($iq->GetTo());
    $iq->SetTo($from);
    $query->SetJID(SERVICE_NAME);
    $query->SetCategory("service");
    $query->SetType($config::browseservicetype);
    $query->SetName($config::browseservicename);
    $query->SetNS($namespaces);
    $config::Connection->Send($iq);
    
   }
  else 
   {
    sendError($iq, $from, $to, 501, 'Not Implemented');
   }

} ### END of jabber:iq:browse

sub jabber_iq_disco_info
{
my $sid 	= shift;
my $iq 		= shift;
my $from 	= $iq->GetFrom();
my $to 		= $iq->GetTo();
my $id 		= $iq->GetID();
my $type 	= $iq->GetType();
my $query 	= $iq->GetQuery();
my $xml		= $iq->GetXML();

eval {

   if ($type eq 'get')
    {
    aspsmst_log('notice',"jabber_iq_disco_info(): Processing disco query from $from");
    $iq->SetType('result');
    $iq->SetFrom($iq->GetTo());
    $iq->SetTo($from);
    
    my $iqQuery = $iq->NewQuery("http://jabber.org/protocol/disco#info");


    $iqQuery->AddIdentity(	category=>"gateway",
                        	type=>"sms",
				name=>$config::browseservicename);

    $iqQuery->AddFeature(var=>"http://jabber.org/protocol/disco");
    $iqQuery->AddFeature(var=>"jabber:iq:register");
    $iqQuery->AddFeature(var=>"jabber:iq:gateway");
    $iqQuery->AddFeature(var=>"jabber:iq:version");

    $config::Connection->Send($iq);

    } # END of if ($type eq 'get'

};
if($?) { core_debug($?); }

} ### END of jabber_iq_disco_info ###

### jabber_iq_disco_items ###
sub jabber_iq_disco_items
{
my $sid = shift;
my $iq = shift;
my $from = $iq->GetFrom();
my $to = $iq->GetTo();
my $id = $iq->GetID();
my $type = $iq->GetType();
my $query = $iq->GetQuery();
my $xml		= $iq->GetXML();

    if($type eq 'get')
     {
      aspsmst_log('info',"jabber_iq_disco_items(): Processing disco query from $from");
      $iq->SetType('result');
      $iq->SetFrom($iq->GetTo());
      $iq->SetTo($from);
      $config::Connection->Send($iq);
    }
} ### END of jabber_iq_disco_items ###

### get jabberid from userkey ###
sub get_jid_from_userkey
 {
  my $userkey 	= shift;
   opendir(DIR,$spooldir) or die;
   while (defined(my $file = readdir(DIR))) 
    {
     open(FILE,"<$spooldir/$file") or die;
     my @lines = <FILE>;
     close(FILE);
     # process 
     my $line 	= $lines[0];
     my @data	= split(/:/,$line);
     my $get_userkey	= $data[1];
     aspsmst_log('notice',"get_jid_from_userkey($userkey): Return: $get_userkey");
     if ($userkey eq $get_userkey)
      {
        closedir(DIR);
	return $file;
      }
    } # END of while
    closedir(DIR);
  return "no jid for userkey $userkey";
 }

sub get_barejid
 {
  my $jid = shift;
  my ($barejid) 		= split (/\//, $jid);
  return $barejid;
 } # END of get_barejid
