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

package Presence;

use strict;
use config;
use vars qw(@EXPORT @ISA);
use Exporter;

@ISA 			= qw(Exporter);
@EXPORT 		= qw(sendError sendPresence InPresence sendGWNumPresences);


use Sys::Syslog;
use ASPSMS::aspsmstlog;
use ASPSMS::Jid;
use ASPSMS::Message;


sub sendError {
my ($msg, $to, $from, $code, $text) = @_;
	
$msg->SetType('error');
$msg->SetFrom($from);
$msg->SetTo($to);
$msg->SetErrorCode($code);
$msg->SetError($text);
$config::Connection->Send($msg);

aspsmst_log('info',"sendError($to): $code,$text");
#sendAdminMessage("info","sendError(): Message to \"$to $code,$text\"");	

}


sub InPresence {
# Incoming presence. Reply to subscription requests with proper subscription 
# actions, reply to probe presence with gateways presence.
# On registration requests, accept and send a gateways status presence update.

$config::aspsmst_stat_stanzas++;

my $sid 		= shift;
my $presence 		= shift;
my $from 		= $presence->GetFrom();
my $to 			= $presence->GetTo();
my ($number) 		= split(/@/, $to);
my $type 		= $presence->GetType();
my $status 		= $presence->GetStatus();
my $barejid 		= get_barejid($from);

aspsmst_log('notice',"InPresence($barejid): Got `$type' type presence from $number");

if ($type eq 'subscribe') 
 {
  if ( ($number !~ /^\+[0-9]{3,50}$/) && ($to ne "$config::service_name/registered") ) 
   {
    aspsmst_log('info',"InPresence(): Error: Invalid number `$number' got.");

    sendPresence($presence, $from, $to, 'unsubscribed');
    return;
   }
  
  sendPresence($presence, $from, $to, 'subscribed', );
  if ($to eq "$config::service_name/registered") 
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
  
  
  if ($to eq "$config::service_name/registered") 
   {
     sendPresence(undef,$from,$to,undef,undef,undef,5);
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


sub sendGWNumPresences 
{
 my ($number, $to) = @_;	
 my $prefix = substr($number, 1, 5);
 my $presence = new Net::Jabber::Presence();

 sendPresence(undef,$to,"$number\@$config::service_name",undef,undef,undef,5);
 aspsmst_log('notice',"sendGWNumPresences($to): Sending presence for $number");
 $config::Connection->Send($presence);

} ### END of sendGWNumPresences ###


sub sendPresence {
my ($pres, $to, $from, $type, $show, $status, $prio) = @_;

$pres = new Net::Jabber::Presence();

$pres->SetType($type);
$pres->SetShow($show);
$pres->SetStatus($status);
$pres->SetTo($to);
$pres->SetFrom($from);

my $to_barejid = get_barejid($to);
aspsmst_log('notice',"sendPresence($to_barejid): Sending presence type `$type' and status `$status'");

$config::Connection->Send($pres);

}
1;
