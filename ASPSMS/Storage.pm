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
@EXPORT 		= qw(get_data_from_storage set_data_to_storage);


use Sys::Syslog;
use ASPSMS::aspsmstlog;

my $spooldir = $config::passwords;

sub get_data_from_storage
 {
  my $read_by 		= shift;
  my $jid		= shift;
  
  my $user = {};

  my $passfile 		= "$config::passwords/$jid";
  open(F, "<$passfile");
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
  
return (	
	$user->{gateway}, 
    	$user->{name}, 
	$user->{password}, 
	$user->{phone},
	$user->{signature}
	);

 } ### END of get_data_from_storage ###

sub set_data_to_storage
 {

 } ### END of get_data_from_storage ###


1;
