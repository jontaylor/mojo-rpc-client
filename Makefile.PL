use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'MojoRPC::Client',
    VERSION_FROM      => 'lib/MojoRPC/Client.pm', # finds $VERSION
    PREREQ_PM         => {
      'Want' => 0,
      'Mojo' => 0,
      'HTTP::Request' => 0,
      'MIME::Base64' => 0,
      'JSON::XS' => 0,
      'LWP' => 0,
      'URI' => 0,
      'Carp' => 0,
      'Data::Dumper' => 0,
      'URI::Escape' => 0,

    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/MojoRPC/Client.pm', # retrieve abstract from module
       AUTHOR         => 'Jonathan Taylor <jon@local>') : ()),
);
