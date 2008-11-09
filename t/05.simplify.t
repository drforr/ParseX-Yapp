use warnings;
use strict;
use Test::More tests => 2;

BEGIN
  {
  use Parse::Yapp;
  use lib './t';
  use_ok( 'ParseX::Yapp' );
  use_ok( 'Utils' );
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

# {{{ join_rules($rules)
sub join_rules
  {
  my ( $rules ) = @_;
  my %reconstructed;

  for my $rule ( @$rules )
    {
    my $rule_name = $rule->{name};
    push @{$reconstructed{$rule_name}{alternation}},
      @{$rule->{alternation}};
    }
  return \%reconstructed;
  }

# }}}

die Utils::rules(parse(q{A:a;B:b+;}));

#use YAML; die Dump(join_rules(parse(q{A:a;A:b|c;A:d;})));

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

#ok( $str eq rules(parse(<<'_EOF_')), qq{q{$str}} );
use YAML; die Dump(parse(<<'_EOF_'));
A : ( (foo) b*)+
  | 'modifier'*
  ;
_EOF_

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
