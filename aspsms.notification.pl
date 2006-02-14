#!/usr/bin/perl
# aspsms-t by Marco Balmer <mb@micressor.ch> @2004
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


# Read configuration
my $Config  		= XML::Smart->new('./aspsms.xml');
my $hostname           = $Config->{aspsms}{notification}{hostname};
my $username           = $Config->{aspsms}{notification}{username};
my $password           = $Config->{aspsms}{notification}{password};
my $servicename        = $Config->{aspsms}{jabber}{serviceid};
my $facility	       = $Config->{aspsms}{facility};
my $release	       = $Config->{aspsms}{release};
my $ident	       = $Config->{aspsms}{ident};
use constant SERVICE_NAME 	=> $Config->{aspsms}{notification}{jabberid};

openlog('aspsms.notification.pl','',$facility);

print "Content-Type: text/html\n\n";
print "
<html>
 <head>
 </head>
<body>
<pre>";

my $xml 	= param("xml");
my @tmpstat	= split(/,,,/,$xml);
my $transid	= $tmpstat[1];

print "\nprint transid:$transid\n\n";

my $Con 			= new Net::Jabber::Client(debuglevel=>0,debugfile=>"stdout");

print "
$ident Gateway system v$release

Got notification from aspsms: 
";

if($xml) 
 {
  connect_client();
  $Con->PresenceSend();
  syslog('notice',"RosterGet();");
  syslog('notice',"Got <stream>$xml</stream>");
  print "<stream>$xml</stream>";
  my $msg = new Net::Jabber::Message();
  $msg->SetMessage(type    =>"message",
                   to      =>$servicename."/notification",
                   body    =>"$xml");
  $Con->Send($msg);
 }
else
 {
  syslog('info',"Got <stream/>");
  print "<stream/>";
 } 


stop();




sub connect_client {

$Con->Connect(
                hostname                => $hostname,
                port                    => "5222",
                timeout                 => "5"
              );

#$Con->SetCallBacks(
#                  "message"       => \&InMessage,
#                  "iq"            => \&InIQ,
#                  );

if ($Con->Connected()) {    }

$Con->AuthSend (
                 username=>      $username,
                 password=>      $password,
                 resource=>      $transid
               );

} # end sub connect_client()

sub stop 
 {
  $Con->Disconnect;
  print "\ndone";
  syslog('notice',"End");
  sleep(1);
  exit(0);
 }

