package Params::Smart;

use 5.006;
use strict;
use warnings; # ::register __PACKAGE__;

use Carp;

require Exporter;

our @ISA    = qw( Exporter );
our @EXPORT = qw( Params );

our $VERSION = '0.02';

use constant TYPO_THRESHOLD => 1;

sub new {
  my $class = shift;
  my $self  = {
    names => { },
    order => [ ],
  };

  my $index = 0;
 SLURP: while (my $param = shift) {
    $param =~ /^([\?\+\*]+)?(\w+)(\=.+)?/;
    my $mod  = $1 || "";
    my $name = $2;
    my $def  = substr($3,1) if (defined $3);

    unless (defined $name) {
      croak "malformed parameter $param";
    }
    if ($name =~ /^\_\w+/) {
      croak "parameter $name cannot begin with an underscore";
    }

    if (($mod =~ /\?/) && ($mod =~ /\+/)) {
      croak "parameter $name cannot be both required and optional";
    }
    elsif (exists $self->{names}->{$name}) {
      croak "parameter $name already specified";
    }
    else {
      my $info = {
        name     => $name,
        default  => $def,
        required => ((($mod !~ /\?/) && ($mod =~ /\+/)) || 0),
	slurp    => (($mod =~ /\*/) || 0),
      };
      $self->{order}->[$index] = $info;
      $self->{names}->{$name}  = $index;
      if ($info->{slurp}) {
	croak "no parameters can follow a slurp" if (@_);
	last SLURP;
      }
      if ($index && $info->{required} && (!$self->{order}->[-2]->{required})) {
	croak "a required parameter cannot follow an optional parameter";
      }
    }
    $index++;
  }

  bless $self, $class;
  return $self;
}

sub Params {
  return __PACKAGE__->new(@_);
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
      if (exists $self->{names}->{$n}) {
	$vals{$n} = $_[$i+1];
      } else {
	push @unknown, $n;
	if (@unknown > TYPO_THRESHOLD) {
	  $named = 0;
	  %vals = ( );
	  last;
	}
      }
      $i += 2;
    }

    if ($named && @unknown) {
      croak "unrecognized paramaters: @unknown";
    }
  }

  unless ($named) {
    my $i = 0;
    while ($i < @_) {
      unless (defined $self->{order}->[$i]) {
	croak "too many arguments";
      }
      if ($self->{order}->[$i]->{slurp}) {
	$vals{ $self->{order}->[$i]->{name} } = [ @_[$i..$#_] ];
	last;
      } else {
	$vals{ $self->{order}->[$i]->{name} } = $_[$i];
      }
      $i++;
    }
  }

  # validation stage

  foreach my $i (@{ $self->{order} }) {
    unless (exists($vals{$i->{name}})) {
      $vals{$i->{name}} = $i->{default};
    }
    if ($i->{required} && !exists($vals{$i->{name}})) {
      croak "required parameter not defined: $i->{name}";
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
    %args = Params(qw( +foo +bar ?bo ?baz ))->args(@_);

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

By default, parameters are assumed to be optional. (You may insert a
question mark before the name, C<?name> to emphasize that it is
optional for anyone reading the code.)

If a plus sign is added before the name, C<+name> then it will be
considered a required argument.  No required argument can follow an
optional argument.

If an asterisk is specified, the parameter will slurp all remaining
arguments into a list reference.

The resulting hash contains appropriate values.

It may also contain additional keys which begin with an underscore.
These are internal/diagnostic values.

Because Perl5 treats hashes as lists, this module attempts to interpret
the arguments as a hash of named parameters first.  If one hash key 
does not match, it will assume there is a typo and return an error.
If more do not match, it will assume these are positional parameters
instead.  The downside is that if your positional parameters coincidentally
match parameter names, you will have some frustrating bugs.  In such cases
you can check the C<_named> parameter.

=head1 CAVEATS

I<This is an experimental module, and the interface may change.> More
likely additional features will be added.

=head1 SEE ALSO

  Params::Validate
  Perl6::Subs

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
