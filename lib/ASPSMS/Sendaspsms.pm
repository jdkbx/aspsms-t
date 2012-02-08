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

aspsms-t - main function to send an jabber to sms.

=head1 METHODS

=cut

package ASPSMS::Sendaspsms;

use strict;
use vars qw(@EXPORT @ISA);
use ASPSMS::aspsmstlog;
use ASPSMS::Connection;
use ASPSMS::userhandler;
use ASPSMS::xmlmodel;
use ASPSMS::Regex;

use Exporter;
use IO::Socket;


use Sys::Syslog;

openlog($ASPSMS::config::ident,'','user');


@ISA 				= qw(Exporter);
@EXPORT 			= qw(Sendaspsms);


my $banner			= 	$ASPSMS::config::banner;
my $aspsmssocket		= 	$ASPSMS::config::aspsmssocket;
my $aspsms_ip                   =       $ASPSMS::config::aspsms_ip;
my $aspsms_port                 =       $ASPSMS::config::aspsms_port;



########################################################################
sub Sendaspsms {
# #######################################################################
my (	$number, 
	$from, 
	$msg,
	$aspsmst_transaction_id,
	$msg_id,
	$msg_type) = @_;
my $xmppanswer;

=head2 Sendaspsms()

This function handle the interaction between jabber and sms.

=cut

aspsmst_log('debug',"id:$aspsmst_transaction_id Sendaspsms(): Begin");

$number = substr($number, 1, 50);

=head2

=over 4

=item * Do we have a correct registered user?

=back 

=cut

my $user = getUserPass($from,$banner,$aspsmst_transaction_id);

if($user == -2)
                        {
			    my $msg_register 
			    = "Your jid `$from` is not " .
			    "registered on \`$ASPSMS::config::service_name\` for" .
			    "using sms services. Please register first to".
			    "this transport.";
                            aspsmst_log('warning',"Sendaspsms(): $msg_register");
                            return (99,$msg_register);
                        }


aspsmst_log('debug',"id:$aspsmst_transaction_id Sendaspsms(): sending message to number $number");

=head2

=over 4

=item * If ok we put it through exec_SendTextSMS() function.

=back

=cut

my (	$result,
	$resultdesc,
	$Credits,
	$CreditsUsed,
	$random) = exec_SendTextSMS(	$number, 
					$msg, 
					$user->{name}, 
					$user->{password},
					$user->{phone},
					$user->{signature},
					$from,
					$aspsmst_transaction_id,
					$msg_id,
					$msg_type);


if ($result == 1) 
 { $ASPSMS::config::stat_message_counter++; } 
else 
 { $ASPSMS::config::stat_error_counter++; }

my $xmppanswerlog = "SMS from $from to $number (Balance: $Credits Used: " .
"$CreditsUsed) has status --> $result ($resultdesc)";

if ($result == 1) {

$xmppanswer = "
Status(for SMS $random) --> $resultdesc 

Balance: $Credits / Used: $CreditsUsed 

SMS (for $number):
$msg

$ASPSMS::config::ident Gateway system v$ASPSMS::config::release
";

$resultdesc = $xmppanswer;
}

aspsmst_log('debug',"Sendaspsms(): id:$aspsmst_transaction_id End $xmppanswerlog");

=head2

=over 4

=item * And finally we give the status of this transaction als a return
value back

=back

=cut

return ($result,$resultdesc,$Credits,$CreditsUsed,$random);

########################################################################
}
########################################################################

1;

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2012 Marco Balmer <marco@balmer.name>

The Debian packaging is licensed under the 
GPL, see `/usr/share/common-licenses/GPL-2'.

=cut
