use Test::More tests => 11;

BEGIN
  {
  use Parse::Yapp;
  use YAML;
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
      concatenation => [{ name => 'a' }]
      }]
    }]
  );

run_test
  (
  q{A:(a);},
    [{
    name => 'A',
    alternation =>
      [{
      concatenation =>
        [{
        alternation =>
          [{
          concatenation => [{ name => 'a' }]
          }]
        }]
      }]
    }]
  );

run_test
  (
  q{A:a+;},
    [{
    name => 'A',
    alternation =>
      [{
      concatenation => [{ name => 'a', modifier => '+' }]
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

run_test
  (
  q{A:a|b;},
    [
      {
      name => 'A',
      alternation =>
        [
        { concatenation => [{ name => 'a' }] },
        { concatenation => [{ name => 'b' }] }
        ]
      }
    ], 0
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
