use Test::More tests => 14;

BEGIN
{
use Parse::Yapp;
use_ok( 'ParseX::Yapp' );
}

my $lexer_header = <<'_EOF_';

input : # empty
  | input syntax { push @{$_[1]}, $_[2]; $_[1] }
  ;

syntax :
    rule_name { [ 'rule_name', $_[1] ] }
  | literal { [ 'literal', $_[1] ] }
  | ':' { [ $_[1], $_[1] ] }
  | ';' { [ ';', $_[1] ] }
  ;

%%

_EOF_

my $parser = Parse::Yapp->new
  (
  input => $ParseX::Yapp::header . $lexer_header
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
  [ [ 'rule_name', 'foo-bar' ] ],
  q{rule_name.1}
  );

is_deeply ( parse( q{:} ), [ [ ':', ':' ] ], q{:.1} );

is_deeply ( parse( q{;} ), [ [ ';', ';' ] ], q{:.1} );

is_deeply
  (
  parse( q{'1, 2, foo'} ),
  [ [ 'literal', q{'1, 2, foo'} ] ],
  q{literal.1}
  );

is_deeply
  (
  parse( q{"1, 2, foo"} ),
  [ [ 'literal', q{"1, 2, foo"} ] ],
  q{literal.2}
  );

is_deeply
  (
  parse( q{'1, 2, \'foo\''} ),
  [ [ 'literal', q{'1, 2, \'foo\''} ] ],
  q{literal.3}
  );

is_deeply
  (
  parse( q{"1, 2, 'foo'"} ),
  [ [ 'literal', q{"1, 2, 'foo'"} ] ],
  q{literal.4}
  );

is_deeply
  (
  parse( qq{'a' 'b'} ),
  [
  [ q{literal}, q{'a'} ],
  [ q{literal}, q{'b'} ],
  ],
  q{whitespace.1}
  );

is_deeply
  (
  parse( qq{'a'\t'b'} ),
  [
  [ q{literal}, q{'a'} ],
  [ q{literal}, q{'b'} ],
  ],
  q{whitespace.2}
  );

is_deeply
  (
  parse( qq{'a'\n\n'b'} ),
  [
  [ q{literal}, q{'a'} ],
  [ q{literal}, q{'b'} ],
  ],
  q{whitespace.3}
  );

is_deeply
  (
  parse( qq{'a'\t'b'} ),
  [
  [ q{literal}, q{'a'} ],
  [ q{literal}, q{'b'} ],
  ],
  q{whitespace.2}
  );

is_deeply
  (
  parse( qq{'a';'b'} ),
  [
  [ q{literal}, q{'a'} ],
  [ q{;},       q{;}   ],
  [ q{literal}, q{'b'} ],
  ],
  q{compound.1}
  );

is_deeply
  (
  parse( qq{"1, 2, 'foo'" : bar-foo;'hi there'} ),
    [
    [ q{literal},   q{"1, 2, 'foo'"} ],
    [ q{:},         q{:}             ],
    [ q{rule_name}, q{bar-foo}       ],
    [ q{;},         q{;}             ],
    [ q{literal},   q{'hi there'}    ],
    ],
  q{compound.2}
  );
