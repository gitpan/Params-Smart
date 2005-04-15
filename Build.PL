use Module::Build;

my $build = Module::Build->new
    (
     module_name => 'Params::Smart',
     license => 'perl',
     requires => {
       'perl'             => '5.6.0',
       'Carp'             => 0,
#       'Params::Validate' => 0,
     },
     recommends => {
#        'Test::Pod::Coverage' => 0,
#        'Test::Pod'      => 1.00,
#        'Test::Prereq'   => 0,
     },
     build_requires => {
       'Test::More'     => 0,
     },
     create_readme      => 1,
     create_makefile_pl => 'traditional',
     dist_author        => 'Robert Rothenberg <rrwo at cpan.org>',
     sign               => 1,
);

$build->create_build_script;

