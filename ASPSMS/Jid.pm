# aspsms-t by Marco Balmer <mb@micressor.ch> @2005
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

package ASPSMS::Jid;

use strict;
use config;
use vars qw(@EXPORT @ISA);
use Exporter;

@ISA 			= qw(Exporter);
@EXPORT 		= qw(get_barejid get_jid_from_userkey);


use Sys::Syslog;
use ASPSMS::aspsmstlog;

my $spooldir = $config::passwords;

sub get_barejid
 {
   my $jid = shift;
   my ($barejid)                 = split (/\//, $jid);
   return $barejid;
 } # END of get_barejid

sub get_jid_from_userkey
 {
  my $userkey 	= shift;
   opendir(DIR,$spooldir) or die;
   while (defined(my $file = readdir(DIR))) 
    {
     open(FILE,"<$spooldir/$file") or return "no file";
     my @lines = <FILE>;
     close(FILE);
     # process 
     my $line 	= $lines[0];
     my @data	= split(/:/,$line);
     my $get_userkey	= $data[1];
     if ($userkey eq $get_userkey)
      {
        closedir(DIR);
        aspsmst_log('notice',"get_jid_from_userkey($userkey): Return: $get_userkey");
	return $file;
      }
    } # END of while
} ### END of get_jid_from_userkey ###
1;
