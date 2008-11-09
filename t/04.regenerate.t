use warnings;
use strict;
use Test::More tests => 8;

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

#
# This seems to be a pretty common thing to do:
#
# list : item { [ $_[1] ] }
#      | list item  { push @{$_[1]}, $_[2] }
#      ;
# 
# Why not encapsulate it?
#

{
my $str = q{A :  ;};
ok( $str eq Utils::rules(parse($str)), qq{q{$str}} );

ok( $str eq Utils::rules(parse(<<'_EOF_')), qq{q{$str}} );
A : 
  ;
_EOF_
}

{
my $str = q{A : ((a) b*)+ | b* ;};
ok( $str eq Utils::rules(parse($str)), qq{q{$str}} );

ok( $str eq Utils::rules(parse(<<'_EOF_')), qq{q{$str}} );
A : ( (a) b*)+
  | b*
  ;
_EOF_
}

{
my $str = q{A : ((foo) b*)+ | 'modifier'* ;};
ok( $str eq Utils::rules(parse($str)), qq{q{$str}} );

ok( $str eq Utils::rules(parse(<<'_EOF_')), qq{q{$str}} );
A : ( (foo) b*)+
  | 'modifier'*
  ;
_EOF_
}
