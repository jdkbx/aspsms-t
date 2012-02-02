# aspsms-t
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

package Presence;

use strict;
use ASPSMS::config;
use vars qw(@EXPORT @ISA);
use Exporter;

@ISA 			= qw(Exporter);
@EXPORT 		= qw(sendError sendPresence InPresence sendGWNumPresences);


use Sys::Syslog;
use ASPSMS::aspsmstlog;
use ASPSMS::Jid;
use ASPSMS::Message;
use ASPSMS::Storage;


sub sendError {
my ($msg, $to, $from, $code, $text) = @_;

#$text .= "
#
#Do you need support with $ASPSMS::config::ident ?
#Support contact is xmpp: $ASPSMS::config::admin_jid";
	
$msg->SetType('error');
$msg->SetFrom($from);
$msg->SetTo($to);
$msg->SetErrorCode($code);
$msg->SetError($text);
$ASPSMS::config::Connection->Send($msg);

aspsmst_log('warning',"sendError($to): $code,$text");
#sendAdminMessage("info","sendError(): Message to \"$to $code,$text\"");	

}


sub InPresence {
# Incoming presence. Reply to subscription requests with proper subscription 
# actions, reply to probe presence with gateways presence.
# On registration requests, accept and send a gateways status presence update.

$ASPSMS::config::aspsmst_stat_stanzas++;

my $sid 		= shift;
my $presence 		= shift;
my $from 		= $presence->GetFrom();
my $to 			= $presence->GetTo();
my ($number) 		= split(/@/, $to);
my $type 		= $presence->GetType();
my $iq_show 		= $presence->GetShow();
my $status 		= $presence->GetStatus();
my $barejid 		= get_barejid($from);

aspsmst_log('debug',"InPresence($barejid): Got `$type' type presence from $number");

my $user = get_record("jid",$barejid);

  #
  # If we get no record we will send
  # a unsubscribed
  #
  if ($user == -2)
   {
    aspsmst_log("warning","InPresence($barejid): Has no $ASPSMS::config::ident account registered -- Send type `unsubscribed'");

    #
    # send only if a @ is in the 
    unless ($barejid =~ /\@/)
     { #sendPresence($from, $to, 'unsubscribed'); 
     }
    return 0;
   }

if ($type eq 'subscribe') 
 {
  if ( ($number !~ /^\+[0-9]{3,50}$/) && ($to ne "$ASPSMS::config::service_name/registered") ) 
   {
    aspsmst_log('err',"InPresence(): Error: Invalid number `$number' got.");

    sendPresence($from, $to, 'unsubscribed');
    return;
   }
  
  aspsmst_log('info',"InPresence($barejid): Got type `$type' for number $number -- Send subscribed");
  sendPresence($from, $to, 'subscribed');

  if ($to eq "$ASPSMS::config::service_name/registered") 
   {
    sendPresence($from, $to, 'available');
   } 
  else 
   {
    sendGWNumPresences($number, $from);
   }
 } 
elsif (($type eq '') or ($type eq 'probe')) 
 {

  if ( $number =~ /^\+[0-9]{3,50}$/ ) 
   {
    sendGWNumPresences($number, $from);
   }
  
  if ($to eq "$ASPSMS::config::service_name/registered") 
   {
     aspsmst_log('notice',"InPresence($barejid): Send presence status: \"Transport uptime: $ASPSMS::config::transport_uptime_hours in hour(s) SMS/Hour: $ASPSMS::config::aspsmst_stat_msg_per_hour\"");
     sendPresence($from,$to,undef,$iq_show,"Transport uptime: $ASPSMS::config::transport_uptime_hours SMS/h: $ASPSMS::config::aspsmst_stat_msg_per_hour $ASPSMS::config::release");
   }
 } 
elsif ($type eq 'unsubscribe') 
 {
  aspsmst_log('info',"InPresence($barejid): Got type `$type' for jid $number -- Send unsubscribed");
  sendPresence($from, $to, 'unsubscribed');
 }
elsif ($type eq 'unavailable')
 {
  aspsmst_log('debug',"InPresence($barejid): Got type `$type' for jid $number -- Send unavailable");
  sendPresence($from, $to, 'unavailable');
 }


} ### END of InPresence ###


sub sendGWNumPresences 
{
 my ($number, $to) = @_;	
 my $prefix = substr($number, 0, 5);
 my $presence = new Net::Jabber::Presence();

 #
 # How much costs this number prefix.
 #
 
 my ($credits);
 
 for (my $i=3;$i<=14;$i++)
  {
   #
   # Check prefix between 3 and 14 numbers 
   #
   $prefix 	= substr($number, 0, $i);
   $prefix =~ s/\+/00/g;
   $credits 	= $ASPSMS::config::prefix_data->{"$prefix"};
   aspsmst_log('debug',"sendGWNumPresences($to): Try $prefix credits=$credits");
   unless($credits eq "")
    { 
     #
     # Prefix found, exit for
     #
     aspsmst_log('debug',"sendGWNumPresences($to): Prefix $prefix found credits=$credits exit for");
     last; 
    } ### END of unles($credits
  } ### END of for (my$
  
 if($credits eq "")
  { 
   $credits = "1"; 
   aspsmst_log('debug',"sendGWNumPresences($to): No matching prefix found, set credits=$credits");
  }
  
 sendPresence($to,"$number\@$ASPSMS::config::service_name",undef,undef,"Credits: $credits",5);

 aspsmst_log('debug',"sendGWNumPresences($to): Sending presence for $number prefix=$prefix credits=$credits");

} ### END of sendGWNumPresences ###


sub sendPresence {
my ($to, $from, $type, $show, $status) = @_;

my $pres = new Net::Jabber::Presence();

$pres->SetType($type);
unless($show eq "")
 {
  $pres->SetShow($show);
 }

unless($status eq "")
 {
  $pres->SetStatus($status);
 }

$pres->SetTo($to);
$pres->SetFrom($from);

my $to_barejid = get_barejid($to);
aspsmst_log('debug',"sendPresence($to_barejid): Sending presence type `$type', show `$show' and status `$status'");

$ASPSMS::config::Connection->Send($pres);

}

1;
