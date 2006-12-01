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
  my $get_type 		= shift;
  my $jid_userkey	= shift;
  
  my $user = {};

  opendir(DIR,"$config::passwords") or die "Can not open spool dir $config::passwords";
  while (defined(my $file = readdir(DIR))) 
   {
    aspsmst_log("debug","get_record($get_type): Processing file $config::passwords/$file");
    
    eval
    {
     open(F, "<$config::passwords/$file") or die "Problem: $!\n";
    };

    #
    # If we can not open the passfile, return -2 (user not registered)
    #

    if($@)
     {
      aspsmst_log("alert","get_record($get_type,$jid_userkey): Problem to open passfile $file");
      return -2;
     }
     
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
	$user->{jid} = $file;

     } ### END of while (<F>)
    close(F);

     if ($get_type eq "userkey")
      {

       if ($jid_userkey eq $user->{name})
        {

         closedir(DIR);
         aspsmst_log('notice',"get_record($get_type): Return: Got $file for ".$user->{name}."/".$user->{phone}."\n");
	 return $user;

        } ### END of if ($jid_userkey eq $user->{name})
      } ### END of if ($get_type eq "userkey")

     if ($get_type eq "jid")
      {

       if ($jid_userkey eq $file)
        {

         closedir(DIR);
         aspsmst_log('notice',"get_record($get_type): Return: Got $file for ".$user->{name}."/".$user->{phone}."\n");
	 return $user;

        } ### END of if ($jid_userkey eq $file)

      } ### END of if ($get_type eq "jid")



    } ### END of while (defined(my $file = readdir(DIR)))
 
return -2;

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
  aspsmst_log("alert","set_record($set_by,$passfile): Problem to read passfile $passfile");
  return -1;
 }
 

return 0;
 } ### END of get_data_from_storage ###

sub delete_record
 {
   my $set_by	= shift;
   my $passfile	= shift;

   aspsmst_log("info","delete_record($set_by,$passfile): Delete passfile $passfile");
   
  eval {
        unlink($passfile);
       };

if($@)
 {
  aspsmst_log("alert","delete_record($set_by,$passfile): Problem to delete passfile $passfile");
  return -1;
 }

return 0;

}


1;
