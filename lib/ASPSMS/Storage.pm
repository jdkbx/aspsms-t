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

aspsms-t - spool storage manipulation functions

=head1 METHODS

=cut

package ASPSMS::Storage;

use strict;
use ASPSMS::config;
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

=head2 get_record()

my $userobject = get_record($type,$jid or $userkey)

Based on what we need, we can read USERKEY or jid (jabber-id) from spool 
storage.

=cut
  
  my $user = {};

  opendir(DIR,"$ASPSMS::config::passwords") or die "Can not open spool dir $ASPSMS::config::passwords";
  while (defined(my $file = readdir(DIR))) 
   {
    aspsmst_log("debug","get_record($get_type): Processing file $ASPSMS::config::passwords/$file");
    
    my $ret_open =  open(F, "<$ASPSMS::config::passwords/$file");

    # If we can not open the passfile, return -2 (user not registered)
    if($ret_open ne "1")
     {
      aspsmst_log("alert","get_record($get_type,$jid_userkey): Problem to open passfile $file:");
      aspsmst_log("alert","get_record($get_type,$jid_userkey): $@");
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
         aspsmst_log('debug',"get_record($get_type): Return: Got $file for ".$user->{name}."/".$user->{phone}."\n");
	 return $user;

        } ### END of if ($jid_userkey eq $user->{name})
      } ### END of if ($get_type eq "userkey")

     if ($get_type eq "jid")
      {

       if ($jid_userkey eq $file)
        {

         closedir(DIR);
         aspsmst_log('debug',"get_record($get_type): Return: Got $file for ".$user->{name}."/".$user->{phone}."\n");
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

=head2 set_record()

my $ret = set_record($jid,$userdataobject);

This function is called from jabber register functions to store new user
configurations to the spool/ directory.

It returns 0 for ok and -1 for a failure.

=cut

   aspsmst_log("debug","set_record($set_by,$passfile): Store passfile $passfile");
   
   my $data = join(':',	
	$userdata->{gateway}, 
    	$userdata->{name}, 
	$userdata->{pass}, 
	$userdata->{phone},
	$userdata->{signature}
	);

      my $ret_open = open(F, ">$passfile");

if($ret_open ne "1")
 {
  aspsmst_log("alert","set_record($set_by,$passfile): Problem to read passfile $passfile");
  return -1;
 }
 
      print(F "$data\n");
      close(F);

return 0;
 } ### END of get_data_from_storage ###

sub delete_record
 {
   my $set_by	= shift;
   my $passfile	= shift;

=head2 delete_record()

my $ret = delete_record($set_by,$passfile);

This function remove a registration of a jabber user. This function is called
by jabber_iq_remove() if a user want to unregister his configuration 
from aspsms-t.

=cut

   aspsmst_log("info","delete_record($set_by,$passfile): Delete passfile $passfile");
   
  my $ret_delete = unlink($passfile);

if($ret_delete eq "0")
 {
  aspsmst_log("alert","delete_record($set_by,$passfile): Problem to delete passfile $passfile");
  return -1;
 }

return 0;

}


1;

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2012 Marco Balmer <marco@balmer.name>

The Debian packaging is licensed under the 
GPL, see `/usr/share/common-licenses/GPL-2'.

=cut
