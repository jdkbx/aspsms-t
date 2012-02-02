#!/usr/bin/perl
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

### CONFIGURATION BEGIN ###
my $login		= '';
my $password		= '';
my $originator		= "";
my $target		= $ARGV[0];
my $affiliateid		= '82723';
my $mess		= $ARGV[1];
### CONFIGURATION END ###

use IO::Socket;
use strict;
use ASPSMS::xmlmodel;

my $aspsms_ip    = 'xml1.aspsms.com';
my $aspsms_port  = '5061';
my $aspsmssocket;

unless($ARGV[0] and $ARGV[1] and $login and $password and $originator)
 {
  print "Please configure the script ./aspsms.SendTextSMS.pl
Usage: ./aspsms.SendTextSMS.pl destination \"text\"\n";
  exit(-1);
 }


my $aspsmsrequest 	= xmlSendTextSMS($login,$password,$originator,$target,$mess,'1','1',$target,$affiliateid);
my $aspsmsrequestlength = length($aspsmsrequest);
my $httprequest 	= xmlGenerateRequest($aspsmsrequest,$aspsmsrequestlength);


$aspsmssocket = IO::Socket::INET->new(  PeerAddr => $aspsms_ip,
                                        PeerPort => $aspsms_port,
                                        Proto    => 'tcp',
                                        Timeout  => 5,
                                        Type     => SOCK_STREAM) or die "Connection to aspsms falied!";

print $aspsmssocket $httprequest;
my @answer = <$aspsmssocket>; 

print "Response:\n\n",@answer;

close($aspsmssocket);
