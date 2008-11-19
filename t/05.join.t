use warnings;
use strict;
use Test::More tests => 8;
use YAML;

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
  my $final = Utils::join_rules(parse($str));
  $debug and $debug == 1 and defined($final) and do
    {
    warn qq{q{$str}: }.Dump($final)
    };
  ok( defined($final), qq{valid parse of q{$str}} );
  is_deeply( $final, $layout, qq{conforming parse of q{$str}} );
  }

# }}}

# {{{ Test the joining of rules
run_test
  (
  q{A:a;A:b;},
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

# {{{ Test more than one rule outbound
run_test
  (
  q{C:d;A:a;A:b;B:c;},
    [
      {
      name => 'C',
      alternative => 
        [
          { concatenation => [ { name => 'd' } ] }
        ],
      },
      {
      name => 'A',
      alternative =>
        [
          { concatenation => [ { name => 'a' } ] },
          { concatenation => [ { name => 'b' } ] }
        ]
      },
      {
      name => 'B',
      alternative =>
       [
         { concatenation => [ { name => 'c' } ] }
       ],
      }
    ], 0
  );

# }}}

# {{{ Test more than one rule outbound
run_test
  (
  q{C:d;A:a{1++};A:b{++2};B:c;},
    [
      {
      name => 'C',
      alternative => 
        [
          { concatenation => [ { name => 'd' } ] }
        ],
      },
      {
      name => 'A',
      alternative =>
        [
          { concatenation => [ { name => 'a' } ], codeblock => q{{1++}} },
          { concatenation => [ { name => 'b' } ], codeblock => q{{++2}} }
        ]
      },
      {
      name => 'B',
      alternative =>
       [
         { concatenation => [ { name => 'c' } ] }
       ],
      }
    ], 0
  );

# }}}
