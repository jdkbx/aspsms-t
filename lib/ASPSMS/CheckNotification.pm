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

=head1 NAME

aspsms-t - notification module.

=head1 SYNOPSIS

my $ret = check_notification();

=head1 DESCRIPTION

Check configuration of aspsms.notify and make a syslog entry if it was 
successfully.

=cut

package ASPSMS::CheckNotification;

use strict;
use vars qw(@EXPORT @ISA);
use ASPSMS::aspsmstlog;

use Exporter;
use Sys::Syslog;

openlog($ASPSMS::config::ident,'','user');


@ISA 				= qw(Exporter);
@EXPORT 			= qw(check_notification);

use ASPSMS::config;
use LWP::UserAgent;
use URI::URL;

=head1 Methods


=over 1

=item * check_notification()

Send check url to verify configuration of aspsms.notify. This 
request will make an syslog entry, that aspsms.notify is successfully
configured.

=back

=cut

sub check_notification 
 {
 
   unless($ASPSMS::config::notificationurl)
    { return "notificationurl is not configured -- skip"; }

   my $url = url($ASPSMS::config::notificationurl);
   aspsmst_log("info","check_notification(): url=$ASPSMS::config::notificationurl");
   
   $url->query_form(xml=>"test,,,test");

   #
   # Send request
   #
   my $ua = LWP::UserAgent->new;
   $ua->timeout(5);
   $ua->agent("$ASPSMS::config::ident Post");
   my $request = HTTP::Request->new('GET', $url);
   my $response = $ua->request($request);
   my $url_response = $response->content;

   my $ret_check_notification;

   #
   # Check response
   #
   if($url_response =~ /Successfully/)
    {
     $ret_check_notification = "Successfully";
    }
   else
    {
     $ret_check_notification = $url_response;
    }

   return $ret_check_notification;
 }

1;

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2012 Marco Balmer <marco@balmer.name>

The Debian packaging is licensed under the 
GPL, see `/usr/share/common-licenses/GPL-2'.

=cut
