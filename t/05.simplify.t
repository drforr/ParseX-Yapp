use Test::More tests => 1;

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

# {{{ run_test($str,$layout[,$debug])
sub run_test
  {
  my ( $str, $layout, $debug ) = @_;
  my $final = parse($str);
  $debug and $debug == 1 and defined($final) and do
    {
    warn qq{q{$str}: }.Dump($final)
    };
  ok( defined($final), qq{valid parse of q{$str}} );
  is_deeply( $final, $layout, qq{conforming parse of q{$str}} );
  }

# }}}

# {{{ term($term)
sub term
  {
  my ( $term ) = @_;
  my $text;
  $text = $term->{alternation} ?
    q{(} . alternation($term->{alternation}) . q{)} :
    $term->{name};

  $text .= $term->{modifier} if $term->{modifier};
  return $text;
  }

# }}}

# {{{ concatenation($concatenation)
sub concatenation
  {
  my ( $concatenation ) = @_;
  return join q{ }, map { term($_) } @$concatenation;
  }

# }}}

# {{{ alternation($alternation)
sub alternation
  {
  my ( $alternation ) = @_;
  return join qq{ | }, map { concatenation($_->{concatenation}) } @$alternation;
  }

# }}}

# {{{ rule($rule)
sub rule
  {
  my ( $rule ) = @_;
  my $alternation = alternation($rule->{alternation});
  return "$rule->{name} : $alternation ;";
  }

# }}}

# {{{ rules($rules)
sub rules
  {
  my ( $rules ) = @_;
  return join qq{\n}, map { rule($_) } @$rules;
  }

# }}}

=pod

A : 'modifier'?
  ;

=>

A : _gensym_0x12345 ;
_gensym_0x12345
  : LAMBDA
  | 'modifier'
  ;

------

A : 'modifier'*
  ;

A : _gensym_0x12345
  ;
_gensym_0x12345
  : LAMBDA
  | 'modifier'
  | _gensym_0x12345 'modifier'
  ; 

------

A : 'modifier'+
  ;

=>

A : _gensym_0x12345
  ;
_gensym_0x12345
  : 'modifier'
  | _gensym_0x12345 'modifier'
  ;

=cut

=pod

# {{{ A:a;
run_test
  (
  q{A:a;},
    [{
    name => 'A',
    alternation =>
      [{
      concatenation => [{ name => 'a' }]
      }]
    }], 0
  );

# }}}

# {{{ A:(a);
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
    }], 0
  );

# }}}

# {{{ A:a+;
run_test
  (
  q{A:a+;},
    [{
    name => 'A',
    alternation =>
      [{
      concatenation => [{ name => 'a', modifier => '+' }]
      }]
    }], 0
  );

# }}}

# {{{ A:(a+);
run_test
  (
  q{A:(a+);},
    [{
    name => 'A',
    alternation =>
      [{
      concatenation =>
        [{
        alternation =>
          [{
          concatenation => [{ name => 'a', modifier => '+' }]
          }]
        }]
      }]
    }], 0
  );

# }}}

# {{{ A:(a)+;
run_test
  (
  q{A:(a)+;},
    [{
    name => 'A',
    alternation =>
      [{
      concatenation =>
        [{
        modifier => '+', 
        alternation =>
          [{
          concatenation => [{ name => 'a' }]
          }]
        }]
      }]
    }], 0
  );

# }}}

# {{{ A:a b;
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
    }], 0
  );

# }}}

# {{{ A:a|b;
run_test
  (
  q{A:a|b;},
    [{
    name => 'A',
    alternation =>
      [
      { concatenation => [{ name => 'a' }] },
      { concatenation => [{ name => 'b' }] }
      ]
    }], 0
  );

# }}}

# {{{ A:(a)+|b;
run_test
  (
  q{A:(a)+|b;},
    [{
    name => 'A',
    alternation =>
      [{
      concatenation =>
        [{
        modifier => '+', 
        alternation =>
          [{
          concatenation => [{ name => 'a' }]
          }]
        }]
      },{ concatenation => [{ name => 'b' }] }]
    }], 0
  );

# }}}

=cut
