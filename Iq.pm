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
use ASPSMS::Storage;
use Presence;


my $admin_jid	= $config::admin_jid;
my $passwords	= $config::passwords;

sub InIQ {

 # Incoming IQ. Handle jabber:iq:registration with add/remove source 
 # dialog, return error 501 for other NS's.

 $config::aspsmst_stat_stanzas++;

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
aspsmst_log('debug',"InIQ->GetXML(): $xml");

if ($to eq "$config::service_name/xmlsrv.asp") 
 {
  my $ret = jabber_iq_xmlsrv($sid,$iq,$from,$to,$id,$type,$query,$xml);
 } ### END jabber:iq:xmlsrv.asp ###

return unless $query;
my $xmlns 	= $query->GetXMLNS();

# If error in <iq/> 
if ($type eq 'error') 
{
 aspsmst_log('debug',"InIQ->GetXML(): " . $iq->GetXML());
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
     sendError($iq, $from, $to, 501, "Not supported $xmlns");
    }
   }
  else 
   {
    sendError($iq, $from, $to, 501, "Not supported $xmlns");
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
my $banner	= $config::banner;

  if ($type eq 'get') 
   {
    $iq->SetType('result');
    $iq->SetFrom($iq->GetTo());
    $iq->SetTo($from);
    aspsmst_log('info',"jabber_register(): Send instructions to $from");
    $query->SetInstructions("jabber2sms transport

Important: This gateway will only operate with an account from http://www.aspsms.com

Support contact xmpp: $config::admin_jid

Please enter Username (=UserKey https://www.aspsms.ch/userkey.asp) and password of your aspsms.com account:");

    my $ret_user 	= getUserPass($from,$banner);
    my $user 		=  {};

    if($ret_user == -2)
     {
      #
      # If no user found, reset $user var
      #
      $user->{name}           = '' if ( ! $user->{name} );
      $user->{password}       = '' if ( ! $user->{password} );
      $user->{phone}          = 'aspsms-t' if ( ! $user->{phone} );
      $user->{signature}      = $banner if (! $user->{signature} );
     }
    else
     {
      $user = $ret_user;
     }
    
    $query->SetUsername($user->{name});
    $query->SetURL($user->{signature});
    $query->SetPhone($user->{phone});
    $query->SetPassword('');
    $config::Connection->Send($iq);
   }
  elsif ($type eq 'set') 
   {
    my $gateway 	= 'aspsms'; # TODO! ->GetName() but only one gateway with passwords so far
    my $name 		= $query->GetUsername();
    my $phone 		= $query->GetPhone();
    my $pass 		= $query->GetPassword();
    my $signature 	= $query->GetURL();
    my $remove		= $query->GetRemove();

  my ($barefrom)  	= get_barejid($from);
  my $passfile 		= "$config::passwords/$barefrom";
  $phone          	=~ s/\+/00/g;

  #
  # Remove = 1 ?????
  #
  aspsmst_log('notice',"jabber_register(): remove flag: $remove for $from");
  unless ($remove == 1) 
   {
    jabber_iq_remove($from,$id,$passfile);
    return;
   } # if ($remove) {

    # check aspsms user trough gateway of aspsms.com
    my ($ErrorCode,$ErrorDescription) = CheckNewUser($name,$pass);
    unless($ErrorCode == 1)
     {
      SendIQError($id,$from,$ErrorCode,$ErrorDescription);
      return;
     };
			


  #
  # store configuration to the spool directory
  # via set_record();
  #

  my $userdata = {};
  $userdata->{gateway} 	= $gateway; 
  $userdata->{name} 	= $name; 
  $userdata->{pass} 	= $pass; 
  $userdata->{phone} 	= $phone; 
  $userdata->{signature}= $signature; 

  my $ret_record = set_record("jabber_register",$passfile,$userdata);

  aspsmst_log('info',"jabber_register(): RegisterManager.Execute: set_record(): Return: $ret_record for $from");

  $iq->SetType('result');
  $iq->SetFrom($iq->GetTo());
  $iq->SetTo($from);
  $config::Connection->Send($iq);
  sendAdminMessage("info","RegisterManager.Complete: set_record(): Return: $ret_record for $from $name:$phone:$pass:$signature");

  my $presence = new Net::Jabber::Presence();
  
  aspsmst_log('info',"jabber_register(): RegisterManager.Complete: for $from $name:$phone:$pass:$signature");
  
  sendPresence($presence, $from,"$config::service_name/registered", 'subscribe');
 } else 
    {
     sendError($iq, $from, $to, 501, 'jabber:iq:register request not implemented');
    }
} # END of jabber_register

### jabber_iq_gateway ####
sub jabber_iq_gateway 
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
   sendError($iq, $from, $to, 501, 'Not supported');
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
    sendError($iq, $from, $to, 501, 'Not supported');
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

if($to eq $config::service_name)
 {
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
} ### END of if($to eq $config::service_name)

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

    my $iqQuery = $iq->NewQuery("http://jabber.org/protocol/disco#items");

    if($type eq 'get')
     {
      	aspsmst_log('notice',"jabber_iq_disco_items(): Processing disco query from=$barejid id=$id");


    #
    # Offer supported networks
    #

    if($to eq $config::service_name)
     {
      aspsmst_log('info',"jabber_iq_disco_items($barejid): Display transport items");
      $iqQuery->AddItem(jid=>"networks\@$config::service_name",
    			name=>"Supported sms networks");
     } ### END of if($to eq $config::service_name)


    #
    # Display all availavle countries for sending
    # sms messages
    #

    if($to eq "networks\@$config::service_name")
     {
      aspsmst_log('info',"jabber_iq_disco_items($barejid): Display network countries");
      my @countries	= $config::xml_networks->{networks}{country}('[@]','name');

      #
      # Generate disco item for each country
      #

      foreach my $i (@countries)
      {
       aspsmst_log('debug',"jabber_iq_disco_items($barejid): Country: $i");
       $i =~ tr/A-Z/a-z/;
       
       #
       # Jid fix for spaces in country names
       #
       $i =~ s/\s/\_/g;
       unless($i eq "")
        {
       $iqQuery->AddItem(	jid=>"$i\@".$config::service_name,
       				name=>$i);
        } ### END of unless($li eq "")
      } ### END of foreach my $i (@countries)

     } ### END of if($to eq "networks\@$config::service_name")

    my @select_country = split(/@/,$to);
    if($to eq $select_country[0]."@".$config::service_name)
     {
      
      #
      # Jid fix for spaces in country names
      #
      $select_country[0] =~ s/\_/\ /g;

      aspsmst_log('info',"jabber_iq_disco_items($barejid): Display network of country ".$select_country[0]);

      #
      # Change country to uppercase
      #
      $select_country[0] =~ tr/a-z/A-Z/;
      my @networks	= $config::xml_networks->{"networks"}{"country"}('name','eq',"$select_country[0]"){"network"}('[@]','name');
      my @credits	= $config::xml_networks->{"networks"}{"country"}('name','eq',"$select_country[0]"){"network"}('[@]','credits');

      #<fees>
      #<country name="AUSTRIA">
      #<network name="Mobilkom Austria" credits="2.75">
      #<prefix number="0043664"/>
      #</network>
      #</fees>

      my @prefixes;


      my $counter_networks 	=0;
      my $counter_prefixes	=0;
      foreach my $i (@networks)
      {
       #
       # Generate disco item for each country
       #
       aspsmst_log('debug',"jabber_iq_disco_items($barejid): Network $counter_networks: $i");

       unless($i eq "")
	{
         $iqQuery->AddItem(	name=>"Network: $i");
        } ### END of unless($i eq "")

       @prefixes = $config::xml_fees->{"fees"}{"country"}('name','eq',"$select_country[0]"){"network"}('name','eq',"$i"){"prefix"}('[@]','number');

       $counter_prefixes	=0;
       foreach my $i_prefix (@prefixes)
        {
         #
         # Generate disco item for prefixes
         #
	 unless($i_prefix eq "")
	  {
           aspsmst_log('debug',"jabber_iq_disco_items($barejid): Prefix $counter_prefixes: $i_prefix");
           $iqQuery->AddItem(name=>"Network: $i Prefix: $i_prefix [Credits:$credits[0]]");
	  }
	 $counter_prefixes++;
	} ### END of foreach my $i (@prefixes)
       $counter_networks++;
      } ### END of foreach my $i (@countries)

     } ### END of if($to eq "networks\@$config::service_name")

      	$iq->SetType('result');
      	$iq->SetFrom($iq->GetTo());
      	$iq->SetTo($from);
      	$iq->SetID($id);
      	$config::Connection->Send($iq);
        aspsmst_log('debug',"jabber_iq_disco_items($barejid): Processing finished");
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

sub jabber_iq_remove
{
 my $from	= shift;
 my $id		= shift;
 my $passfile	= shift;

    aspsmst_log('info',"jabber_register(): Execute remove registration of  $passfile");

    #
    # remove file	
    #

    my $ret_unlink = delete_record("jabber_register",$passfile);
    aspsmst_log('info',"jabber_register(): Execute remove completed delete_record($passfile): Return $ret_unlink");

    #
    # If delete of passfile was successfully then send presence 
    # unsubscribe
    #

    if($ret_unlink == 0)
    {
    
    #
    # send unsubscribe presence
    # 
    
    my $presence = new Net::Jabber::Presence;	
    sendPresence($presence, $from,"$config::service_name/registered", 'unsubscribe');
    
    #
    # send iq result
    # 
    my $barefrom	= get_barejid($from);
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
    }

return $ret_unlink;
}


1;
