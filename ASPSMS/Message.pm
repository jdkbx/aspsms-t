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
use config;
use vars qw(@EXPORT @ISA);
use Exporter;

@ISA 			= qw(Exporter);
@EXPORT 		= qw(sendAdminMessage WelcomeMessage SendMessage);


use Sys::Syslog;


sub sendAdminMessage
 {
   my $type      = shift;
   my $msg       = shift;

   my $jabber_msg= new Net::Jabber::Message();

   $jabber_msg->SetMessage(      type    =>"message",
   			 	 subject =>"aspsms-t Core Message",
                                 to      =>$config::admin_jid,
                                 from    =>$config::service_name,
                                 body    =>"\n$msg\n\n
---				 
$config::ident v $config::release
http://www.micressor.ch/content/projects/aspsms-t");


  $config::Connection->Send($jabber_msg);

 }

sub WelcomeMessage
 {
   my $from = shift;
   my $msg= new Net::Jabber::Message();
  	 
	 $msg->SetMessage(	type    =>"",
	 			subject =>"Wecome to $config::ident",
				to      =>$from,
				from    =>$config::service_name,
				body    => "Hello, this is $config::ident at $config::service_name. 
It is a sms-transport gateway. If you wish to operate with it, please 
register an https://www.aspsms.com account, afterwards you can use 
it to send sms like +4178xxxxxxx@$config::service_name



$config::ident Gateway system v$config::release
Support contact xmpp: $config::admin_jid
http://www.micressor.ch/content/projects/aspsms-t

");
				
$config::Connection->Send($msg);
}

sub SendMessage
 {
   my $from 	= shift;
   my $to	= shift;
   my $subject	= shift;
   my $text	= shift;

   my $msg= new Net::Jabber::Message();

   $msg->SetMessage(      	 type    =>"",
   			 	 subject =>$subject,
                                 to      =>$to,
                                 from    =>$from,
                                 body    =>"$text


---
$config::ident Gateway system v$config::release
Support contact xmpp: $config::admin_jid
http://www.micressor.ch/content/projects/aspsms-t
");

$config::Connection->Send($msg);

 }

1;
