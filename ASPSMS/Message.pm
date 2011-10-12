# aspsms-t by Marco Balmer <mb@micressor.ch> @2005
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

package ASPSMS::Message;

use strict;
use ASPSMS::config;
use vars qw(@EXPORT @ISA);
use Exporter;

@ISA 			= qw(Exporter);
@EXPORT 		= qw(	sendAdminMessage 
				HelpMessage
				ShowBalanceMessage
				SendMessage
				get_transaction_id);


use Sys::Syslog;
use ASPSMS::aspsmstlog;


sub sendAdminMessage
 {
   my $type	= shift;
   my $msg	= shift;
   my $msg_id	= shift;

   #
   # If we have no transaction id, 
   # generate one.
   # 
   unless($msg_id)
    {
     $msg_id = get_transaction_id();
    }

   aspsmst_log("debug","id: $msg_id SendAdminMessage(): to ".
   "$ASPSMS::config::admin_jid \$msg_id=$msg_id");

   SendMessage( $ASPSMS::config::service_name,
             	$ASPSMS::config::admin_jid,
             	$msg_id,
             	$msg_id,
             	"message",
             	"$ASPSMS::config::ident Core Message",
	     	"\n$type: $msg\n\n
---				 
$ASPSMS::config::ident Gateway system v$ASPSMS::config::release
http://github.com/micressor/aspsms-t");


 } ### END of sendAdminMessage()

sub ShowBalanceMessage
 {
   my $from 	= shift;
   my $to 	= shift;
   my $Credits	= shift;
   my $msg_id	= shift;
   my $send_msg;

   unless($Credits == -2)
   {
    $send_msg .= "
You are a registered $ASPSMS::config::ident user and your credit balance is: $Credits";
   } ### unless($Credits == -2)
  else
   {
    $send_msg .= "
You are not a registered user of $ASPSMS::config::service_name !

If you wish to use $ASPSMS::config::service_name, 
1. please register an https://www.aspsms.com account
2. Afterwards register to $ASPSMS::config::service_name with the account information 
   of aspsms.com.
3. Send sms to jid's like +4178xxxxxxx@$ASPSMS::config::service_name.";
   } ### unless($Credits == -2)

SendMessage( $to,
             $from,
             $msg_id,
             $msg_id,
             "chat",
             "$ASPSMS::config::ident information",
             $send_msg);
  	 
   aspsmst_log("info","id: $msg_id ShowBalanceMessage(): to $from ".
   "balance=$Credits");

} ### END of WelcomeMessage()

sub HelpMessage
 {
   my $from 	= shift;
   my $to 	= shift;
   my $msg_id	= shift;

   my $send_msg = "
Hello, this is $ASPSMS::config::ident at $ASPSMS::config::service_name. It is a sms-transport 
gateway.

The following commands are available:

!credits   Shows your credit balance
!help      This help message

---
$ASPSMS::config::ident build $ASPSMS::config::release
http://www.micressor.ch/content/projects/aspsms-t";

SendMessage( $to,
             $from,
             $msg_id,
             $msg_id,
             "chat",
             "$ASPSMS::config::ident information",
             $send_msg);

   aspsmst_log("info","id: $msg_id HelpMessage(): to $from");
  	 
} ### END of HelpMessage()

sub SendMessage
 {
   my $from 	= shift;
   my $to	= shift;
   my $transid	= shift;
   my $msg_id	= shift;
   my $msg_type	= shift;
   my $subject	= shift;
   my $text	= shift;

aspsmst_log("debug","id: $transid SendMessage(): to $to \$msg_id=$msg_id");

   my $msg= new Net::Jabber::Message();

   $msg->SetMessage(      	 type		=>$msg_type,
   				 subject 	=>$subject,
                                 to      	=>$to,
				 id	 	=>$msg_id,
                                 from    	=>$from,
                                 body    	=>
				 "$text\n\n$ASPSMS::config::jabber_banner");

$ASPSMS::config::Connection->Send($msg);

 }

sub get_transaction_id
 {
  my $trans_id = int( rand(10000)) + 10000;
  return $trans_id;
 } ### END of get_transaction_id


1;
