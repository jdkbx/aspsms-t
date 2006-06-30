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

our $release = " 1.0.3";

our $config_file;
our $aspsmssocket;

our $aspsms_ip;
our $aspsms_port;
our $xmlspec;
our $affiliateid;

our $service_name;
our $server;
our $port;
our $secret;

our $banner;
our $admin_jid;
our $facility;
our $ident;
our $passwords;
our $notificationurl;
our $notificationjid;
our $browseservicename;
our $browseservicetype;

our $stat_message_counter;
our $stat_error_counter;
our $stat_notification_counter;
our $transport_secret;

our $stat_stanzas = 0;
our $Connection;

@ISA 			= qw(Exporter);
@EXPORT 		= qw(	set_config
				$service_name,
				$server,
				$port,
				$secret,
				$passwords,
				$release,
				$xmlspec,
				$aspsms_ip,
				$aspsms_port,
				$banner,
				$admin_jid,
				$ident,
				$affiliateid,
				$notificationurl,
				$notificationjid,
				$notificationjid,
				$browseservicename,
				$browseservicetype,
				$stat_message_counter,
				$stat_error_counter,
				$stat_notification_counter,
				$transport_secret,
				$Connection);


sub set_config
 {
  $config_file = shift;
  aspsmst_log("info","set_config(): Read config from $config_file");

  my $Config  =       XML::Smart->new($config_file);

  $aspsms_ip		= $Config->{aspsms}{server}('id','eq','1'){"host"};
  $aspsms_port		= $Config->{aspsms}{server}('id','eq','1'){"port"};
  $xmlspec		= $Config->{aspsms}{server}('id','eq','1'){"xmlspec"};
  $affiliateid		= $Config->{aspsms}{server}('id','eq','1'){"affiliateid"};

  $service_name		= $Config->{aspsms}{jabber}{serviceid};
  $server		= $Config->{aspsms}{jabber}{server};
  $port			= $Config->{aspsms}{jabber}{port};
  $secret		= $Config->{aspsms}{jabber}{secret};

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

} ### END of set_config ###


1;

