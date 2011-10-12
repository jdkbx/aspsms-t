#!/usr/bin/perl 
# aspsms-t by Marco Balmer <marco.balmer@gmx.ch> @2006
# http://www.swissjabber.ch/
# https://github.com/micressor/aspsms-t
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
use lib "./lib";

use ASPSMS::config;

use File::Pid;

use Net::Jabber qw(Component);

use XML::Parser;
use XML::Smart;

use ASPSMS::Iq;
use ASPSMS::Presence;
use ASPSMS::Jid;
use ASPSMS::Message;
use ASPSMS::Connection;
use ASPSMS::aspsmstlog;
use ASPSMS::ContactCredits;
use ASPSMS::CheckNotification;
use ASPSMS::GetNetworksFees;
use ASPSMS::InMessage;
				  
### BEGIN CONFIGURATION ###

aspsmst_log("info","Starting up..."); 
my $pidfile = File::Pid->new({
    file => '/var/lock/aspsms-t.pid',
});

if ( my $num = $pidfile->running ) {
    aspsmst_log("Already running: $num\n");
    exit(1);
}

  
$pidfile->write;

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
openlog($ASPSMS::config::ident,'',"$ASPSMS::config::facility");


# Initialisation timer for message and notification statistic to syslog
# Every 300 seconds, it will generate a syslog entry with statistic infos
my $timer					= 295;
$ASPSMS::config::transport_uptime			= 0;

$ASPSMS::config::aspsmst_stat_message_counter 		= 0;
$ASPSMS::config::aspsmst_stat_error_counter 		= 0;
$ASPSMS::config::aspsmst_stat_notification_counter 	= 0;

### END BASIC CONFIGURATION ###

aspsmst_log('info',"Init(): $ASPSMS::config::service_name - Version $ASPSMS::config::release`");

umask(0177);

$SIG{KILL} 	= sub { $ASPSMS::config::aspsmst_flag_shutdown="KILL"; 	};
$SIG{TERM} 	= sub { $ASPSMS::config::aspsmst_flag_shutdown="TERM"; 	};
$SIG{INT} 	= sub { $ASPSMS::config::aspsmst_flag_shutdown="INT"; 	};
$SIG{ABRT} 	= sub { $ASPSMS::config::aspsmst_flag_shutdown="ABRT"; 	};
#$SIG{SEGV} 	= sub { $ASPSMS::config::aspsmst_flag_shutdown="SEGV"; 	};
$SIG{ALRM} 	= sub { die "Unexepted Timeout" 		};

#
# Check configuration of aspsms.notification.pl 
# and make a syslog entry if it is successfully.
#
my $ret_check_notification = check_notification();
aspsmst_log('info',"Init(): check_notification(): Return: $ret_check_notification");

SetupConnection();
Connect();

sendAdminMessage("info","Init(): \$service_name=$ASPSMS::config::service_name \$release=$ASPSMS::config::release");

