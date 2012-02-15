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

aspsms-t - jabber iq (information query) handler

=head1 DESCRIPTION

This module handles all transport register and service discovery requests.

=head1 METHODS

=cut

package ASPSMS::Iq;

use strict;
use ASPSMS::config;
use vars qw(@EXPORT @ISA);
use Exporter;

@ISA 			= qw(Exporter);
@EXPORT 		= qw(	InIQ 
				SendIQError 
				jabber_register 
				jabber_iq_gateway
				jabber_iq_register 
				jabber_iq_browse 
				jabber_iq_remove 
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
use ASPSMS::DiscoNetworks;
use ASPSMS::Presence;


my $admin_jid	= $ASPSMS::config::admin_jid;
my $passwords	= $ASPSMS::config::passwords;

sub InIQ {
=head2 InIQ()

Incoming Iq. Handle jabber:iq:registration with add/remove source 
dialog, return error 501 for other NS's.

=cut

 $ASPSMS::config::aspsmst_stat_stanzas++;

 my $sid 	= shift;
 my $iq 	= shift;
 my $from 	= $iq->GetFrom();
 my $to 	= $iq->GetTo();
 my $id 	= $iq->GetID();
 my $type 	= $iq->GetType();
 my $query 	= $iq->GetQuery();
 my $xml	= $iq->GetXML();
 my $barejid	= get_barejid($from);

aspsmst_log('debug',"InIQ->GetXML(): $xml");

if ($to eq "$ASPSMS::config::service_name/xmlsrv.asp") 
 {
  my $ret = jabber_iq_xmlsrv($sid,$iq,$from,$to,$id,$type,$query,$xml);
 } ### END jabber:iq:xmlsrv.asp ###

return unless $query;
my $xmlns 	= $query->GetXMLNS();

aspsmst_log('debug',"id=$id InIQ($barejid): Processing iq query type=$type xmlns=\"$xmlns\"");

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
     $query->SetName($ASPSMS::config::browseservicename);
     $query->SetVer($ASPSMS::config::release);
     $query->SetOS($^O);
     $ASPSMS::config::Connection->Send($iq);
    }
   else 
    {
     sendError($iq, $from, $to, 501, 
     		"Sorry, $ASPSMS::config::ident does not support $xmlns");
    }
   }
  else 
   {
    sendError($iq, $from, $to, 501, 
    		"Sorry, $ASPSMS::config::ident does not support $xmlns");
   }

} ### END of InPresence ###

