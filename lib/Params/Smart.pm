package Params::Smart;

use 5.006;
use strict;
use warnings; # ::register __PACKAGE__;

use Carp;
use Memoize;

require Exporter;

our @ISA    = qw( Exporter );
our @EXPORT = qw( Params );

our $VERSION = '0.03';

# use constant TYPO_THRESHOLD => 1;

sub new {
  my $class = shift;
  my $self  = {
    names => { },
    order => [ ],
  };

  my $index = 0;
  my $last;
 SLURP: while (my $param = shift) {
    $param =~ /^([\?\+\*]+)?([\@\$\%])?(\w+)(\=.+)?/;
    my $mod  = $1 || "";
    my $type = $2;
    my $name = $3;
    my $def  = substr($4,1) if (defined $4);

    unless (defined $name) {
      croak "malformed parameter $param";
    }
    if ($name =~ /^\_\w+/) {
      croak "parameter $name cannot begin with an underscore";
    }

    if (exists $self->{names}->{$name}) {
      croak "parameter $name already specified";
    }
    else {
      my $info = {
        name      => $name,
        type      => $type,
        default   => $def,
        required  => (($mod !~ /\?/) || 0),
        name_only => (($mod =~ /\+/) || 0),
	slurp     => (($mod =~ /\*/) || 0),
      };
      push @{$self->{order}}, $name unless ($info->{name_only});
      $self->{names}->{$name}  = $info;
      if ($info->{slurp}) {
	croak "no parameters can follow a slurp" if (@_);
	last SLURP;
      }

      if ($last && $info->{required} && (!$last->{required})) {
	croak "a required parameter cannot follow an optional parameter";
      }
      $last = $info;
    }
    $index++;
  }

  bless $self, $class;
  return $self;
}

# We have the exported Params() function rather than requiring calls to
# Params::Smart->new() so that the code looks a lot cleaner.

sub Params {
  return __PACKAGE__->new(@_);
}

# Since it's a bit of work to encode the parameters, we memoize them.

BEGIN {
  memoize("Params");
}

sub args {
  my $self = shift;
  my %vals = ( );

  # $vals{_args} = [ @_ ];

  my $named = !(@_ % 2);
  if ($named) {
    my @unknown = ( );
    my $i = 0;
    while ($named && ($i < @_)) {
      my $n = $_[$i];
      $n = substr($n,1) if ($n =~ /^\-/);
      if (exists $self->{names}->{$n}) {
	$vals{$n} = $_[$i+1];
      } else {
	push @unknown, $n;
# 	if ((@unknown > TYPO_THRESHOLD) || ((TYPO_THRESHOLD*2) >= @_)) {
# 	  $named = 0;
# 	  %vals = ( );
# 	  last;
# 	}
      }
      $i += 2;
    }

    if ($named && @unknown && (keys %vals)) {
      croak "unrecognized paramaters: @unknown";
    }
    elsif ($named && @unknown) {
      $named = 0;
      %vals = ( );
    }
  }

  unless ($named) {
    my $i = 0;
    while ($i < @_) {
      unless (defined $self->{order}->[$i]) {
	croak "too many arguments";
      }
      if ($self->{names}->{$self->{order}->[$i]}->{slurp}) {
	$vals{ $self->{order}->[$i] } = [ @_[$i..$#_] ];
	last;
      } else {
	$vals{ $self->{order}->[$i] } = $_[$i];
      }
      $i++;
    }
  }

  # validation stage

  foreach my $name (keys %{ $self->{names} }) {
    my $info = $self->{names}->{$name};
    unless (exists($vals{$name})) {
      $vals{$name} = $info->{default}, if (defined $info->{default});
    }
    if ($info->{required} && !exists($vals{$name})) {
      croak "required parameter not defined: $name";
    }
  }

  $vals{_named} = $named;

  return %vals;
}


1;
__END__


=head1 NAME

Params::Smart - use both positional and named arguments in a subroutine

=head1 SYNOPSIS

  use Params::Smart;

  sub my_sub {
    %args = Params(qw( foo bar ?bo ?baz ))->args(@_);

    ...
  }

  my_sub( foo=> 1, bar=>2, bo=>3 );  # call with named arguments

  my_sub(1, 2, 3);                   # same, with positional args

=head1 DESCRIPTION

This module allows you to have subroutines which take both named
and positional arguments without having to use a changed syntax
and source filters.

Usage is as follows:

  %values = Params( @template )->( @args );

C<@template> specifies the names of parameters in the order that they
should be given in subroutine calls.  C<@args> is the list of argument
to be parsed: usually you just specify the void list C<@_>.

=over

Paramaters are required by default. To change this behavior, add the 
following symbols before the names:

=item ?

The parameter is optional, e.g. C<?name>.

=item +

The parameter must only be specified as a named parameter. Note that
it is not necessarily optional. You must explicitly state that,
e.g. C<+?name>.

=item *

The parameter "slurps" the rest of the arguments into an array reference,
e.g. C<*name>.  It is not assumed to be optional unless there is a
question-mark before it.

=back

C<%values> contains the keys of specified arguments, with their values.
It may also contain additional keys which begin with an underscore.
These are internal/diagnostic values:

=over

=item _named

True if the parameters were treated as named, false if positional.

=back

=head1 CAVEATS

I<This is an experimental module, and the interface may change.> More
likely additional features will be added.

Because Perl5 treats hashes as lists, this module attempts to interpret
the arguments as a hash of named parameters first.  If some hash keys
match, and some do not, then it assumes there has been an error. If
no keys match, then it assumes that it the arguments are positional.

In theory one can pass positional arguments where every other argument
matches a hash key, or one can pass a hash with the wrong keys (possible
if one copies/pastes code from the wrong call) and so it is treated as
a positional argument.

This is probably uncommon for most data, but subroutines should take
extra care to check if values are within allowed ranges.  There may
even be security issues if users can blindly specify data that they
know can cause this confusion.  If the application is critical
enough, then this may not be an appropriate module to use (at least
not until the ability to distinguish between lists and hashes is
improved).

To diagnose potential bugs, or to enforce named or positional calling
one can check the L</_named> parameter.

=head1 SEE ALSO

This module is similar in function to L<Getargs::Mixed> but does not
require named parameters to have an initial dash ('-').  It also has 
some additional features.

The syntax of the paramater templates is inspired by L<Perl6::Subs>,
though not necessarily compatible. (See also I<Apocalypse 6> in
L<Perl6::Bible>).

L<Params::Validate> is useful for (additional) parameter validation
beyond what this module is capable of.

=head1 AUTHOR

Robert Rothenberg <rrwo at cpan.org>

=head2 Suggestions and Bug Reporting

Feedback is always welcome.  Please use the CPAN Request Tracker at
L<http://rt.cpan.org> to submit bug reports.

=head1 LICENSE

Copyright (c) 2005 Robert Rothenberg. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
