use ExtUtils::MakeMaker;

WriteMakefile(
	NAME            => 'ASPSMS',
	VERSION_FROM    => 'lib/ASPSMS/config.pm',
	INSTALL_BASE	=> '/home/maba',
	PREREQ_PM     => {
			 File::Pid,
			 Net::Jabber,
			 XML::Parser,
			 XML::Smart,
			 Sys::Syslog
                       },
);
