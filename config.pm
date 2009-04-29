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

package config;

use strict;
use vars qw(@EXPORT @ISA);
use Exporter;

use XML::Smart;
use ASPSMS::aspsmstlog;
use ASPSMS::ContactCredits;

our $release = " 1.2.5-trunk";

our $config_file;
our $aspsmssocket;

our %aspsms_connection 	= {};
our %prefix_data	= {};

our $service_name;
our $server;
our $port;
our $secret;

our $banner;
our $jabber_banner;
our $admin_jid;
our $facility;
our $ident;
our $passwords;
our $notificationurl;
our $notificationjid;
our $browseservicename;
our $browseservicetype;
our $affiliateid;

our $aspsmst_stat_message_counter;
our $aspsmst_stat_error_counter;
our $aspsmst_stat_notification_counter;
our $transport_secret;
our $xml_networks;
our $xml_fees;
our $aspsmst_stat_stanzas_per_hour;
our $transport_uptime_hours;

our $aspsmst_stat_stanzas 	= 0;
our $aspsmst_in_progress 	= 0;

#
# 1=Enable xmpp debug messages 0=Disabled
#
our $xmpp_debuglevel		= 0;

our $aspsmst_flag_shutdown	= 0;
our $transport_uptime           = 0;
our $aspsmst_stat_msg_per_hour  = 0;

our $Connection;


@ISA 			= qw(Exporter);
@EXPORT 		= qw(	set_config
				$aspsms_connection
				$service_name
				$server
				$port
				$secret
				$passwords
				$release
				$banner
				$jabber_banner
				$admin_jid
				$ident
				$notificationurl
				$notificationjid
				$notificationjid
				$browseservicename
				$browseservicetype
				$aspsmst_stat_message_counter
				$aspsmst_stat_error_counter
				$aspsmst_stat_notification_counter
				$aspsmst_stat_stanzas
				$transport_secret
				$aspsmst_in_progress
				$xml_networks
				$xml_fees
				$aspsmst_flag_shutdown
				$transport_uptime
				$aspsmst_stat_msg_per_hour
				$aspsmst_stat_stanzas_per_hour
				$aspsmst_stat_msg_per_hour
				$transport_uptime
				$transport_uptime_hours
				$prefix_data
				$affiliateid
				$Connection);


sub set_config
 {
  $config_file = shift;
  aspsmst_log("info","set_config(): Read config from $config_file");

  my $Config  =       XML::Smart->new($config_file);

  for (my $i=1;$i<=4;$i++)
   {
    aspsmst_log("debug","set_config(): Read ip configuration for host $i");
    $aspsms_connection{"host_$i"} 		= $Config->{aspsms}{server}('id','eq',"$i"){"host"};
    $aspsms_connection{"port_$i"} 		= $Config->{aspsms}{server}('id','eq',"$i"){"port"};
    $aspsms_connection{"xmlspec_$i"} 		= $Config->{aspsms}{server}('id','eq',"$i"){"xmlspec"};
   }

  $affiliateid		= $Config->{aspsms}{affiliateid};
  $service_name		= $Config->{aspsms}{jabber}{serviceid};
  $server		= $Config->{aspsms}{jabber}{server};
  $port			= $Config->{aspsms}{jabber}{port};
  $secret		= $Config->{aspsms}{jabber}{secret};
  $jabber_banner	= $Config->{aspsms}{jabber}{banner};

  $banner		= $Config->{aspsms}{banner};
  $admin_jid		= $Config->{aspsms}{adminjid};
  $facility 		= $Config->{aspsms}{facility};
  $ident 		= $Config->{aspsms}{ident};
  $passwords		= $Config->{aspsms}{spooldir};
  $notificationurl	= $Config->{aspsms}{notificationurl};
  $notificationjid	= $Config->{aspsms}{notificationjid};
  $browseservicename  	= $Config->{aspsms}{jabber}{browse}{servicename};
  $browseservicetype  	= $Config->{aspsms}{jabber}{browse}{type};
  $transport_secret  	= $Config->{aspsms}{"transport-secret"};

#
# Load Network and fees information
#

aspsmst_log("info","set_config(): Load ./etc/networks.xml and ./etc/fees.xml network and billing information");
$xml_networks  	= XML::Smart->new("./etc/networks.xml") or return -1;
$xml_fees	= XML::Smart->new("./etc/fees.xml") or return -1;

#
# Loading prefix data
#
aspsmst_log("info","set_config(): Load prefix data from etc/fees.xml");
load_prefix_data();

} ### END of set_config ###


1;

