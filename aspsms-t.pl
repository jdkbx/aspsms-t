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

use strict;
use lib "./";

use config;

use Net::Jabber qw(Component);

use XML::Parser;
use XML::Smart;

use Iq;
use Presence;
use ASPSMS::Jid;
use ASPSMS::Message;
use ASPSMS::Connection;
use ASPSMS::aspsmstlog;
use ASPSMS::ContactCredits;
use ASPSMS::CheckNotification;
use ASPSMS::GetNetworksFees;
use InMessage;
				  
### BEGIN CONFIGURATION ###

  aspsmst_log("info","Starting up..."); 
  if(-e "/var/lock/aspsms-t")
  {
    aspsmst_log("Info","Lock file /var/lock/aspsms-t already exists, $config::ident seems to be running...");
    exit(1);
  }
  #
  # set lock file;
  open (LOCKFILE, ">>/var/lock/aspsms-t");
  flock LOCKFILE,2;
  update_networks_fees();
  my $ret_config = set_config($ARGV[1]);
  unless($ret_config == 0 and $ARGV[0] eq "-c")
   { 
    aspsmst_log("debug","Error: read config file $ARGV[1]");
    aspsmst_log("debug","Exit: $ret_config");
    aspsmst_log("debug","Usage: ./aspsms-t.pl -c aspsms.xml");
    print "\n";
    exit($ret_config);
   } ### END of unless($ret_config == 0)


use Sys::Syslog;
openlog($config::ident,'',"$config::facility");


# Initialisation timer for message and notification statistic to syslog
# Every 300 seconds, it will generate a syslog entry with statistic infos
my $timer					= 295;
$config::transport_uptime			= 0;

$config::aspsmst_stat_message_counter 		= 0;
$config::aspsmst_stat_error_counter 		= 0;
$config::aspsmst_stat_notification_counter 	= 0;

### END BASIC CONFIGURATION ###

aspsmst_log('info',"Init(): $config::service_name - Version $config::release`");

umask(0177);

$SIG{KILL} 	= sub { $config::aspsmst_flag_shutdown="KILL"; 	};
$SIG{TERM} 	= sub { $config::aspsmst_flag_shutdown="TERM"; 	};
$SIG{INT} 	= sub { $config::aspsmst_flag_shutdown="INT"; 	};
$SIG{ABRT} 	= sub { $config::aspsmst_flag_shutdown="ABRT"; 	};
#$SIG{SEGV} 	= sub { $config::aspsmst_flag_shutdown="SEGV"; 	};
$SIG{ALRM} 	= sub { die "Unexepted Timeout" 		};

#
# Check configuration of aspsms.notification.pl 
# and make a syslog entry if it is successfully.
#
my $ret_check_notification = check_notification();
aspsmst_log('info',"Init(): check_notification(): Return: $ret_check_notification");

SetupConnection();
Connect();

sendAdminMessage("info","Init(): \$service_name=$config::service_name \$release=$config::release");

