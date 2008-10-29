use Test::More tests => 1;

BEGIN
  {
  use Parse::Yapp;
  use_ok( 'ParseX::Yapp' );
  }

my $error = undef;

# {{{ stuff
my $yapp = Parse::Yapp->new( input => $ParseX::Yapp::grammar );
eval $yapp->Output( classname => 'ParseX' );
my $parser = ParseX->new;

sub parse
  {
  my ( $text ) = @_;
  $error = undef;
  $parser->YYData->{INPUT} = $text;
  return $parser->YYParse
    (
    yylex => \&ParseX::Yapp::Lexer,
    yyerror => sub { $error = 1 } 
    );
  }

# }}}

use YAML;
sub run_test
  {
  my ( $str, $layout, $debug ) = @_;
  my $final = parse($str);
  $debug == 1 and defined($final) and do
    {
    warn qq{q{$str}: }.Dump($final)
    };
  ok( defined($final), qq{valid parse of q{$str}} );
  is_deeply( $layout, $final, qq{conforming parse of q{$str}} );
  }

=pod

Rules can have the same name, we'll merge them later.
So, the outer layer should be an aref.

q{A:b|c; A:c|d} =>

=cut

die Dump
  (
  parse
    (
    q{A:b;B:c d;C:c|d e+|f<g,h> i %prec FOO | (foo|bar)+;}
    )
  );

=pod

=cut
