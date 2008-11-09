use warnings;
use strict;
use Test::More tests => 6;
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
  my $final = simplify(Utils::join_rules(parse($str)));
  $debug and $debug == 1 and defined($final) and do
    {
    warn qq{q{$str}: }.Dump($final)
    };
  ok( defined($final), qq{valid parse of q{$str}} );
  is_deeply( $final, $layout, qq{conforming parse of q{$str}} );
  }

# }}}

# {{{ _simplify_rule($rule)
sub _simplify_rule
  {
  my ( $rule ) = @_;
  my @new_rules;

  for my $alternative ( @{$rule->{alternative}} )
    {
    for my $concatenation ( @{$alternative->{concatenation}} )
      {
      next unless $concatenation->{modifier};
die "Found modifier on rule '$rule->{name}'\n";
      }
    }

  return @new_rules;
  }

# }}}

# {{{ simplify($rules)
sub simplify
  {
  my ( $rules ) = @_;
  my @new_rules;

  for my $rule ( @$rules )
    {
    push @new_rules, _simplify_rule($rule);
    }
  if ( @new_rules )
    {
    push @$rules, @new_rules;
    push @$rules, { name => 'LAMBDA' }
    }

  return $rules;
  }

# }}}

# {{{ Simplify A:'foo'?;
run_test
  (
  q{A:'foo'?;},
    [{
    name => 'A',
    alternative =>
      [
      { concatenation => [{ name => '_A_alt_1_term_1' }] }
      ]
    },
    {
    name => '_A_alt_1_term_1',
    alternative =>
      [
      { concatenation => [{ name => 'LAMBDA' }] },
      { concatenation => [{ name => q{'foo'} }] },
      ]
    },
    {
    name => 'LAMBDA',
    }], 0
  );

# }}}

=pod

A : 'modifier'?
  ;

=>

A : _A_alt_1_term_1 ;
_A_alt_1_term_1
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
