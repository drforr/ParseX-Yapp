use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'ParseX::Yapp',
    AUTHOR              => 'Jeffrey Goff <jgoff@cpan.org>',
    VERSION_FROM        => 'lib/ParseX/Yapp.pm',
    ABSTRACT_FROM       => 'lib/ParseX/Yapp.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Parse::Yapp' => 0,
        'Regexp::Common' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'ParseX-Yapp-*' },
);
