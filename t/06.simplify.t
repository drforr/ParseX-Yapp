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
  my $final = Utils::simplify(Utils::join_rules(parse($str)));
  $debug and $debug == 1 and defined($final) and do
    {
    warn qq{q{$str}: }.Dump($final)
    };
  ok( defined($final), qq{valid parse of q{$str}} );
  is_deeply( $final, $layout, qq{conforming parse of q{$str}} );
  }

# }}}

# {{{ Simplify A:'foo'?;
run_test
  (
  q{A:'foo'?;},
    [
      {
      name => 'A',
      alternative =>
        [
          { concatenation => [ { name => q{_A_alt_1_term_1_ques} } ] }
        ]
      },
      {
      name => '_A_alt_1_term_1_ques',
      alternative =>
        [
          { concatenation => [ { name => q{LAMBDA} } ] },
          { concatenation => [ { name => q{'foo'} } ] },
        ]
      },
      { name => q{LAMBDA} }
    ], 0
  );

# }}}

# {{{ Simplify A:'foo'?{};
run_test
  (
  q{A:'foo'?{$_++};},
    [
      {
      name => 'A',
      alternative =>
        [
          {
          concatenation => [ { name => q{_A_alt_1_term_1_ques} } ],
          codeblock => q{{$_++}}
          }
        ]
      },
      {
      name => '_A_alt_1_term_1_ques',
      alternative =>
        [
          { concatenation => [ { name => q{LAMBDA} } ] },
          { concatenation => [ { name => q{'foo'} } ] },
        ]
      },
      { name => q{LAMBDA} }
    ], 0
  );

# }}}

# {{{ Simplify A:'foo'*;
run_test
  (
  q{A:'foo'*;},
    [
      {
      name => 'A',
      alternative =>
        [
          { concatenation => [ { name => q{_A_alt_1_term_1_star} } ] }
        ]
      },
      {
      name => '_A_alt_1_term_1_star',
      alternative =>
        [
          { concatenation => [ { name => q{LAMBDA} } ] },
          {
          concatenation =>
            [
              { name => q{_A_alt_1_term_1_star} },
              { name => q{'foo'} }
            ],
          codeblock => q{{ push @{$_[1]}, $_[2]; $_[1] }}
          },
        ]
      },
      { name => q{LAMBDA} }
    ], 0
  );

# }}}
