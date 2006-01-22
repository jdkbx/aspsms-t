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

use config;
use vars qw(@EXPORT @ISA);
use Exporter;

@ISA 			= qw(Exporter);
@EXPORT 		= qw(sendAdminMessage);


use Sys::Syslog;


sub sendAdminMessage
 {
   my $type      = shift;
   my $msg       = shift;

   my $jabber_msg= new Net::Jabber::Message();

   $jabber_msg->SetMessage(      type    =>"message",
   			 	 subject =>"aspsms-t Core Message",
                                 to      =>$config::admin_jid,
                                 from    =>SERVICE_NAME,
                                 body    =>"CORE Message:\n$msg
				 
$config::ident Starting up v".RELEASE);

  $config::Connection->Send($jabber_msg);

   print "\n($type) $msg";
   syslog($type,$msg);
 }

1;

