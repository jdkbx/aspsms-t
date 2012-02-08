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

aspsms-t - logging interface

=head1 SYNOPSIS

 use ASPSMS::aspsmstlog;
 aspsmst_log("info","Starting up...");

=head1 DESCRIPTION

This function logs to debug messages to STDOUT and normal
log messages to a syslog daemon.

=cut

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
       print "\n[debug] aspsmst_log(): Exeption: We have problem to log a message -- Ignore";
      }
    }

   else

    {
     print "\n[debug] $msg";
    }

 } ### END of aspsmst_log

1;

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2012 Marco Balmer <marco@balmer.name>

The Debian packaging is licensed under the 
GPL, see `/usr/share/common-licenses/GPL-2'.

=cut
