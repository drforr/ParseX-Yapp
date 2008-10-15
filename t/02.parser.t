use Test::More tests => 11;

BEGIN
  {
  use Parse::Yapp;
  use_ok( 'ParseX::Yapp' );
  }

my $parser =
  Parse::Yapp->new ( input => $ParseX::Yapp::header . $ParseX::Yapp::grammar );
eval $parser->Output( classname => 'ParseX' );
my $ParseX = ParseX->new;

my $DEBUG;

sub parse
  {
  my ( $text ) = @_;
  $ParseX->YYData->{INPUT} = $text;
  my $foo =
    $ParseX->YYParse( yylex => \&ParseX::Yapp::Lexer, yydebug => $DEBUG );
  return $ParseX->YYData->{VARS};
  }

is_deeply
  (
  parse( q{A:b} ),
  { A => [ [ 'b' ] ] },
  q{A:b}
  );

is_deeply
  (
  parse( q{A :b} ),
  { A => [ [ 'b' ] ] },
  q{A :b}
  );

is_deeply
  (
  parse( q{A : b} ),
  { A => [ [ 'b' ] ] },
  q{A : b}
  );

is_deeply
  (
  parse( q{A\n:b} ),
  { A => [ [ 'b' ] ] },
  q{A\n:b}
  );

is_deeply
  (
  parse( q{A\n\n:b} ),
  { A => [ [ 'b' ] ] },
  q{A\n\n:b}
  );

is_deeply
  (
  parse( q{A:b c} ),
  { A => [ [ 'b', 'c' ] ] },
  q{A:b c}
  );

is_deeply
  (
  parse( q{A:b c|d} ),
  { A => [ [ 'b', 'c' ], [ 'd' ] ] },
  q{A:b c|d}
  );

is_deeply
  (
  parse( qq{A:b;B:c} ),
  { A => [ [ 'b' ] ], B => [ [ 'c' ] ] },
  q{A:b;B:c}
  );

is_deeply
  (
  parse( qq{A:b\n;\nB:c\n  | d} ),
  { A => [ [ 'b' ] ], B => [ [ 'c' ], [ 'd' ] ] },
  q{A:b\n;\nB:c\n  | d},
  );

is_deeply
  (
  parse( <<'_EOF_'),
A:b %prec NEG { $_[1] }
;
B:c { $_[2] }
  | d { $_[3] }
_EOF_
  {
  A => [ [ 'b', '%prec', 'NEG', '{ $_[1] }' ] ],
  B => [ [ 'c', '{ $_[2] }' ], [ 'd', '{ $_[3] }' ] ]
  },
  q{A:b\n;\nB:c\n  | d},
  );
