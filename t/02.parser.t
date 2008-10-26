use Test::More tests => 62;

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
  # Failing tests
  q[A] => 0,
  q[_A] => 0,
  q[0] => 0,
  q[A:] => 0,

  # Null rule
  q[A:;] => 1,
  q[0A:;] => 0,
  q[A+:;] => 0,
  q[A-:;] => 1,
  q[Ab:;] => 1,
  q[Ab-:;] => 1,
  q[Ab-c:;] => 1,
  q[Ab_c:;] => 1,

  q[AB_c:{};] => 1, # Null rules can have codeblocks associated with them
  q[AB_c:%prec NULL;] => 1, # Null rules can have precedences... weird, huh?

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

# {{{ Test loop
for ( my $i = 0; $i < @tests; $i+=2 )
  {
  my ( $name, $yn ) = @tests[$i,$i+1];
  if ( $yn == 1 )
    {
    my $tree = parse($name);
    ok( defined($tree), qq{valid q{$name}} );
    }
  else
    {
    eval { parse($name) };
    ok( defined($error), qq{invalid q{$name}} );
    }
  }

# }}}
