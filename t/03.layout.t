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

#
# This seems to be a pretty common thing to do:
#
# list : item { [ $_[1] ] }
#      | list item  { push @{$_[1]}, $_[2] }
#      ;
# 
# Why not encapsulate it?
#

sub _term
  {
  my ( $term ) = @_;
  if ( $term->{modifier} )
    {
    return $term->{name} . $term->{modifier};
    }
  return $term->{name};
  }

sub _concatenation
  {
  my ( $concatenation ) = @_;
  return join q{ }, map { _term($_) } @$concatenation;
  }

sub _alternation
  {
  my ( $alternation ) = @_;
  return join q{ | }, map { _concatenation($_->{concatenation}) } @$alternation;
  }

sub rebuild
  {
  my ( $rules ) = @_;
  my $text;

  return join qq{\n}, map
    {
    if ( $_->{parameter_list} )
      {
      my $params = join ',', @{$_->{parameter_list}};
      "$_->{name}<$params> : "._alternation($_->{alternation}).";";
      }
    else
      {
      "$_->{name} : "._alternation($_->{alternation}).";";
      }
    }
  @$rules;
  }

my $test = q{A:b;B:c 'd';C<length,precision>:length|precision '.' e+|f<g,h> i %prec FOO | (foo|bar)+;};

warn rebuild(parse($test));

die Dump ( parse($test) );

=pod

---
- alternation:
    - concatenation:
        - name: f
        - name:
            - g
            - h
        - name: i
      precedence: FOO
    - concatenation:
        - children:
            - 
              - name: foo
            - 
              - name: bar
          modifier: +
  name: C

=cut
