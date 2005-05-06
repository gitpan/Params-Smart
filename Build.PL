use Module::Build;

my $build = Module::Build->new
    (
     module_name => 'Params::Smart',
     license => 'perl',
     requires => {
       'perl'             => '5.6.0',
       'Carp'             => 0,
       'Regexp::Common'   => 1.8,
     },
     recommends => {
       'Pod::Readme'      => 0,
#        'Test::Pod::Coverage' => 0,
#        'Test::Pod'      => 1.00,
#        'Test::Prereq'   => 0,
     },
     build_requires => {
       'Test::More'     => 0,
     },
     create_readme      => 0,
     create_makefile_pl => 'traditional',
     dist_author        => 'Robert Rothenberg <rrwo at cpan.org>',
     sign               => 1,
);

$build->create_build_script;

