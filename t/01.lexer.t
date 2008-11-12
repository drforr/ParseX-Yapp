use warnings;
use strict;
use Test::More tests => 16;

BEGIN
  {
  use Parse::Yapp;
  use_ok( 'ParseX::Yapp' );
  }

my $lexer_grammar = <<'_EOF_';

%%

input : # empty
  | input syntax { push @{$_[1]}, $_[2]; $_[1] }
  ;

syntax :
    identifier {[ 'identifier', $_[1] ]}
  | string     {[ 'string',     $_[1] ]}
  | codeblock  {[ 'codeblock',  $_[1] ]}
  | ':'        {[ $_[1],        $_[1] ]}
  | ';'        {[ ';',          $_[1] ]}
  ;

%%

_EOF_

my $parser = Parse::Yapp->new
  (
  input => $lexer_grammar
  );
my $yapptxt = $parser->Output( classname => 'ParseX' );
eval $yapptxt;
my $ParseX = ParseX->new;

my $DEBUG;

sub parse
  {
  my ( $text ) = @_;
  $ParseX->YYData->{INPUT} = $text;
  return $ParseX->YYParse( yylex => \&ParseX::Yapp::Lexer, yydebug => $DEBUG );
  }

is_deeply
  (
  parse( q{foo-bar} ),
  [ [ 'identifier', 'foo-bar' ] ],
  q{identifier.1}
  );

is_deeply ( parse( q{:} ), [ [ ':', ':' ] ], q{:.1} );

is_deeply ( parse( q{;} ), [ [ ';', ';' ] ], q{:.1} );

is_deeply
  (
  parse( q{''} ),
  [ [ 'string', q{''} ] ],
  q{string.1}
  );

is_deeply
  (
  parse( q{'1, 2, foo'} ),
  [ [ 'string', q{'1, 2, foo'} ] ],
  q{string.2}
  );

is_deeply
  (
  parse( q{"1, 2, foo"} ),
  [ [ 'string', q{"1, 2, foo"} ] ],
  q{string.3}
  );

is_deeply
  (
  parse( q{'1, 2, \'foo\''} ),
  [ [ 'string', q{'1, 2, \'foo\''} ] ],
  q{string.4}
  );

is_deeply
  (
  parse( q{"1, 2, 'foo'"} ),
  [ [ 'string', q{"1, 2, 'foo'"} ] ],
  q{string.5}
  );

is_deeply
  (
  parse( q{{$_[1]}} ),
  [ [ 'codeblock', q{{$_[1]}} ] ],
  q{codeblock.1}
  );


is_deeply
  (
  parse( qq{'a' 'b'} ),
  [
  [ q{string}, q{'a'} ],
  [ q{string}, q{'b'} ],
  ],
  q{whitespace.1}
  );

is_deeply
  (
  parse( qq{'a'\t'b'} ),
  [
  [ q{string}, q{'a'} ],
  [ q{string}, q{'b'} ],
  ],
  q{whitespace.2}
  );

is_deeply
  (
  parse( qq{'a'\n\n'b'} ),
  [
  [ q{string}, q{'a'} ],
  [ q{string}, q{'b'} ],
  ],
  q{whitespace.3}
  );

is_deeply
  (
  parse( qq{'a'\t'b'} ),
  [
  [ q{string}, q{'a'} ],
  [ q{string}, q{'b'} ],
  ],
  q{whitespace.2}
  );

is_deeply
  (
  parse( qq{'a';'b'} ),
  [
  [ q{string}, q{'a'} ],
  [ q{;},      q{;}   ],
  [ q{string}, q{'b'} ],
  ],
  q{compound.1}
  );

is_deeply
  (
  parse( qq{"1, 2, 'foo'" : bar-foo;'hi there' }.q{{$_[1]++}} ),
    [
    [ q{string},     q{"1, 2, 'foo'"} ],
    [ q{:},          q{:}             ],
    [ q{identifier}, q{bar-foo}       ],
    [ q{;},          q{;}             ],
    [ q{string},     q{'hi there'}    ],
    [ q{codeblock},  q{{$_[1]++}}     ],
    ],
  q{compound.2}
  );
