# aspsms-t

Check this site for the latest version of this software:

  <http://github.com/jdkbx/aspsms-t>
  <http://github.com/micressor/aspsms-t> (original)

# Overview

sms transport for your xmpp/jabber server

With aspsms-t your jabber users are able to send sms messages through the gateway-system of aspsms.com.

* A lot of networks are supported.

* Delivery is very fast and will send your users a confirmation jabber message.
  Jabber users can set their own mobile number as originator.

* Jabber messages which are longer than the maximum allowed characters of an
  sms, aspsms-t will split it into a multiple sms. Don´t worry!

* Unicode message support.


# Requirements for Debian

	apt-get install libaspsms-perl libnet-jabber-perl libnet-xmpp-perl \
	  libxml-smart-perl libxml-parser-perl libwww-perl liburi-perl \
	  libunicode-string-perl libfile-pid-perl liblog-log4perl-perl \
	  libgetopt-long-descriptive-perl libsoap-lite-perl \
	  libhttp-server-simple-perl


# Building

	cd $src
	Perl Makefile.PL
	make
	make test
	make install
	cp ./aspsms-t /usr/local/bin
	cp ./aspsms-t.notify /usr/local/bin

# Configuring

Copy example configuration file to /etc/aspsms/

	cp etc/aspsms-t.xml.dist /etc/aspsms/aspsms.xml

and configure it according to your jabber-server and system environment settings. Additionally information how to configure jabber-servers like jabberd14 or ejabberd you can find at the manpages.

	man aspsms-t
	man aspsms-t.notify

# Starting up

With debug log messages:

	aspsms-t -c /etc/aspsms/aspsms-t.xml

Without debug log messages:

	aspsms-t -c /etc/aspsms/aspsms-t.xml 2>&1 > /dev/null

Openrc /etc/init.d scripts and systemd units can be found in the etc directory:

Have fun!
