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

package Iq;

use strict;
use config;
use vars qw(@EXPORT @ISA);
use Exporter;

@ISA 			= qw(Exporter);
@EXPORT 		= qw(	InIQ 
				SendIQError 
				jabber_register 
				jabber_iq_gateway
				jabber_iq_register 
				jabber_iq_browse 
				jabber_iq_disco_info 
				jabber_iq_disco_items 
				jabber_iq_xmlsrv
			   );


use Sys::Syslog;
use ASPSMS::aspsmstlog;
use ASPSMS::Jid;
use ASPSMS::xmlmodel;
use ASPSMS::Connection;
use ASPSMS::userhandler;
use ASPSMS::Message;
use Presence;


my $banner	= $config::banner;
my $admin_jid	= $config::admin_jid;
my $passwords	= $config::passwords;

sub InIQ {

 # Incoming IQ. Handle jabber:iq:registration with add/remove source 
 # dialog, return error 501 for other NS's.

 $config::stat_stanzas++;

 my $sid 	= shift;
 my $iq 	= shift;
 my $from 	= $iq->GetFrom();
 my $to 	= $iq->GetTo();
 my $id 	= $iq->GetID();
 my $type 	= $iq->GetType();
 my $query 	= $iq->GetQuery();
 my $xml	= $iq->GetXML();
 my $barejid	= get_barejid($from);

aspsmst_log('notice',"InIQ(): Processing iq query from from=$barejid id=$id");
aspsmst_log('debug',"XMPP():\n $xml");

if ($to eq "$config::service_name/xmlsrv.asp") 
 {
  my $ret = jabber_iq_xmlsrv($sid,$iq,$from,$to,$id,$type,$query,$xml);
 } ### END jabber:iq:xmlsrv.asp ###

return unless $query;
my $xmlns 	= $query->GetXMLNS();

# If error in <iq/> 
if ($type eq 'error') 
{
 aspsmst_log('info',"InIQ(): Error: " . $iq->GetXML());
 sendAdminMessage("info","InIQ(): Error: \n\n".$iq->GetXML);
 return;
}

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
     $query->SetVer($config::release);
     $query->SetOS($^O);
     $config::Connection->Send($iq);
    }
   else 
    {
     sendError($iq, $from, $to, 501, 'Not implemented in aspsms-t');
    }
   }
  else 
   {
    sendError($iq, $from, $to, 501, 'Not implemented in aspsms-t');
   }

} ### END of InPresence ###

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
			from		=>$config::service_name,
                      	id		=>$id);			


$config::Connection->Send($iq);
}

sub jabber_register

