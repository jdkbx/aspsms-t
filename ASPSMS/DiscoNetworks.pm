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

package ASPSMS::DiscoNetworks;

use strict;
use vars qw(@EXPORT @ISA);

use Exporter;
use Sys::Syslog;

use config;
use ASPSMS::aspsmstlog;

openlog($config::ident,'','user');


@ISA 				= qw(Exporter);
@EXPORT 			= qw(disco_get_aspsms_networks);



sub disco_get_aspsms_networks
{
 my $iqQuery	= shift;
 my $from	= shift;
 my $to		= shift;

      aspsmst_log('notice',"disco_get_aspsms_networks($from): Display network countries");
      my @countries	= $config::xml_networks->{networks}{country}('[@]','name');

      #
      # Generate disco item for each country
      #
      if($to eq "countries\@".$config::service_name)
      {
       foreach my $i (@countries)
       {
        aspsmst_log('debug',"disco_get_aspsms_networks($from): Country: $i");
        $i =~ tr/A-Z/a-z/;
        
        #
        # Jid fix for spaces in country names
         #
        $i =~ s/\s/\_/g;
        unless($i eq "")
         {
          $iqQuery->AddItem(	jid=>"$i\@".$config::service_name,
        				name=>$i);
         } ### END of unless($li eq "")
       } ### END of foreach my $i (@countries)
      } ### END of if($to eq "countries\@⅛.$config::service_name")

    my @select_country = split(/@/,$to);
    if($to eq $select_country[0]."@".$config::service_name)
     {
      
      #
      # Jid fix for spaces in country names
      #
      $select_country[0] =~ s/\_/\ /g;

      aspsmst_log('debug',"disco_get_aspsms_networks($from): Display network of country ".$select_country[0]);

      #
      # Change country to uppercase
      #
      $select_country[0] =~ tr/a-z/A-Z/;
      my @networks	= $config::xml_networks->{"networks"}{"country"}('name','eq',"$select_country[0]"){"network"}('[@]','name');
      my @credits	= $config::xml_networks->{"networks"}{"country"}('name','eq',"$select_country[0]"){"network"}('[@]','credits');

      my @prefixes;

      my $counter_networks 	=0;
      my $counter_prefixes	=0;
      foreach my $i (@networks)
      {
       #
       # Generate disco item for each country
       #
       aspsmst_log('debug',"disco_get_aspsms_networks($from): Network $counter_networks: $i");

       unless($i eq "")
	{
         $iqQuery->AddItem(	name=>"Network: $i");
        } ### END of unless($i eq "")

       @prefixes = $config::xml_fees->{"fees"}{"country"}('name','eq',"$select_country[0]"){"network"}('name','eq',"$i"){"prefix"}('[@]','number');

       $counter_prefixes	=0;
       foreach my $i_prefix (@prefixes)
        {
         #
         # Generate disco item for prefixes
         #
	 unless($i_prefix eq "")
	  {
           aspsmst_log('debug',"disco_get_aspsms_networks($from): Prefix $counter_prefixes: $i_prefix");
           $iqQuery->AddItem(name=>"Network: $i Prefix: $i_prefix [Credits:$credits[0]]");
	  }
	 $counter_prefixes++;
	} ### END of foreach my $i (@prefixes)
       $counter_networks++;
      } ### END of foreach my $i (@countries)

     } ### END of if($to eq "networks\@$config::service_name")

 return $iqQuery;
} ### END of disco_get_aspsms_networks ###

1;

