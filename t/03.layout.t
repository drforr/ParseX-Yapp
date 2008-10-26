use Test::More tests => 1;

BEGIN
  {
  use Parse::Yapp;
  use_ok( 'ParseX::Yapp' );
  }

my $error = undef;

# {{{ stuff
my $yapp = Parse::Yapp->new( input => $ParseX::Yapp::grammar );
eval $yapp->Output( classname => 'ParseX' );
my $parser = ParseX->new;

sub parse
  {
  my ( $text ) = @_;
  $error = undef;
  $parser->YYData->{INPUT} = $text;
  return $parser->YYParse
    (
    yylex => \&ParseX::Yapp::Lexer,
    yyerror => sub { $error = 1 } 
    );
  }

# }}}

# {{{ Tests
my @tests =
  (
  # Null rule
  q[A:;] => 1,
  q[A-:;] => 1,
  q[Ab:;] => 1,
  q[Ab-:;] => 1,
  q[Ab-c:;] => 1,
  q[Ab_c:;] => 1,

  q[AB_c:{};] => 1, # Null rules can have codeblocks associated with them

  # Basic literals
  q[Ab_c:'a';] => 1,
  q[Ab_c:'a;] => 0,
  q[Ab_c:a';] => 0,
  q[Ab_c:'a'?;] => 1,
  q[Ab_c:'a'*;] => 1,
  q[Ab_c:'a'+;] => 1,
  q[Ab_c:a;] => 1,
  q[Ab_c:a?;] => 1,
  q[Ab_c:a*;] => 1,
  q[Ab_c:a+;] => 1,

  # Empty parens, some random nestings.
  q[A:();] => 1,
  q[A:()();] => 1,
  q[A:(());] => 1,
  q[A:()(());] => 1,

  # Empty parens with terms outside
  q[A:() a;] => 1,
  q[A:()() a;] => 1,
  q[A:(()) a;] => 1,
  q[A:()(()) a;] => 1,

  q[A:a();] => 1,
  q[A:a()();] => 1,
  q[A:a(());] => 1,
  q[A:a()(());] => 1,

  q[A:a()+;] => 1,
  q[A:a()?()*;] => 1,
  q[A:a(()+)*;] => 1,
  q[A:a()(()?)?;] => 1,

  # Invalid nested parens
  q[A:(;] => 0,
  q[A:);] => 0,
  q[A:());] => 0,
  q[A:(();] => 0,

  # Single-element parens, randomly nested
  q[A:('a');] => 1,
  q[A:('a')('a');] => 1,
  q[A:(('a'));] => 1,
  q[A:('a'('a'));] => 1,
  q[A:('a'('a')'b');] => 1,
  q[A:()(());] => 1,

  q[A: a (b) c d (e f (g h i)) ghi ;] => 1,

  # Alternations
  q[A: a (b) | c d | (e | f (g h | i)) ghi ;] => 1,

  # Mass codeblock test
  q[A: a {} (b? {}) | c* {} {} d | (e | f (g h | i)) ghi ;] => 1,

  # Mass codeblock test with precedence
  q[A: a {} (b? {}) %prec blah | c* {} {} d %prec blah | (e | f (g h | i)) ghi %prec blah ;] => 1,
  <<'_EOS_' => 1,
A: a {} (b? {}) %prec blah
 | c* {} {} d %prec blah
 | (e | f (g h | i)) ghi %prec blah
 ;

_Bling : a;
_EOS_

  # Bletch, gotta check comments, I suppose.
  q[A: foo #bar;] => 0, # Swallow semicolon
  q[A: foo bar;#] => 1, # Trailing comments shouldn't matter
  q[A: foo 'foo #bar';#] => 1, # Comments in strings
  q[A: foo /*bar;*/] => 0, # Swallow semicolon
  q[A: foo /*bar;*/;] => 1, # Comment with semicolon afterward
  q[A: foo 'bar';/*bar;*/] => 1, # Swallow semicolon
  );

# }}}

sub run_test
  {
  my ( $str, $layout, $debug ) = @_;
  my $final = parse($str);
$debug == 1 and defined($final) and do { use YAML; warn qq{q{$str}: }.Dump($final) };
  ok( defined($final), qq{valid parse of q{$str}} );
  is_deeply( $layout, $final, qq{conforming parse of q{$str}} );
  }

#run_test(<<'_EOS_'
#A: a {} (b? {}) %prec blah
# | c* {} {} d %prec blah
# | (e | f (g h | i)) ghi %prec blah
# ;
#
#_Bling : a;
#_EOS_
#, [], 1 );