sub SendIQError {
my $id		= shift;
my $to	  	= shift;
my $errorcode 	= shift;
my $error 	= shift;
my $iq;

=head2 SendIQError()

If something at aspsms-t does not work, we have to inform the jabber user.
This function generates an information query (iq) error and send them
to the jabber user. This function can be called from any place in the
aspsms-t code.

=cut

  aspsmst_log('info',"SendIQError(): Sending IQ to $to");
  $iq = new Net::Jabber::IQ();

  $iq->SetIQ(		type		=>"error",
                       	to		=>$to,
                       	errorcode	=>$errorcode,
                       	error		=>$error,
			from		=>$ASPSMS::config::service_name,
                      	id		=>$id);			


$ASPSMS::config::Connection->Send($iq);
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
my $banner	= $ASPSMS::config::banner;

=head2 jabber_register()

Via this function, a jabber user can register his jabber id at the aspsms-t
transport.

=over 4

=item * If request type is 'get`, we send him a registration form via jabber.

=back

=cut

  if ($type eq 'get') 
   {
    $iq->SetType('result');
    $iq->SetFrom($iq->GetTo());
    $iq->SetTo($from);
    aspsmst_log('info',"jabber_register(): Send instructions to $from");
    $query->SetInstructions("$ASPSMS::config::ident $ASPSMS::config::release transport

Please enter Username 
(https://www.aspsms.ch/userkey.asp) and 
password of your aspsms.com account.
Support contact xmpp: $ASPSMS::config::admin_jid");

=head2

=over 4

=item * Via getUserPass() we read users properties if his jabber id was 
already existing. This case is if a user would like to change his
registration or passwort.

=back

=cut

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
    $ASPSMS::config::Connection->Send($iq);
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
  my $passfile 		= "$ASPSMS::config::passwords/$barefrom";
  $phone          	=~ s/\+/00/g;

  #
  # Remove = 1 ?????
  #
  aspsmst_log('notice',"jabber_register(): remove flag: $remove for $from");
  if ($remove == 1) 
   {
    jabber_iq_remove($from,$id,$passfile);
    return;
   } # if ($remove) {

=head2

=over 4

=item * Via CheckNewUser() we call aspsms.com to check is the USERKEY and 
password at aspsms.com correct.

=back

=cut
    my ($ErrorCode,$ErrorDescription) = CheckNewUser($name,$pass);
    unless($ErrorCode == 1)
     {
      #
      # Convert aspsms.com error codes in jabber compilant (XEP-0086) codes
      #
      $ErrorCode =~ s/26/406/g;
      $ErrorCode =~ s/3/401/g;
      SendIQError($id,$from,$ErrorCode,$ErrorDescription);
      return;
     };
=head2

=over 4

=item * If already another jabber id is registered with the same aspsms USERKEY,
we reject them, because we can not handle delivery notifications for more
than one registration with the same USERKEY.
			
=back

=cut

  my $check_two_userdata 	= get_record("userkey",$name);

  unless($check_two_userdata == -2)
   {
    my $check_two_jid	= $check_two_userdata->{jid};
    unless($barefrom eq $check_two_jid)
     {
      SendIQError($id,$from,406,"You have already another jid registered with the same userkey. Please unregister first your registration from $check_two_jid");
      return 1;
     } ### unless($barefrom eq $check_two_jid)
   } ### unless($check_two_userdate == -2)

=head2

=over 4

=item * If everything is ok, we store the registration info to the spool
directory of aspsms-t. To do this we call the function set_record().

=back

=cut

  my $userdata = {};
  $userdata->{gateway} 	= $gateway; 
  $userdata->{name} 	= $name; 
  $userdata->{pass} 	= $pass; 
  $userdata->{phone} 	= $phone; 
  $userdata->{signature}= $signature; 

  my $ret_record = set_record("jabber_register",$passfile,$userdata);

  aspsmst_log('info',"jabber_register($from): Starting registration");

  $iq->SetType('result');
  $iq->SetFrom($iq->GetTo());
  $iq->SetTo($from);
  $ASPSMS::config::Connection->Send($iq);
  sendAdminMessage("info","Registration successfully: set_record(): Return: $ret_record for $from $name:$phone:$pass:$signature");

  aspsmst_log('info',"jabber_register($from): registration successfully");

=head2

=over 4

=item * And send to the jabber user a roster item via SendPresence() which is 
necessary to handle furthur sms send requests.

=back

=cut
  
  sendPresence($from,"$ASPSMS::config::service_name", 'subscribe');
  sendPresence($from,"$ASPSMS::config::service_name", undef);
 } else 
    {
     sendError($iq, $from, $to, 501, 'feature-not-implemented: jabber:iq:register');
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

=head2 jabber_iq_gateway()

It enables a client to send a legacy username to the gateway and receive a 
properly-formatted JID in return. To do so, the client sends the legacy 
address to the gateway as the character data of the <prompt/> element and the 
gateway returns a valid JID as the character data of the <jid/> element.
http://xmpp.org/extensions/xep-0100.html#addressing-iqgateway

=cut

     if ($type eq 'get') 
     {
      $iq->SetType('result');
      $iq->SetFrom($iq->GetTo());
      $iq->SetTo($from);
      $query->SetDesc('Choose your destination number like: +4179xxxxxxx');
      $query->SetPrompt('Number');
      $ASPSMS::config::Connection->Send($iq);

      aspsmst_log('info',"jabber_iq_gateway($from): Send gateway information");
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
   $query->SetPrompt("$number\@$ASPSMS::config::service_name");
   $query->SetJID("$number\@$ASPSMS::config::service_name");
   $ASPSMS::config::Connection->Send($iq);
  }
 else 
  {
   sendError($iq, $from, $to, 501, 'feature-not-implemented');
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

=head2 jabber_iq_browse()

The Jabber world is a diverse place, with lots of services, transports, 
software agents, users, groupchat rooms, translators, headline tickers, and 
just about anything that might interact on a real-time basis using 
conversational messages or presence. Every JabberID (JID) is a node that can 
be interacted with via messages, presence, and special purpose IQ namespaces. 
Some JIDs are parents (such as transports), and often many JIDs have 
relationships with other JIDs (such as a user to their resources, a server to 
its services, etc.). We need a better way to structure and manage this culture 
of multi-namespace JID stew. The answer: Jabber Browsing.
http://xmpp.org/extensions/xep-0011.html

=cut

  my $namespaces = [ 'jabber:iq:register', 'jabber:iq:gateway','jabber:iq:version' ];

  if ($type eq 'get') 
   {
    aspsmst_log('debug',"id=$id jabber_iq_browse($barejid): Processing iq browse query type=$type");
    $iq->SetType('result');
    $iq->SetFrom($iq->GetTo());
    $iq->SetTo($from);
    $query->SetJID($ASPSMS::config::service_name);
    $query->SetCategory("service");
    $query->SetType($ASPSMS::config::browseservicetype);
    $query->SetName($ASPSMS::config::browseservicename);
    $query->SetNS($namespaces);
    $ASPSMS::config::Connection->Send($iq);
    
   }
  else 
   {
    sendError($iq, $from, $to, 501, 'feature-not-implemented');
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

=head2 jabber_iq_disco_info()

The ability to discover information about entities on the Jabber network is 
extremely valuable. Such information might include features offered or 
protocols supported by the entity, the entity's type or identity, and 
additional entities that are associated with the original entity in some 
way (often thought of as "children" of the "parent" entity). While mechanisms 
for doing so are not defined in XMPP Core [1], several protocols have been 
used in the past within the Jabber community for service discovery, 
specifically Jabber Browsing [2] and Agent Information [3].
http://xmpp.org/extensions/xep-0030.html#intro

=cut

if($to eq $ASPSMS::config::service_name)
 {
   if ($type eq 'get')
    {
    aspsmst_log('debug',"id=$id jabber_iq_disco_info($barejid): Processing query type=$type");
    $iq->SetType('result');
    $iq->SetFrom($iq->GetTo());
    $iq->SetTo($from);
    
    my $iqQuery = $iq->NewQuery("http://jabber.org/protocol/disco#info");


    $iqQuery->AddIdentity(	category=>"gateway",
                        	type=>"sms",
				name=>$ASPSMS::config::browseservicename);

    $iqQuery->AddFeature(var=>"http://jabber.org/protocol/disco");
    $iqQuery->AddFeature(var=>"http://www.aspsms.com/xml/doc/xmlsvr18.pdf");
    $iqQuery->AddFeature(var=>"jabber:iq:register");
    $iqQuery->AddFeature(var=>"jabber:iq:gateway");
    $iqQuery->AddFeature(var=>"jabber:iq:version");

    $ASPSMS::config::Connection->Send($iq);


    } # END of if ($type eq 'get'
} ### END of if($to eq $ASPSMS::config::service_name)

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

=head2 jabber_iq_disco_items()

According to jabber_iq_disco_info.

=cut

    my $iqQuery = $iq->NewQuery("http://jabber.org/protocol/disco#items");

    if($type eq 'get')
     {
        aspsmst_log('debug',"id=$id jabber_iq_disco_items($barejid): Processing query type=$type");

    #
    # Offer supported networks
    #

    if($to eq $ASPSMS::config::service_name)
     {
      aspsmst_log('debug',"jabber_iq_disco_items($barejid): Display transport items");
      $iqQuery->AddItem(jid=>"countries\@$ASPSMS::config::service_name",
    			name=>"Supported sms networks");
     } ### END of if($to eq $ASPSMS::config::service_name)


    #
    # Display all availavle countries and network operators for sending
    # sms messages
    #

    $iqQuery = disco_get_aspsms_networks($iqQuery,$barejid,$to);

      	$iq->SetType('result');
      	$iq->SetFrom($iq->GetTo());
      	$iq->SetTo($from);
      	$iq->SetID($id);
      	$ASPSMS::config::Connection->Send($iq);
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
aspsmst_log('info',"id=$id jabber_iq_xmlsrv($barejid): Processing xmlsrv.asp query");

=head2 jabber_iq_xmlsrv()

Via jabber you are able to access to the xml interface from aspsms.com directly
with an iq (information query). Send an iq to aspsms.domain.tld/xmlsrv.asp
and it will directly forwarded to the aspsms.com. The result is the response
from aspsms.com xml interface via a regulary jabber iq message.

=cut

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
	   my $ret_parsed_response = parse_aspsms_response(\@ret_CompleteRequest,undef);
	   $iq_xmlsrv_result->InsertRawXML($ret_parsed_response);
           $ASPSMS::config::Connection->Send($iq_xmlsrv_result);
	   return undef;
	 } ### END of if ( $to eq $ASPSMS::config::service_name."/xmlsrv.asp")

	#
	# END of Direct access to the aspsms:com xml srv
	#
} ### END of jabber_iq_xmlsrv ###

sub jabber_iq_remove
{
 my $from	= shift;
 my $id		= shift;
 my $passfile	= shift;
 my $barejid	= get_barejid($from);

=head2 jabber_iq_remove()

If a jabber user deletes aspsms.domain.tld from his roster, jabber_iq_remove()
will be called and his registration information via delete_record() removed.

=cut

    aspsmst_log('info',"jabber_register($barejid): Execute remove registration of $passfile");

    #
    # remove file	
    #

    my $ret_unlink = delete_record("jabber_register",$passfile);
    aspsmst_log('info',"jabber_register($barejid): Execute remove completed delete_record($passfile): Return $ret_unlink");

=head2

If delete of passfile was successfully then send presence unsubscribe.

=cut

    if($ret_unlink == 0)
    {
    
    # send unsubscribe presence
    sendPresence($from,"$ASPSMS::config::service_name", 'unsubscribe');
    
    #
    # send iq result
    # 
    my $barefrom	= get_barejid($from);
    my $iq	= new Net::Jabber::IQ;
    $iq->SetIQ(	type	=>"result",
              	to	=>$barefrom,
		from	=>$ASPSMS::config::service_name,
               	id	=>$id);			

    $ASPSMS::config::Connection->Send($iq);

    my $message = new Net::Jabber::Message();
    $message->SetMessage(
			type	=>"",
			to	=>$barefrom,
			from	=>$ASPSMS::config::service_name,
			body	=>"Sucessfully unregistred" );

    $ASPSMS::config::Connection->Send($message);
    }

return $ret_unlink;
}


1;

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2012 Marco Balmer <marco@balmer.name>

The Debian packaging is licensed under the 
GPL, see `/usr/share/common-licenses/GPL-2'.

=cut
