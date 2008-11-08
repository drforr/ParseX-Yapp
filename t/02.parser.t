use Test::More tests => 86;

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
  # Basic identifier types, just in case.
  q[a] => 0,
  q[''] => 0,
  q[<a>] => 0,

  q[a:] => 0, # Rule and ':'

  q[a:;] => 1, # Lambda
  q[a:
;] => 1, # Lambda
  q[a<>:;] => 0, # Empty lambda macro
  q[a<b>:;] => 1, # Lambda macro
  q[a<b,c>:;] => 1, # Lambda macro with multiple parameters.

  # Comments
  q[#
a:;] => 1,
  q[#
# foo
a:;] => 1,
  q[a:#;] => 0,
  q[a:;#] => 1,
  q[a:;#:] => 1,

  q[a:'#';] => 1,
  q[a:'modifier';] => 1,
  q[a:'/**/';] => 1,
  q[a:/*'*/';] => 0,
  q[a:/*'*/'a';] => 1,
  q[a:'/*';] => 1,
  q[a:'*/';] => 1,

  # Multiline comments
  q[a /* : blah ; */] => 0,
  q[a /* : blah */ ;] => 0,
  q[a /* : */ blah ;] => 0,

  q[a:'/*'*/;] => 0,

  q[a:{};] => 1,
  q[a:{;] => 0,
  q[a:};] => 0,
  q[a:{{};] => 0,
  q[a:}{};] => 0,
  q[a:%prec NULL;] => 1,
  q[a:%prec NULL{};] => 1,
  q[a:{}%prec NULL;] => 0,
  q[a:|%prec NULL|{}|%prec NULL{};] => 1, # All prec/codeblock variants

  q[a:'a';] => 1,
  q[a:'a'b;] => 1,

  # Parenthesis tests
  q[a:(;] => 0,
  q[a:);] => 0,
  q[a:();] => 1,
  q[a:(a);] => 1,
  q[a:(b a);] => 1,
  q[a:(b|a);] => 1,

  # Make sure precedences are *only* at the end of a top-level alternation.
  q[a:(b|a %prec NULL);] => 0,
  q[a:(%prec NULLb|a %prec NULL);] => 0,
  q[a:()();] => 1,
  q[a:(());] => 1,
  q[a:(a());] => 1,
  q[a:(a(b)c)d;] => 1,

  q[a:() %prec NULL;] => 1,
  q[a:() | %prec NULL;] => 1,
  q[a:() %prec NULL | %prec NULL;] => 1,
  q[a:() | b %prec NULL;] => 1,

  q[a:%prec NULL();] => 0,

  # Modifiers
  q[a:+;] => 0,
  q[a:'a'+;] => 1,
  q[A:'modifier'+;] => 1,
  q[a:+'a';] => 0, # No prefix modifiers
  q[a:'a'+*;] => 0, # No repetition of modifiers
  q[a: b 'a'+;] => 1,
  q[a:()+;] => 1,
  q[a:()()+;] => 1,
  q[a:()*()+;] => 1,

  q[a:<foo>;] => 1,
  q[a:<'foo'>;] => 1,
  q[a<b>:a;] => 1,
  q[a<'b'>:a;] => 1,
  q[a<b>:<a>;] => 1,
  q[a<b>:<a>+;] => 1,

  q[csl<foo> : '(' <foo> ( ',' <foo> )* ')' ;] => 1,
  q[decimal : DECIMAL a<precision,scale>? ;] => 1,
  q[term:factor|term'*'factor|term'/'factor%precNEG;] => 1,
  q[a<b>:<a>+;
] => 1,
  q[a<b>:
<a>+;
] => 1,
  q[a<b>:
<a>+
;] => 1,
  q[a<b>:
<a>
+;] => 1,
  q[COBOL-character-type:
 ( CHARACTER SET IS? character-set-specification)?
 (PIC|PICTURE) IS? ( 'X' ('(' length ')')?)+;
] => 1,

  q[foo #XXX blah
:bar;] => 1,
  q[foo : bar ;#XXX] => 1,
  q[foo : 'modifier' ;
] => 1,
  q[
foo : 'modifier' ;
] => 1,
  q[
foo : 'modifier'
 ;
] => 1,
  q[
foo :
 'modifier' ;
] => 1,
  q[
foo
 : 'modifier' ;
] => 1,
  q[
foo
 : 'modifier'
 ;
] => 1,
  q[ foo
 : 'modifier'
 ;
] => 1,
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
