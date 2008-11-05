use Test::More tests => 2;

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

sub concatenation
  {
  my ( $concatenation ) = @_;
  return join q{ }, map { term($_) } @$concatenation;
  }

sub alternation
  {
  my ( $alternation ) = @_;
  return join qq{ | }, map { concatenation($_->{concatenation}) } @$alternation;
  }

sub rule
  {
  my ( $rule ) = @_;
  my $alternation = alternation($rule->{alternation});
  return "$rule->{name} : $alternation ;";
  }

sub rules
  {
  my ( $rules ) = @_;
  return join qq{\n}, map { rule($_) } @$rules;
  }

#
# This seems to be a pretty common thing to do:
#
# list : item { [ $_[1] ] }
#      | list item  { push @{$_[1]}, $_[2] }
#      ;
# 
# Why not encapsulate it?
#

my $str = q{A : ((a) b*)+ | b* ;};
ok( $str eq rules(parse($str)), qq{q{$str}} );
