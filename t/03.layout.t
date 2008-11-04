use Test::More tests => 5;

BEGIN
  {
  use Parse::Yapp;
  use_ok( 'ParseX::Yapp' );
  }

# {{{ stuff
my $yapp = Parse::Yapp->new( input => $ParseX::Yapp::grammar );
eval $yapp->Output( classname => 'ParseX' );
my $parser = ParseX->new;

sub parse
  {
  my ( $text ) = @_;
  $parser->YYData->{INPUT} = $text;
  return $parser->YYParse ( yylex => \&ParseX::Yapp::Lexer );
  }

# }}}

sub run_test
  {
  my ( $str, $layout, $debug ) = @_;
  my $final = parse($str);
  $debug and $debug == 1 and defined($final) and do
    {
    warn qq{q{$str}: }.Dump($final)
    };
  ok( defined($final), qq{valid parse of q{$str}} );
  is_deeply( $layout, $final, qq{conforming parse of q{$str}} );
  }

run_test
  (
  q{A:a;},
    [{
    name => 'A',
    alternation =>
      [{
      concatenation =>
        [{
        name => 'a'
        }]
      }]
    }]
  );

run_test
  (
  q{A:a b;},
    [{
    name => 'A',
    alternation =>
      [{
      concatenation =>
        [
          { name => 'a' },
          { name => 'b' }
        ]
      }]
    }]
  );

#
# This seems to be a pretty common thing to do:
#
# list : item { [ $_[1] ] }
#      | list item  { push @{$_[1]}, $_[2] }
#      ;
# 
# Why not encapsulate it?
#

# {{{ _term($term)
sub _term
  {
  my ( $term ) = @_;
  if ( $term->{modifier} )
    {
    return $term->{name} . $term->{modifier};
    }
  return $term->{name};
  }

# }}}

# {{{ _concatenation($concatenation)
sub _concatenation
  {
  my ( $concatenation ) = @_;
  return join q{ }, map { _term($_) } @$concatenation;
  }

# }}}

# {{{ _alternation($alternation)
sub _alternation
  {
  my ( $alternation ) = @_;
  return join q{ | }, map { _concatenation($_->{concatenation}) } @$alternation;
  }

# }}}

# {{{ _rule_name($rule_name)
sub _rule_name
  {
  my ( $rule_name ) = @_;
  if ( $rule_name->{parameter_list} )
    {
    my $params = join ',', @{$rule_name->{parameter_list}};
    return "$rule_name->{name}<$params>";
    }

  return $rule_name->{name};
  }

# }}}

# {{{ rebuild($rules)
sub rebuild
  {
  my ( $rules ) = @_;

  return join qq{\n}, map
    {
    _rule_name($_) . " : " . _alternation($_->{alternation}) . " ;"
    }
  @$rules;
  }

# }}}

#my $test = q{A:b;B:c 'd';C<length,precision>:length|precision '.' e+|f<g,h> i %prec FOO | (a b c|d e f)+;};
#my $test = q{A:b|c d|e f g;};
#my $test = q{A:()|(b)+|(c d)*|(e f g)?|(h i|j k);};
#my $test = q{A:z ()| z (b)+| z (c d)*| z (e f g)?| z (h i|j k (l m| n)+);};
#my $test = q{A:b c;};

#warn rebuild(parse($test));
#
#die Dump ( parse($test) );

=pod

A : b | c d | e f g ;  =>
---
- alternation:
    - concatenation:
        - name: b
    - concatenation:
        - name: c
        - name: d
    - concatenation:
        - name: e
        - name: f
        - name: g
  name: A

=cut
