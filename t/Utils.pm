package Utils;

use warnings;
use strict;
use Carp;

=head2 join_rules($rules)

=cut

# {{{ join_rules($rules)
sub join_rules
  {
  my ( $rules ) = @_;
  my @names;
  my %reconstructed;

# {{{ Collect the rule names in order of usage for later reconstruction
  for my $rule ( @$rules )
    {
    my $rule_name = $rule->{name};
    next if grep { $_ eq $rule_name } @names;
    push @names, $rule_name;
    }

# }}}

  for my $rule ( @$rules )
    {
    push @{$reconstructed{ $rule->{name} }},
      @{$rule->{alternative}};
    }

  return [ map { { name => $_, alternative => $reconstructed{$_} } } @names ]
  }

# }}}

=head2 term

=cut

# {{{ term($term)
sub term
  {
  my ( $term ) = @_;
  my $text;
  $text = $term->{alternative} ?
    q{(} . alternative($term->{alternative}) . q{)} :
    $term->{name};

  $text .= $term->{modifier} if $term->{modifier};
  return $text;
  }

# }}}

=head2 concatenation

=cut

# {{{ concatenation($concatenation)
sub concatenation
  {
  my ( $concatenation ) = @_;
  return join q{ }, map { term($_) } @$concatenation;
  }

# }}}

=head2 alternative

=cut

# {{{ alternative($alternative)
sub alternative
  {
  my ( $alternative ) = @_;
  return join qq{ | }, map
    {
    my $text = concatenation($_->{concatenation});
    $text .= " $_->{codeblock}"
      if $_->{codeblock};
    $text;
    }
  @$alternative;
  }

# }}}

=head2 rule

=cut

# {{{ rule($rule)
sub rule
  {
  my ( $rule ) = @_;
  my $alternative = alternative($rule->{alternative});
  return "$rule->{name} : $alternative ;";
  }

# }}}

=head2 rules

=cut

# {{{ rules($rules)
sub rules
  {
  my ( $rules ) = @_;
  return join qq{\n}, map { rule($_) } @$rules;
  }

# }}}

=head2 _make_name

=cut

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

=head2 _ques

=cut

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

=head2 _star

=cut

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
      {
      concatenation => [{ name => $rule_name }, { name => $term_name }],
      codeblock => q{{ push @{$_[1]}, $_[2]; $_[1] }}
      },
    ]
  }

# }}}

=head2 _plus

=cut

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

=head2 _create_rule

=cut

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
    $new_rule->{alternative} = Utils::__ques($term_name);
    }
  elsif ( $modifier eq '*' )
    {
    $new_rule->{alternative} = Utils::__star($term_name,$rule_name);
    }
  elsif ( $modifier eq '+' )
    {
    $new_rule->{alternative} = Utils::__plus($term_name,$rule_name);
    }
  else
    {
    die "Unknown modifier name! This shouldn't happen!";
    }
  return $new_rule;
  }

# }}}

=head2 _simplify_rule

=cut

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
        Utils::_make_name($rule_name,$i+1,$j+1,$modifier);

      push @new_rules, Utils::_create_rule($rule_name,$term_name,$modifier);
      $concatenation->{name} = $rule_name;
      }
    }

  return @new_rules;
  }

# }}}

=head2 simplify

=cut

# {{{ simplify($rules)
sub simplify
  {
  my ( $rules ) = @_;
  my @new_rules;

  for my $rule ( @$rules )
    {
    push @new_rules, Utils::_simplify_rule($rule);
    }
  if ( @new_rules )
    {
    push @$rules, @new_rules;
    push @$rules, { name => 'LAMBDA' }
    }

  return $rules;
  }

# }}}

1; # Magic true value required at end of module
__END__

=head1 NAME

Utils - Utilities for the test suite

=head1 VERSION

This document describes the Utils suite version 0.0.1

=head1 SYNOPSIS

    use Utils;

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