#
# aspsms-t main loop until we're finished.
#
while () 
 {

  $config::transport_uptime++;$timer++;

  #
  # Check every second for work (Process(1))
  #

  ReConnect() unless defined($config::Connection->Process(1));
  if($timer == 300)
   {
     #
     # Calculate messages per hour
     #
     $config::aspsmst_stat_msg_per_hour  = $config::aspsmst_stat_message_counter / ($config::transport_uptime/3600);
     $config::aspsmst_stat_msg_per_hour  = sprintf("%.3f",$config::aspsmst_stat_msg_per_hour);
     #
     # Calculate messages per hour
     #
     $config::aspsmst_stat_stanzas_per_hour  = $config::aspsmst_stat_stanzas / ($config::transport_uptime/3600);
     $config::aspsmst_stat_stanzas_per_hour  = sprintf("%.3f",$config::aspsmst_stat_stanzas_per_hour);
     #
     # Calculate uptime in hours
     #
        $config::transport_uptime_hours	 = $config::transport_uptime / 3600;
        $config::transport_uptime_hours	 = sprintf("%.3f",$config::transport_uptime_hours);


     
     #
     # Logging status message
     #
     aspsmst_log('info',"[stat] --- statistics ---");
     aspsmst_log('info',"[stat] $config::transport_uptime_hours hour(s) transport uptime");
     aspsmst_log('info',"[stat] $config::aspsmst_stat_message_counter SMS Successfully");
     aspsmst_log('info',"[stat] $config::aspsmst_stat_notification_counter SMS Notifications");
     aspsmst_log('info',"[stat] $config::aspsmst_stat_error_counter SMS delivery errors");
     aspsmst_log('info',"[stat] $config::aspsmst_stat_msg_per_hour SMS Messages/h");
     aspsmst_log('info',"[stat] $config::aspsmst_stat_stanzas XMPP/Jabber stanza counter");
     aspsmst_log('info',"[stat] $config::aspsmst_stat_stanzas_per_hour XMPP/Jabber stanzas/h");
     aspsmst_log('notice',"[stat] \$aspsmst_flag_shutdown=$config::aspsmst_flag_shutdown");
     aspsmst_log('notice',"[stat] \$aspsmst_in_progress=$config::aspsmst_in_progress");
     aspsmst_log('info',"[stat] --- statistics ---");
    $timer = 0;
   } 

 #
 # Entry point for shutdown if flag is set
 #
 unless($config::aspsmst_flag_shutdown eq "0")
  {
   Stop($config::aspsmst_flag_shutdown);
  }
   
 } ### END of Loop

Stop("The connection was killed...");

sub Stop {
# Terminate the SMS component's current run.
my $err = shift;
aspsmst_log('info',"Stop(): Shutting down aspsms-t \$aspsmst_in_progress=$config::aspsmst_in_progress \$aspsmst_flag_shutdown=$config::aspsmst_flag_shutdown");


unless($config::aspsmst_in_progress==0)
 {
  aspsmst_log('info',"Stop(): Waiting for shutdown, aspsms-t is still working");
  return -1;
 }

sendAdminMessage("info","Stop(): \$aspsmst_in_progress=$config::aspsmst_in_progress \$aspsmst_flag_shutdown=$config::aspsmst_flag_shutdown \$err=$err");
aspsmst_log('info',"Stop(): Shutting down aspsms-t because sig: $err\n");
$config::Connection->Disconnect();
flock LOCKFILE,8;
close(LOCKFILE);
system("rm /var/lock/aspsms-t");
exit(0);
}

sub SetupConnection {

$config::Connection = new Net::Jabber::Component(debuglevel=>$config::xmpp_debuglevel, debugfile=>"stdout");

my $status = $config::Connection->Connect("hostname" => $config::server, "port" => $config::port, "secret" => $config::secret, "componentname" => $config::service_name);
$config::Connection->AuthSend("secret" => $config::secret);

if (!(defined($status))) {
  aspsmst_log("info","SetupConnection(): Error: Jabber server is down or connection was not allowed. $!\n");
}

$config::Connection->SetCallBacks("message" => \&InMessage, "presence" => \&InPresence, "iq" => \&InIQ);

} # END of sub SetupConnection;


sub Connect {

my $status = $config::Connection->Connected();
aspsmst_log('info',"Connect(): Transport connected to jabber-server $config::server:$config::port") if($status == 1);
aspsmst_log('info',"Connect(): aspsms-t running and ready for queries") if ($status == 1) ;


if ($status == 0)
	{

		aspsmst_log('info',"Connect(): Transport not connected, waiting 5 seconds...");
		sleep(5);
		Connect();
	}

} # END of sub Connect

sub ReConnect {

aspsmst_log('info',"ReConnect(): Connection to jabber lost, waiting 2 seconds...");
sleep(2);
aspsmst_log('info',"ReConnect(): Reconnecting...");
SetupConnection();
Connect();

}