#
# aspsms-t main loop until we're finished.
#
while () 
 {

  $ASPSMS::config::transport_uptime++;$timer++;

  #
  # Check every second for work (Process(1))
  #

  ReConnect() unless defined($ASPSMS::config::Connection->Process(1));
  if($timer == 300)
   {
     #
     # Calculate messages per hour
     #
     $ASPSMS::config::aspsmst_stat_msg_per_hour  = $ASPSMS::config::aspsmst_stat_message_counter / ($ASPSMS::config::transport_uptime/3600);
     $ASPSMS::config::aspsmst_stat_msg_per_hour  = sprintf("%.3f",$ASPSMS::config::aspsmst_stat_msg_per_hour);
     #
     # Calculate messages per hour
     #
     $ASPSMS::config::aspsmst_stat_stanzas_per_hour  = $ASPSMS::config::aspsmst_stat_stanzas / ($ASPSMS::config::transport_uptime/3600);
     $ASPSMS::config::aspsmst_stat_stanzas_per_hour  = sprintf("%.3f",$ASPSMS::config::aspsmst_stat_stanzas_per_hour);
     #
     # Calculate uptime in hours
     #
        $ASPSMS::config::transport_uptime_hours	 = $ASPSMS::config::transport_uptime / 3600;
        $ASPSMS::config::transport_uptime_hours	 = sprintf("%.3f",$ASPSMS::config::transport_uptime_hours);


     
     #
     # Logging status message
     #
     aspsmst_log('info',"[stat] --- statistics ---");
     aspsmst_log('info',"[stat] $ASPSMS::config::transport_uptime_hours hour(s) transport uptime");
     aspsmst_log('info',"[stat] $ASPSMS::config::aspsmst_stat_message_counter SMS Successfully");
     aspsmst_log('info',"[stat] $ASPSMS::config::aspsmst_stat_notification_counter SMS Notifications");
     aspsmst_log('info',"[stat] $ASPSMS::config::aspsmst_stat_error_counter SMS delivery errors");
     aspsmst_log('info',"[stat] $ASPSMS::config::aspsmst_stat_msg_per_hour SMS Messages/h");
     aspsmst_log('info',"[stat] $ASPSMS::config::aspsmst_stat_stanzas XMPP/Jabber stanza counter");
     aspsmst_log('info',"[stat] $ASPSMS::config::aspsmst_stat_stanzas_per_hour XMPP/Jabber stanzas/h");
     aspsmst_log('notice',"[stat] \$aspsmst_flag_shutdown=$ASPSMS::config::aspsmst_flag_shutdown");
     aspsmst_log('notice',"[stat] \$aspsmst_in_progress=$ASPSMS::config::aspsmst_in_progress");
     aspsmst_log('info',"[stat] --- statistics ---");
    $timer = 0;
   } 

 #
 # Entry point for shutdown if flag is set
 #
 unless($ASPSMS::config::aspsmst_flag_shutdown eq "0")
  {
   Stop($ASPSMS::config::aspsmst_flag_shutdown);
  }
   
 } ### END of Loop

Stop("The connection was killed...");

sub Stop {
# Terminate the SMS component's current run.
my $err = shift;
aspsmst_log('info',"Stop(): Shutting down aspsms-t \$aspsmst_in_progress=$ASPSMS::config::aspsmst_in_progress \$aspsmst_flag_shutdown=$ASPSMS::config::aspsmst_flag_shutdown");


unless($ASPSMS::config::aspsmst_in_progress==0)
 {
  aspsmst_log('info',"Stop(): Waiting for shutdown, aspsms-t is still working");
  return -1;
 }

sendAdminMessage("info","Stop(): \$aspsmst_in_progress=$ASPSMS::config::aspsmst_in_progress \$aspsmst_flag_shutdown=$ASPSMS::config::aspsmst_flag_shutdown \$err=$err");
aspsmst_log('info',"Stop(): Shutting down aspsms-t because sig: $err\n");
$ASPSMS::config::Connection->Disconnect();
$pidfile->remove;
exit(0);
}

sub SetupConnection {

$ASPSMS::config::Connection = new Net::Jabber::Component(debuglevel=>$ASPSMS::config::xmpp_debuglevel, debugfile=>"stdout");

my $status = $ASPSMS::config::Connection->Connect("hostname" => $ASPSMS::config::server, "port" => $ASPSMS::config::port, "secret" => $ASPSMS::config::secret, "componentname" => $ASPSMS::config::service_name);
$ASPSMS::config::Connection->AuthSend("secret" => $ASPSMS::config::secret);

if (!(defined($status))) {
  aspsmst_log("info","SetupConnection(): Error: Jabber server is down or connection was not allowed. $!\n");
}

$ASPSMS::config::Connection->SetCallBacks("message" => \&InMessage, "presence" => \&InPresence, "iq" => \&InIQ);

} # END of sub SetupConnection;


sub Connect {

my $status = $ASPSMS::config::Connection->Connected();
aspsmst_log('info',"Connect(): Transport connected to jabber-server $ASPSMS::config::server:$ASPSMS::config::port") if($status == 1);
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
