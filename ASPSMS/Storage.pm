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

package ASPSMS::Storage;

use strict;
use config;
use vars qw(@EXPORT @ISA);
use Exporter;

@ISA 			= qw(Exporter);
@EXPORT 		= qw(get_record set_record delete_record);


use Sys::Syslog;
use ASPSMS::aspsmstlog;
use ASPSMS::Jid;


sub get_record
 {
  my $read_by 		= shift;
  my $jid		= shift;
  my $barejid		= get_barejid($jid);
  
  my $user = {};

  my $passfile 		= "$config::passwords/$barejid";

  aspsmst_log("notice","get_record($read_by): Read passfile for $barejid");

eval {

  open(F, "<$passfile") or die "Problem: $!\n";
  seek(F, 0, 0);
  local $/ = "\n";

  while (<F>) 
   {
    chop;
    	(	
	$user->{gateway}, 
    	$user->{name}, 
	$user->{password}, 
	$user->{phone},
	$user->{signature}
	) = split(':');

   } ### END of while (<F>)

close(F);
 
 };

if($@)
 {
  aspsmst_log("info","get_record($read_by): Problem to read passfile for $barejid");
  aspsmst_log("notice","get_record($read_by): Problem to read passfile $passfile");
  return -1;
 }

return (0,$user);

 } ### END of get_data_from_storage ###

sub set_record
 {
   my $set_by	= shift;
   my $passfile	= shift;
   my $userdata	= shift;

   aspsmst_log("notice","set_record($set_by,$passfile): Store passfile $passfile");
   
   my $data = join(':',	
	$userdata->{gateway}, 
    	$userdata->{name}, 
	$userdata->{pass}, 
	$userdata->{phone},
	$userdata->{signature}
	);

eval {
      open(F, ">$passfile");
      print(F "$data\n");
      close(F);
     };

if($@)
 {
  aspsmst_log("info","set_record($set_by,$passfile): Problem to read passfile $passfile");
  return -1;
 }
 

return 0;
 } ### END of get_data_from_storage ###

sub delete_record
 {
   my $set_by	= shift;
   my $passfile	= shift;

   aspsmst_log("notice","delete_record($set_by,$passfile): Delete passfile $passfile");
   
  eval {
        unlink($passfile);
       };

if($@)
 {
  aspsmst_log("info","delete_record($set_by,$passfile): Problem to delete passfile $passfile");
  return -1;
 }

return 0;

}
1;
