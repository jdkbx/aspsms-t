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

aspsms-t - message handler, help messages and other functions

=head1 METHODS

=cut

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

=head2 sendAdminMessage()

If something happen which is necessary to inform the admin of the transport,
this function send all necessary information to the admin.

=cut

   # If we have no transaction id, 
   # generate one.
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

=head2 ShowBalanceMessage()

If you had requested how much credits you have at aspsms.com, this function
will generate the message with balance information and send it to the 
jabber user.

=cut

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
3. Send sms to jid's like +4178xxxxxxx\@$ASPSMS::config::service_name.";
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

=head2 HelpMessage()

If you sent '!help` to the transport, it will call this function and send you
a help message.

=cut

   my $send_msg = "
Hello, this is $ASPSMS::config::ident at $ASPSMS::config::service_name. It is a sms-transport 
gateway.

The following commands are available:

!credits   Shows your credit balance
!help      This help message

---
$ASPSMS::config::ident build $ASPSMS::config::release
https://github.com/micressor/aspsms-t";

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

=head2 SendMessage()

This is a fuction used by aspsms-t to send messages mith several content
to the jabber users.

=cut

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

=head2 get_transaction_id()

Get a random integer transaction id to idetify sms messages between aspsms.com
and jabber. 

=cut

sub get_transaction_id
 {
  my $trans_id = int( rand(10000)) + 10000;
  return $trans_id;
 } ### END of get_transaction_id


1;

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2012 Marco Balmer <marco@balmer.name>

The Debian packaging is licensed under the 
GPL, see `/usr/share/common-licenses/GPL-2'.

=cut
