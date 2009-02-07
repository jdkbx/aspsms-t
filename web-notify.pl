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
# web-notify.pl?xml=notify,,,004179xyzx,,,$USERKEY,,,<Originator>,,,<MessageData>
#
# twoway example
# web-notify.pl?xml=twoway,,,004179xyzx,,,$USERKEY,,,<Originator>,,,<MessageData>

use lib "./";

use CGI qw(:standard);
use Sys::Syslog;
use strict;
use Net::Jabber qw(Client);
use XML::Smart;

# Variables --------------------------------------------------------------------

#
# Please set the path to the configuration file.
# Important: Absolut path!
# Example: /home/jabber/aspsms-t/etc/aspsms-web-notify.xml
#
my $config_file = "/home/jabber/aspsms-t/etc/aspsms-web-notify.xml";

my (	$hostname,
	$port,
	$username,
	$password,
	$servicename,
	$facility,
	$ident);

# Main ------------------------------------------------------------------------

my $xml 	= param("xml");
my @tmpstat	= split(/,,,/,$xml);
my $transid	= $tmpstat[1];

# Read configuration
my $Config = XML::Smart->new($config_file) or 
	Stop("Cannot open configuration file; Exit: $?");

openlog($ident,'',$facility);

my $Con			
= new Net::Jabber::Client(debuglevel=>0,debugfile=>"stdout");

read_configuration();

unless($xml)
 {
  Stop("No xml-stream found");
 }
else
 {
  syslog("notice","Got a response <stream> (but not recorded)");
 }

my $ret_connect_status 	= 	connect_client();

unless($ret_connect_status == 0)
 { Stop("Internal aspsms-t problem"); }

my $ret_send_message = send_xml_to_aspsmst($xml);

Stop($ret_send_message);

# Functions --------------------------------------------------------------------

sub read_configuration
 {
  $hostname	= $Config->{aspsms}{notification}{hostname};
  $port		= $Config->{aspsms}{notification}{port};
  $username	= $Config->{aspsms}{notification}{username};
  $password	= $Config->{aspsms}{notification}{password};
  $servicename	= $Config->{aspsms}{jabber}{serviceid};
  $facility	= $Config->{aspsms}{facility};
  $ident	= $Config->{aspsms}{ident};
 } ### END of read_configuration();

sub http_response
 {
  my $ident 	= shift;
  my $xml	= shift;
  my $status	= shift;

  print "Content-Type: text/xml

<?xml version=\'1.0\'?>
<aspsms>
 <ident>$ident</ident>
 <stream>$xml</stream>
 <reply>
  <status>$status</status>
 </reply>
</aspsms>";

} ### END of http_response();

sub connect_client {

eval {

$Con->Connect(
                hostname                => $hostname,
                port                    => $port,
                timeout                 => "5"
              );

};

if($@)
 { Stop("Problem to connect jabber-server"); }

unless($transid)
 { Stop("Problem with given stream (Values missing?)"); }

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
  my $xml_send = shift;
  my $msg = new Net::Jabber::Message();
  eval 
   {
  $msg->SetMessage(type    =>"message",
                   to      =>$servicename."/notification",
                   body    =>"$xml_send");
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
  eval
  {
   $Con->Disconnect;
  };

  if($@)
   { }

  http_response($ident,
		$xml,
		$ret);

  syslog('notice',"$ret");

  print "\n";

  exit(0);
 } ### Stop()
