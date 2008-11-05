use Test::More tests => 17;

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
