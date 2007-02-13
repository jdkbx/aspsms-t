#!/usr/bin/perl
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

# Notify example
# aspsms.notification.pl?xml=notify,,,004179xyzx,,,$USERKEY,,,<Originator>,,,<MessageData>
#
# twoway example
# aspsms.notification.pl?xml=twoway,,,004179xyzx,,,$USERKEY,,,<Originator>,,,<MessageData>

use lib "./";

use CGI qw(:standard);
use Sys::Syslog;
use strict;
use Net::Jabber qw(Client);
use XML::Smart;

my $xml 	= param("xml");
my @tmpstat	= split(/,,,/,$xml);
my $transid	= $tmpstat[1];

# Read configuration
my $Config  		= XML::Smart->new('./aspsms.xml') or \
die "Cannot open configuration file; Exit: $?";
my $hostname           = $Config->{aspsms}{notification}{hostname};
my $username           = $Config->{aspsms}{notification}{username};
my $password           = $Config->{aspsms}{notification}{password};
my $servicename        = $Config->{aspsms}{jabber}{serviceid};
my $facility	       = $Config->{aspsms}{facility};
my $release	       = $Config->{aspsms}{release};
my $ident	       = $Config->{aspsms}{ident};

openlog('aspsms.notification.pl','',$facility);

my $Con			= new Net::Jabber::Client(debuglevel=>0,debugfile=>"stdout");


http_header();

unless($xml)
 {
  Stop("No xml-stream found");
 }
else
 {
  syslog("notice","Got <stream>__but not recorded__</stream>");
 }

my $ret_connect_status 	= 	connect_client();

unless($ret_connect_status == 0)
 { Stop("Internal aspsms-t problem"); }

my $ret_send_message    = 	send_xml_to_aspsmst();

Stop($ret_send_message);

#
#
#
# 


sub http_header
 {
print "Content-Type: text/xml\n\n";
print "<?xml version='1.0'?>\n";
print "<aspsms>
 <ident>$ident</ident>
 <release>$release</release>";
print "\n <stream>$xml</stream>";
print "\n <reply>
 <status>";

} ### END of http_header


sub connect_client {

eval {

$Con->Connect(
                hostname                => $hostname,
                port                    => "5222",
                timeout                 => "5"
              );

};

if($@)
 {
  Stop("Problem to connect jabber-server");
 }

my @ret_auth = $Con->AuthIQAuth (
                 username=>      $username,
                 password=>      $password,
                 resource=>      $transid
               );

unless($ret_auth[0] eq "ok")
 { return $ret_auth[0]; }

$Con->PresenceSend();
$Con->RosterGet();

return 0;
} # end sub connect_client()

sub send_xml_to_aspsmst
 {
  my $msg = new Net::Jabber::Message();
  eval 
   {
  $msg->SetMessage(type    =>"message",
                   to      =>$servicename."/notification",
                   body    =>"$xml");
  $Con->Send($msg);
   };

  if($@)
   {
    Stop("Problem to send the notification jabber message");
   }
Stop("Successfully accepted");
} ### END of send_xml_to_aspsmst

sub Stop 
 {
  my $ret = shift;
  $Con->Disconnect;
  print "$ret</status>
 </reply>
</aspsms>";
  syslog('notice',"End");
  sleep(1);
  print "\n";
  exit(0);
 }

