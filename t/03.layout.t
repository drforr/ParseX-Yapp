use warnings;
use strict;
use Test::More tests => 43;
use YAML;

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

# {{{ A:;
run_test
  (
  q{LAMBDA:;},
    [
      {
      name => 'LAMBDA'
      }
    ], 0
  );

# }}}

# {{{ A:{};
run_test
  (
  q{A:{};},
    [
      {
      name => 'A',
      alternative =>
        [
          {
          concatenation => undef,
          codeblock => q{{}},
          }
        ]
      }
    ], 0
  );

# }}}

# {{{ A:a;
run_test
  (
  q{A:a;},
    [
      {
      name => 'A',
      alternative =>
        [
          {
          concatenation => [ { name => 'a' } ]
          }
        ]
      }
    ], 0
  );

# }}}

# {{{ A:(a);
run_test
  (
  q{A:(a);},
    [
      {
      name => 'A',
      alternative =>
        [
          {
          concatenation =>
            [
              {
              alternative =>
                [
                  {
                  concatenation => [ { name => 'a' } ]
                  }
                ]
              }
            ]
          }
        ]
      }
    ], 0
  );

# }}}

# {{{ A:a+;
run_test
  (
  q{A:a+;},
    [
      {
      name => 'A',
      alternative =>
        [
          {
          concatenation => [ { name => 'a', modifier => '+' } ]
          }
        ]
      }
    ], 0
  );

# }}}

# {{{ A:a+{};
run_test
  (
  q{A:a+{};},
    [
      {
      name => 'A',
      alternative =>
        [
          {
          concatenation => [ { name => 'a', modifier => '+' } ],
          codeblock => q{{}}
          }
        ]
      }
    ], 0
  );

# }}}

# {{{ A:(a+);
run_test
  (
  q{A:(a+);},
    [
      {
      name => 'A',
      alternative =>
        [
          {
          concatenation =>
            [
              {
              alternative =>
                [
                  {
                  concatenation => [ { name => 'a', modifier => '+' } ]
                  }
                ]
              }
            ]
          }
        ]
      }
    ], 0
  );

# }}}

# {{{ A:(a)+;
run_test
  (
  q{A:(a)+;},
    [
      {
      name => 'A',
      alternative =>
        [
          {
          concatenation =>
            [
              {
              modifier => '+', 
              alternative =>
                [
                  {
                  concatenation => [ { name => 'a' } ]
                  }
                ]
              }
            ]
          }
        ]
      }
    ], 0
  );

# }}}

# {{{ A:a b;
run_test
  (
  q{A:a b;},
    [
      {
      name => 'A',
      alternative =>
        [
          {
          concatenation =>
            [
              { name => 'a' },
              { name => 'b' }
            ]
          }
        ]
      }
    ], 0
  );

# }}}

# {{{ A:a|b;
run_test
  (
  q{A:a|b;},
    [
      {
      name => 'A',
      alternative =>
        [
          { concatenation => [ { name => 'a' } ] },
          { concatenation => [ { name => 'b' } ] }
        ]
      }
    ], 0
  );

# }}}

# {{{ A:(a)+|b;
run_test
  (
  q{A:(a)+|b;},
    [
      {
      name => 'A',
      alternative =>
        [
          {
          concatenation =>
            [
              {
              modifier => '+', 
              alternative =>
                [
                  {
                  concatenation => [ { name => 'a' } ]
                  }
                ]
              }
            ]
          },
          { concatenation => [ { name => 'b' } ] }
        ]
      }
    ], 0
  );

# }}}

# {{{ A:(a)+|b; #2
run_test
  (
  q{A:(a)+|b
;},
    [
      {
      name => 'A',
      alternative =>
        [
          {
          concatenation =>
            [
              {
              modifier => '+', 
              alternative =>
                [
                  {
                  concatenation => [ { name => 'a' } ]
                  }
                ]
              }
            ]
          },
          { concatenation => [ { name => 'b' } ] }
        ]
      }
    ], 0
  );

# }}}

