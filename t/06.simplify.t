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

# {{{ __ques($term_name)
#
# A : 'modifier'?
#   ;
# 
# =>
# 
# A : _A_alt_1_term_1
#   ;
# _A_alt_1_term_1
#   : LAMBDA
#   | 'modifier'
#   ;
#
sub __ques
  {
  my ( $term_name ) = @_;
  return
    [
      { concatenation => [{ name => q{LAMBDA} }] },
      { concatenation => [{ name => $term_name }] },
    ]
  }

# }}}

#
# _blah
#  : LAMBDA
#  | 'blah' { [ $_[1] ] }
#  | _blah 'blah' { [ $_[1] ] }
#  ;
#

# {{{ __star($term_name,$rule_name)
#
# A : 'modifier'*
#   ;
# 
# =>
# 
# A : _A_alt_1_term_1
#   ;
# _A_alt_1_term_1
#   : LAMBDA
#   | _a_alt_1_term_1 'modifier'
#   ;
#
sub __star
  {
  my ( $term_name, $rule_name ) = @_;
  return
    [
      { concatenation => [{ name => q{LAMBDA} }] },
      { concatenation => [{ name => $term_name }] },
      { concatenation => [{ name => $rule_name }, { name => $term_name }] },
    ]
  }

# }}}

# {{{ __plus($term_name,$rule_name)
#
# A : 'modifier'+
#   ;
# 
# =>
# 
# A : _A_alt_1_term_1
#   ;
# _A_alt_1_term_1
#   : LAMBDA
#   | 'modifier'
#   | _a_alt_1_term_1 'modifier'
#   ;
#
sub __plus
  {
  my ( $term_name, $rule_name ) = @_;
  return
    [
      { concatenation => [{ name => $term_name }] },
      { concatenation => [{ name => $rule_name }, { name => $term_name }] },
    ]
  }

# }}}

# {{{ _create_rule($rule_name,$term_name,$modifier)
sub _create_rule
  {
  my ( $rule_name, $term_name, $modifier ) = @_;
  my $new_rule =
    {
    name => $rule_name
    };

  if ( $modifier eq '?' )
    {
    $new_rule->{alternative} = __ques($term_name);
    }
  elsif ( $modifier eq '*' )
    {
    $new_rule->{alternative} = __star($term_name,$rule_name);
    }
  elsif ( $modifier eq '+' )
    {
    $new_rule->{alternative} = __plus($term_name,$rule_name);
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

  for ( my $i = 0; $i < @{$rule->{alternative}}; $i++ )
    {
    my $alternative = $rule->{alternative}[$i];
    for ( my $j = 0; $j < @{$alternative->{concatenation}}; $j++ )
      {
      my $concatenation = $alternative->{concatenation}[$j];
      next unless $concatenation->{modifier};

      my $term_name = $concatenation->{name};
      my $modifier = $concatenation->{modifier};
      delete $concatenation->{modifier};

      my $rule_name =
        _make_name($rule_name,$i+1,$j+1,$modifier);

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
    [
      {
      name => 'A',
      alternative =>
        [
          { concatenation => [{ name => q{_A_alt_1_term_1_ques} }] }
        ]
      },
      {
      name => '_A_alt_1_term_1_ques',
      alternative =>
        [
          { concatenation => [{ name => q{LAMBDA} }] },
          { concatenation => [{ name => q{'foo'} }] },
        ]
      },
      {
      name => q{LAMBDA},
      }
    ], 0
  );

# }}}
