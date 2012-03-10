#!/usr/bin/env perl

=head1 NAME

check_data.t

=head1 DESCRIPTION

Tests we scrape data correctly.

=cut

use strict;
use warnings;
use Test::More;

use constant SEARCH_TERM => 'pasta';

use_ok('URI');
use_ok('BBC::GoodFood', 'Can load module');

## Check basic usage
my @res1 = BBC::GoodFood->search(SEARCH_TERM);
is(scalar(@res1), 10, 'Can fetch 10 results');

## Check we can fetch more than 10
my @res2 = BBC::GoodFood->search(SEARCH_TERM, 20);
is(scalar(@res2), 20, 'Can fetch 20 results');

## Check the first recipe
foreach my $recipe_item (@res1) {
    is(ref($recipe_item), 'HASH', 'Recipe is what we expect');

    ## Check each field in the list
    foreach my $field (qw/href image title author time description ratings difficulty/) {
        ok(defined $recipe_item->{$field} && $recipe_item->{$field}, "Recipe has field $field");
    }

    ## Some data is ok to be empty, but in that case it shouldn't exist
    if ( $recipe_item->{icons} ) {
        isnt(scalar(keys(@{$recipe_item->{icons}})), 0, 'Don\'t have empty icons');
    }
}

## Fetch full recipe
SKIP: {
    skip 'Cannot proceed without valid recipes', 1 unless defined $res1[0];

    my $recipe_item = $res1[0];
    my $uri = URI->new($recipe_item->{'href'});
    my $article = BBC::GoodFood->article($uri);
    is(ref($article), 'HASH', "Got an article hash $uri");

    foreach my $field (qw/summary uploaded_by ratings tested difficulty yield
                          times extras instructions try nutrition published
                          ingredients/) {
        ok(defined $article &&
                   $article, "$field exists for recipe");
    }
};

done_testing();