# {{{ A:(a)+|b; #3
run_test
  (
  q{A:(a)+|
b;},
    [
      {
      name => 'A',
      alternative =>
        [
          {
          concatenation =>
            [
              {
              modifier => '+', 
              alternative =>
                [
                  {
                  concatenation => [ { name => 'a' } ]
                  }
                ]
              }
            ]
          },
          { concatenation => [ { name => 'b' } ] }
        ]
      }
    ], 0
  );

# }}}

# {{{ A:(a)+|b; #4
run_test
  (
  q{A:(a)+
|b;},
    [
      {
      name => 'A',
      alternative =>
        [
          {
          concatenation =>
            [
              {
              modifier => '+', 
              alternative =>
                [
                  {
                  concatenation => [ { name => 'a' } ]
                  }
                ]
              }
            ]
          },
          { concatenation => [ { name => 'b' } ] }
        ]
      }
    ], 0
  );

# }}}

# {{{ A:(a)+|b; #5
run_test
  (
  q{A:(a)
+|b;},
    [
      {
      name => 'A',
      alternative =>
        [
          {
          concatenation =>
            [
              {
              modifier => '+', 
              alternative =>
                [
                  {
                  concatenation => [ { name => 'a' } ]
                  }
                ]
              }
            ]
          },
          { concatenation => [ { name => 'b' } ] }
        ]
      }
    ], 0
  );

# }}}

# {{{ A:(a)+|b; #6
run_test
  (
  q{A:(a
)+|b;},
    [
      {
      name => 'A',
      alternative =>
        [
          {
          concatenation =>
            [
              {
              modifier => '+', 
              alternative =>
                [
                  {
                  concatenation => [ { name => 'a' } ]
                  }
                ]
              }
            ]
          },
          { concatenation => [ { name => 'b' } ] }
        ]
      }
    ], 0
  );

# }}}

# {{{ A:(a)+|b; #7
run_test
  (
  q{A:(
a)+|b;},
    [
      {
      name => 'A',
      alternative =>
        [
          {
          concatenation =>
            [
              {
              modifier => '+', 
              alternative =>
                [
                  {
                  concatenation => [ { name => 'a' } ]
                  }
                ]
              }
            ]
          },
          { concatenation => [ { name => 'b' } ] }
        ]
      }
    ], 0
  );

# }}}

# {{{ A:(a)+|b; #8
run_test
  (
  q{A:
(a)+|b;},
    [
      {
      name => 'A',
      alternative =>
        [
          {
          concatenation =>
            [
              {
              modifier => '+', 
              alternative =>
                [
                  {
                  concatenation => [ { name => 'a' } ]
                  }
                ]
              }
            ]
          },
          { concatenation => [ { name => 'b' } ] }
        ]
      }
    ], 0
  );

# }}}

# {{{ A:(a)+|b; #9
run_test
  (
  q{A
:(a)+|b;},
    [
      {
      name => 'A',
      alternative =>
        [
          {
          concatenation =>
            [
              {
              modifier => '+', 
              alternative =>
                [
                  {
                  concatenation => [ { name => 'a' } ]
                  }
                ]
              }
            ]
          },
          { concatenation => [ { name => 'b' } ] }
        ]
      }
    ], 0
  );

# }}}

# {{{ A:(a)+|b; #10
run_test
  (
  q{
A:(a)+|b;},
    [
      {
      name => 'A',
      alternative =>
        [
          {
          concatenation =>
            [
              {
              modifier => '+', 
              alternative =>
                [
                  {
                  concatenation => [ { name => 'a' } ]
                  }
                ]
              }
            ]
          },
          { concatenation => [ { name => 'b' } ] }
        ]
      }
    ], 0
  );

# }}}

# {{{ A:(a)+|b; #11
run_test
  (
  q{
A : ( a ) +
  | b
  ;
},
    [
      {
      name => 'A',
      alternative =>
        [
          {
          concatenation =>
            [
              {
              modifier => '+', 
              alternative =>
                [
                  {
                  concatenation => [ { name => 'a' } ]
                  }
                ]
              }
            ]
          },
          {
          concatenation => [ { name => 'b' } ] 
          }
        ]
      }
    ], 0
  );

# }}}
