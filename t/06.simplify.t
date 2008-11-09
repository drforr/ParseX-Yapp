use warnings;
use strict;
use Test::More tests => 4;
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

# {{{ _make_name($rule_name,$cur_alternative,$cur_concatenation,$modifier);
my %modifier_map =
  (
  '?' => 'ques',
  '*' => 'star',
  '+' => 'plus',
  );
sub _make_name
  {
  my ( $rule_name, $cur_alternative, $cur_concatenation, $modifier ) = @_;
  my $mod = $modifier_map{$modifier};
  return "_${rule_name}_alt_${cur_alternative}_term_${cur_concatenation}_$mod";
  }

# }}}

# {{{ _create_rule($rule_name,$term_name,$modifier)
sub _create_rule
  {
  my ( $rule_name, $term_name, $modifier ) = @_;
  my $new_rule =
    {
    name => $rule_name,
    };

  if ( $modifier eq '?' )
    {
    $new_rule->{alternative} =
      [
      { concatenation => [{ name => 'LAMBDA' }] },
      { concatenation => [{ name => $term_name }] },
      ];
    }
  elsif ( $modifier eq '*' )
    {
    $new_rule->{alternative} =
      [
      { concatenation => [{ name => 'LAMBDA' }] },
      { concatenation => [{ name => $term_name }] },
      { concatenation => [{ name => $rule_name }, { name => $term_name }] },
      ];
    }
  elsif ( $modifier eq '+' )
    {
    $new_rule->{alternative} =
      [
      { concatenation => [{ name => $term_name }] },
      { concatenation => [{ name => $rule_name }, { name => $term_name }] },
      ];
    }
  else
    {
    die "Unknown modifier name! This shouldn't happen!";
    }
  return $new_rule;
  }

# }}}

# {{{ _simplify_rule($rule)
sub _simplify_rule
  {
  my ( $rule ) = @_;
  my $rule_name = $rule->{name};
  my @new_rules;

  my $cur_alternative = 0;
  for my $alternative ( @{$rule->{alternative}} )
    {
    $cur_alternative++;
    my $cur_concatenation = 0;
    for my $concatenation ( @{$alternative->{concatenation}} )
      {
      $cur_concatenation++;
      next unless $concatenation->{modifier};

      my $term_name = $concatenation->{name};
      my $modifier = $concatenation->{modifier};
      delete $concatenation->{modifier};
#use YAML; die Dump($concatenation);

      my $rule_name =
        _make_name($rule_name,$cur_alternative,$cur_concatenation,$modifier);

      push @new_rules, _create_rule($rule_name,$term_name,$modifier);
      $concatenation->{name} = $rule_name;
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
      { concatenation => [{ name => '_A_alt_1_term_1_ques' }] }
      ]
    },
    {
    name => '_A_alt_1_term_1_ques',
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
