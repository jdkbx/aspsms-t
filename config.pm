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

package config;

use vars qw(@EXPORT @ISA);
use Exporter;

our $release = " 1.0";

our $aspsmssocket;


@ISA 			= qw(Exporter);
@EXPORT 		= qw(	$service_name,
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
				$Message_Counter,
				$Message_Counter_Error,
				$Connection);

use XML::Smart;

my $configoption = $ARGV[0] || " ";
my $configfile = $ARGV[1]   || " " ;

unless ($configoption eq '-c')
 {
  print "\naspsms-t usage: ./aspsms-t.pl -c aspsms.xml\n\n";
  exit(-1);
 }

my $Config  =       XML::Smart->new($ARGV[1]);

our $aspsms_ip		= $Config->{aspsms}{server}('id','eq','1'){host};
our $aspsms_port	= $Config->{aspsms}{server}('id','eq','1'){port};
our $xmlspec		= $Config->{aspsms}{server}('id','eq','1'){xmlspec};
our $affiliateid	= $Config->{aspsms}{server}('id','eq','1'){affiliateid};

our $service_name	= $Config->{aspsms}{jabber}{serviceid};
our $server		= $Config->{aspsms}{jabber}{server};
our $port		= $Config->{aspsms}{jabber}{port};
our $secret		= $Config->{aspsms}{jabber}{secret};

our $banner		= $Config->{aspsms}{banner};
our $admin_jid		= $Config->{aspsms}{adminjid};
our $facility	 	= $Config->{aspsms}{facility};
our $ident	 	= $Config->{aspsms}{ident};
our $passwords		= $Config->{aspsms}{spooldir};
our $notificationurl	= $Config->{aspsms}{notificationurl};
our $notificationjid	= $Config->{aspsms}{notificationjid};
our $browseservicename  = $Config->{aspsms}{jabber}{browse}{servicename};
our $browseservicetype  = $Config->{aspsms}{jabber}{browse}{type};

our $Message_Counter;
our $Message_Counter_Error;
our $Message_Notification_Counter;
our $Connection;

1;

