use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'ParseX::Yapp',
    license             => 'perl',
    dist_author         => 'Jeffrey Goff <jgoff@cpan.org>',
    dist_version_from   => 'lib/ParseX/Yapp.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'ParseX-Yapp-*' ],
);

$builder->create_build_script();
