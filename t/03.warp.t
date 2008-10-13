use Test::More tests => 1;

BEGIN
  {
  use Parse::Yapp;
  use_ok( 'ParseX::Yapp' );
  }

sub Lexer
  {
  my ( $parser ) = @_;

  exists $parser->YYData->{LINE} or $parser->YYData->{LINE} = 1;

  $parser->YYData->{INPUT} or return ( '', undef );
  $parser->YYData->{INPUT} =~ s( ^ [ \t\n]+ )()x;

  for ($parser->YYData->{INPUT})
    {
    s( ^ (.) )()x and return ( $1, $1 );
    }
  }

die ParseX::Yapp::Warp(<<'_EOF_');
A : b 'c' { $_[1] } ;
C : 'd' e { $_[1] }
  | f { $_[2] }
_EOF_
