#!/usr/bin/perl

use strict;

use Test::More tests => 35;

# TODO - test errors in defining params templates, and errors in invalid args

use_ok('Params::Smart');

{
  my %Expected = (
    foo => 1,
    bar => 2,
    bo  => 3,
  );

  my @params = qw(?foo ?bar ?bo );

  my %Vals = Params(@params)->args( %Expected );
  ok(delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "named parameters");

  %Vals = Params(@params)->args( 1, 2, 3 );
  ok(!delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "positional parameters");

  delete $Expected{bo};
  %Vals = Params(@params)->args( 1, 2 );
  ok(!delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "positional parameters");

  delete $Expected{bar};
  %Vals = Params(@params)->args( 1 );
  ok(!delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "positional parameters");

  delete $Expected{foo};
  %Vals = Params(@params)->args();
  ok(delete $Vals{_named}); # defaults to true if no args
  ok(eq_hash( \%Expected, \%Vals ), "positional parameters");
}

{
  my %Expected = (
    foo => 1,
    bar => 2,
    bo  => 3,
  );

  my @params = qw(foo bar bo );

  my %Vals = Params(@params)->args( %Expected );
  ok(delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "named parameters");

  %Vals = Params(@params)->args( 1, 2, 3 );
  ok(!delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "positional parameters");
}

{
  my %Expected = (
    foo => 1,
    bar => 2,
    bo  => 3,
  );

  my @params = qw(foo ?bar ?bo );

  my %Vals = Params(@params)->args( %Expected );
  ok(delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "named parameters");

  %Vals = Params(@params)->args( 1, 2, 3 );
  ok(!delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "positional parameters");

  delete $Expected{bo};

  %Vals = Params(@params)->args( %Expected );
  ok(delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "named parameters");

  %Vals = Params(@params)->args( 1, 2 );
  ok(!delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "positional parameters");

  delete $Expected{bar};

  %Vals = Params(@params)->args( %Expected );
  ok(delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "named parameters");

  %Vals = Params(@params)->args( 1 );
  ok(!delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "positional parameters");

}

{
  my %Expected = (
    foo => 1,
    bar => [ 2, 3 ],
  );

  my @params = qw(foo *bar );

  my %Vals = Params(@params)->args( %Expected );
  ok(delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "named parameters (slurp)");

  %Vals = Params(@params)->args( 1, 2, 3 );
  ok(!delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "positional parameters (slurp)");
}

{
  my %Expected = (
    foo => 1,
    bar => 2,
  );

  my @params = qw( bar +?foo );

  my %Vals = Params(@params)->args( -foo => 1, -bar => 2, );
  ok(delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "named parameters (slurp)");

  %Vals = Params(@params)->args( 2 );
  ok(!delete $Vals{_named});
  ok(eq_hash( { bar => 2 }, \%Vals ), "positional parameters (slurp)");
}
