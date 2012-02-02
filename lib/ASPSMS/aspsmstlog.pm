# aspsms-t
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

package ASPSMS::aspsmstlog;

use strict;
use vars qw(@EXPORT @ISA);
use Exporter;

@ISA 			= qw(Exporter);
@EXPORT 		= qw(aspsmst_log);


use Sys::Syslog;


sub aspsmst_log
 {
   my $type      = shift;
   my $msg       = shift;

   unless ($type eq 'debug')

    {
     print "\n[$type]  $msg";

     eval
      {
       syslog($type,"[$type] $msg");
      };
     
     #
     # If we have a problem logging a message, we logging a 
     # warning.
     #
     if($@)
      {
       syslog($type,"aspsmst_log(): Exeption: We have problem to log a message -- Ignore");
      }
    }

   else

    {
     print "\n[debug] $msg";
    }

 } ### END of aspsmst_log

1;

