use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Data::Pageset',
    'VERSION_FROM'	=> 'Pageset.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		'Data::Page'	=> 0.15,
		'Test::More' => 0.1,
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Pageset.pm', # retrieve abstract from module
       AUTHOR     => 'Leo Lapworth <LLAP@cuckoo.org>') : ()),
);
