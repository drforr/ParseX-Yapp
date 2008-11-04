package ParseX::Yapp;

use warnings;
use strict;
use Carp;
use Regexp::Common;

our $VERSION = q('0.0.3');

#
# %prec terms can't repeat in a row
# {} can occur before or after %prec, though before it's got to have a term
# technically. It's a 'fatal' which means it's lexed.
#
# Multiple {} in a row are illegal though.
#
# The grammar officially denies responsibility for:
#
# %prec NULL where NULL isn't identified.
#   It could be in the lexer.
#
# Multiple lambda transitions
#   The regenerator will either throw an error or ignore this.
#

# {{{ Grammar
our $grammar = <<'_EOF_';

%%

#
# Will eventually look like:
# rules : rule* ;
#
rules
  : LAMBDA
  | rule
  { [ $_[1] ] }
  | rules rule
  { push @{$_[1]}, $_[2]; $_[1] }
  ;

rule
  : rule_name ':' opt_alternation ';'
  { my %h = ( name => $_[1]{name} );
    $h{parameter_list} = $_[1]{parameter_list} if $_[1]{parameter_list};
    $h{alternation}    = $_[3] if $_[3];
    \%h
  }
  ;

rule_name
  : identifier
  { { name => $_[1] } }
  | identifier template_expansion_list
  { { name => $_[1], parameter_list => $_[2] } }
  ;

#
# opt_alternation could better be done as:
# opt_alternation : ( alternation ( '|' alternation )* )?
#
# Eventually:
# sep-list<sep,element> : ( element ( sep element )* )? ;
# opt_alternation : sep-list<'|',alternation> ;
#
opt_alternation
  : LAMBDA
  | alternation
  { [ $_[1] ] }
  | opt_alternation '|' alternation
  { push @{$_[1]}, $_[3]; $_[1] }
  ;

#
# This can eventually be truncated to:
# alternation : precedence? codeblock? ;
# And remove 2 rules.
#
alternation
  : opt_concatenation opt_precedence opt_codeblock
  { my %h = ( concatenation => $_[1] );
    $h{precedence} = $_[2] if $_[2];
    $h{codeblock}  = $_[3] if $_[3];
    \%h;
  }
  ;

opt_concatenation
  : LAMBDA
  | term
  { [ $_[1] ] }
  | opt_concatenation term
  { push @{$_[1]}, $_[2]; $_[1] }
  ;

term
  : element opt_modifier
  { my %h = ( name => $_[1] );
    $h{modifier} = $_[2] if $_[2];
    \%h
  }
  | '(' opt_subalternation ')' opt_modifier
  { my %h = ( alternation => $_[2] );
    $h{modifier} = $_[4] if $_[4];
    \%h
  }
  ;

opt_subalternation
  : LAMBDA
  | opt_concatenation
  { [ { concatenation => $_[1] } ] }
  | opt_subalternation '|' opt_concatenation
  { push @{$_[1]}, { concatenation => $_[3] }; $_[1] }
  ;

opt_modifier
  : LAMBDA
  | '*'
  | '+'
  | '?'
  ;

element
  : string
  | template_expansion_list
  | identifier
  ;

opt_precedence
  : LAMBDA
  | '%prec' identifier
  { $_[2] }
  ;

opt_codeblock
  : LAMBDA
  | codeblock
  ;

template_expansion_list
  : '<' expansion_list '>'
  { $_[2] }
  ;

#
# Of course, this could be:
# expansion_list : csl<identifier> ;
#
expansion_list
  : expansion
  { [ $_[1] ] }
  | expansion_list ',' expansion
  { push @{$_[1]}, $_[3]; $_[1] }
  ;

expansion
  : identifier
  | string
  ;

LAMBDA
  :
  ;

%%

_EOF_

# }}}

=head2 Lexer

=cut

# {{{ Lexer
sub Lexer
  {
  my ( $parser ) = @_;

  $parser->YYData->{INPUT} or return ( '', undef );

  # Eat whitespace and comments before getting to the lexer.
  FOO:
  for ( $parser->YYData->{INPUT} )
    {
    s( ^ [ \t\n]+ )()sx       and goto FOO;
    s( ^ $RE{comment}{C} )()x and goto FOO;
    s( ^ [#] .* ($|\n) )()mx  and goto FOO;
    }

  for ( $parser->YYData->{INPUT} )
    {
    s( ^ ([_A-Za-z][-_A-Za-z0-9]*) )()x      and return ( 'identifier', $1 );
    s( ^ ($RE{quoted}) )()x                  and return ( 'string',     $1 );
    s( ^ ($RE{balanced}{-parens=>'{}'}) )()x and return ( 'codeblock',  $1 );
    s( ^ ([%]prec) )()x                      and return ( $1, $1 );
    s( ^ (.) )()x                            and return ( $1, $1 );
    }
  }

# }}}

1; # Magic true value required at end of module
__END__

=head1 NAME

ParseX::Yapp - [One line description of module's purpose here]

=head1 VERSION

This document describes ParseX::Yapp version 0.0.1

=head1 SYNOPSIS

    use ParseX::Yapp;

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.
  
=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.

=head1 INTERFACE 

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.

=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back

=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
ParseX::Yapp requires no configuration files or environment variables.

=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.

=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.

=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-parse-bnf@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Jeffrey Goff  C<< <jgoff@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Jeffrey Goff C<< <jgoff@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