{
my $sid 	= shift;
my $iq 		= shift;
my $from 	= $iq->GetFrom();
my $to 		= $iq->GetTo();
my $id 		= $iq->GetID();
my $type 	= $iq->GetType();
my $query 	= $iq->GetQuery();
my $xml		= $iq->GetXML();

  if ($type eq 'get') 
   {
    $iq->SetType('result');
    $iq->SetFrom($iq->GetTo());
    $iq->SetTo($from);
    aspsmst_log('info',"jabber_register(): Send instructions to $from");
    $query->SetInstructions("jabber to sms transport

Important: This gateway will only operate with an account from http://www.aspsms.com

Support contact xmpp: $config::admin_jid

Please enter Username (=UserKey https://www.aspsms.ch/userkey.asp) and password of your aspsms.com account:");

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
  my $passfile = "$config::passwords/$barefrom";

  # Remove = 1 ?????
  aspsmst_log('notice',"jabber_register(): remove flag: $remove for $from");
  unless ($remove == 1) 
   {
    aspsmst_log('info',"jabber_register(): Execute remove registration: for $from");
    # remove file	
    unlink($passfile);
	
    # send unsubscribe presence
    my $presence = new Net::Jabber::Presence;	
    sendPresence($presence, $from,"$config::service_name/registered", 'unsubscribe');
    # send iq result
    my $iq	= new Net::Jabber::IQ;
    $iq->SetIQ(	type	=>"result",
              	to	=>$barefrom,
		from	=>$config::service_name,
               	id	=>$id);			

    $config::Connection->Send($iq);

    my $message = new Net::Jabber::Message();
    $message->SetMessage(
			type	=>"",
			to	=>$barefrom,
			from	=>$config::service_name,
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
  
  sendAdminMessage("info","RegisterManager.Complete: for \n\n$from $name:$phone:$pass:$signature");

  my $presence = new Net::Jabber::Presence();
  
  aspsmst_log('info',"jabber_register(): RegisterManager.Complete: for $from $name:$phone:$pass:$signature");
  
  close(F);
  sendPresence($presence, $from,"$config::service_name/registered", 'subscribe');
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
   $query->SetPrompt("$number\@$config::service_name");
   $query->SetJID("$number\@$config::service_name");
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
my $barejid	= get_barejid($from);

  my $namespaces = [ 'jabber:iq:register', 'jabber:iq:gateway','jabber:iq:version' ];

  if ($type eq 'get') 
   {
    aspsmst_log('notice',"jabber_iq_browse(): Processing browse query from=$barejid id=$id");
    $iq->SetType('result');
    $iq->SetFrom($iq->GetTo());
    $iq->SetTo($from);
    $query->SetJID($config::service_name);
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
my $barejid	= get_barejid($from);

#eval {

   if ($type eq 'get')
    {
    aspsmst_log('notice',"jabber_iq_disco_info(): Processing disco query from=$barejid id=$id");
    $iq->SetType('result');
    $iq->SetFrom($iq->GetTo());
    $iq->SetTo($from);
    
    my $iqQuery = $iq->NewQuery("http://jabber.org/protocol/disco#info");


    $iqQuery->AddIdentity(	category=>"gateway",
                        	type=>"sms",
				name=>$config::browseservicename);

    $iqQuery->AddFeature(var=>"http://jabber.org/protocol/disco");
    $iqQuery->AddFeature(var=>"http://www.aspsms.com/xml/doc/xmlsvr18.pdf");
    $iqQuery->AddFeature(var=>"jabber:iq:register");
    $iqQuery->AddFeature(var=>"jabber:iq:gateway");
    $iqQuery->AddFeature(var=>"jabber:iq:version");

    $config::Connection->Send($iq);

    } # END of if ($type eq 'get'


} ### END of jabber_iq_disco_info ###

### jabber_iq_disco_items ###
sub jabber_iq_disco_items
{
my $sid 	= shift;
my $iq 		= shift;
my $from 	= $iq->GetFrom();
my $to 		= $iq->GetTo();
my $id 		= $iq->GetID();
my $type 	= $iq->GetType();
my $query 	= $iq->GetQuery();
my $xml		= $iq->GetXML();
my $barejid	= get_barejid($from);

    if($type eq 'DEV_get')
     {
      	aspsmst_log('notice',"jabber_iq_disco_items(): Processing disco query from=$barejid id=$id");

      
    	$iq->NewChild("http://jabber.org/protocol/disco#items");
      	$iq->SetType('result');
      	$iq->SetFrom($iq->GetTo());
      	$iq->SetTo($from);
      	$iq->SetID($id);
    	$iq->SetDiscoItems("TEST");
	
      	$config::Connection->Send($iq);
    }
} ### END of jabber_iq_disco_items ###

sub jabber_iq_xmlsrv
{
my $sid 	= shift;
my $iq 		= shift;
my $from 	= $iq->GetFrom();
my $to 		= $iq->GetTo();
my $id 		= $iq->GetID();
my $type 	= $iq->GetType();
my $xml		= $iq->GetXML();
my $barejid	= get_barejid($from);
aspsmst_log('info',"jabber_iq_xmlsrv(): Processing xmlsrv.asp query from=$barejid id=$id");

	#
	# Direct access to the aspsms:com xml srv
	#

	if ($type eq 'set')
	 {
	   aspsmst_log('debug',"XMPP:\n $xml");
	   
	   # processing request to aspsms and wait for result
	   my $xmlsrv_completerequest  = xmlGenerateRequest($xml);
	   my $xmlsrv_completerequest_1 = $xmlsrv_completerequest . "\r\n\r\r\n";
	   my @ret_CompleteRequest 	  	= exec_ConnectionASPSMS($xmlsrv_completerequest_1);

    	   my $iq_xmlsrv_result = new Net::Jabber::IQ();
	   
    	   $iq_xmlsrv_result->SetType('result');
           $iq_xmlsrv_result->SetFrom($iq->GetTo());
           $iq_xmlsrv_result->SetID($id);
           $iq_xmlsrv_result->SetTo($from);
	   $iq_xmlsrv_result->InsertRawXML($ret_CompleteRequest[10]);
           $config::Connection->Send($iq_xmlsrv_result);
	   return undef;
	 } ### END of if ( $to eq $config::service_name."/xmlsrv.asp")

	#
	# END of Direct access to the aspsms:com xml srv
	#
} ### END of jabber_iq_xmlsrv ###

1;
