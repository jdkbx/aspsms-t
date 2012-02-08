use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'ASPSMS',
    VERSION_FROM      => 'lib/ASPSMS/config.pm', # finds $VERSION
    PREREQ_PM         => {
				File::Pid,
				Net::Jabber,
				XML::Parser,
				XML::Smart,
				Sys::Syslog 
			}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/ASPSMS/config.pm', # retrieve abstract from module
       AUTHOR         => 'Marco balmer <marco@balmer.name>') : ()),
    MAN1PODS         => { 
  'aspsms-t.notify'    => 'blib/man1/aspsms-t.notify.1p',  
  'aspsms-t'    => 'blib/man1/aspsms-t.1p' } 
);
