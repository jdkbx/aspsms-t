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

package ASPSMS::ContactCredits;

use strict;
use vars qw(@EXPORT @ISA);
use ASPSMS::aspsmstlog;
use ASPSMS::config;

use Exporter;
use Sys::Syslog;

openlog($ASPSMS::config::ident,'','user');


@ISA 				= qw(Exporter);
@EXPORT 			= qw(load_prefix_data);



sub load_prefix_data 
 {
  my @countries		= $ASPSMS::config::xml_fees->{"fees"}{"country"}('[@]','name');
  my @networks;

  foreach my $country_i (@countries)
   {
    #
    # Load all networks
    #
    @networks 		= $ASPSMS::config::xml_fees->{"fees"}{"country"}('name','eq',"$country_i"){"network"}('[@]','name');
    #
    # Get credits for this network
    #
    my $credits 	= $ASPSMS::config::xml_fees->{"fees"}{"country"}('name','eq',"$country_i"){"network"}('[@]','credits');
    foreach my $network_i (@networks)
     {
      #
      # Load all prefixes for $network_i
      #
      my @prefixes 		= $ASPSMS::config::xml_fees->{"fees"}{"country"}('name','eq',"$country_i"){"network"}('name','eq',"$network_i"){"prefix"}('[@]','number');
      foreach my $prefix_i (@prefixes)
       {
        aspsmst_log("debug","load_prefix_data(): Loading prefix=$prefix_i credits=$credits");
	#
	# Relate credits to this $prefix_i
	#
	$ASPSMS::config::prefix_data->{"$prefix_i"} = $credits;
       } ### END of foreach my $prefix_i (@prefixes)
     } ### END of foreach my $network_i (@networks)
   } ### END of foreach my $country_i (@countries)
 } ### END of load_prefix_data()

1;

