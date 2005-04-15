#!/usr/bin/perl

use strict;

use Test::More tests => 9;

use_ok('Params::Smart');

{
  my %Expected = (
    foo => 1,
    bar => 2,
    bo  => 3,
  );

  my %Vals = Params(qw( foo bar bo ))->args( %Expected );
  ok(delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "named parameters");

  %Vals = Params(qw( foo bar bo ))->args( 1, 2, 3 );
  ok(!delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "positional parameters");
}

{
  my %Expected = (
    foo => 1,
    bar => [ 2, 3 ],
  );

  my %Vals = Params(qw( foo *bar ))->args( %Expected );
  ok(delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "named parameters (slurp)");

  %Vals = Params(qw( foo *bar ))->args( 1, 2, 3 );
  ok(!delete $Vals{_named});
  ok(eq_hash( \%Expected, \%Vals ), "positional parameters (slurp)");
}
