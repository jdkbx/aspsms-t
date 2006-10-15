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

package ASPSMS::SendContactStatus;

use strict;
use vars qw(@EXPORT @ISA);
use ASPSMS::aspsmstlog;

use Exporter;
use Sys::Syslog;
use ASPSMS::Jid;
use Presence;

openlog($config::ident,'','user');


@ISA 				= qw(Exporter);
@EXPORT 			= qw(sendContactStatus);


sub sendContactStatus
 {
  my $from 		= shift;
  my $to		= shift;
  my $show		= shift;
  my $status		= shift;
  my $from_barejid	= get_barejid($from);

 my $workpresence = new Net::Jabber::Presence();
 aspsmst_log('notice',"sendContactStatus($from_barejid): Sending `$status'");
 sendPresence(undef,$from,$to,undef,$show,$status,5);
 }

1;
