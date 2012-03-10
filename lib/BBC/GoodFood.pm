=head1 NAME

BBC::GoodFood

=head1 DESCRIPTION

A web scraper for the L<http://www.bbcgoodfood.com> website.

=head1 AUTHOR

Steven Humphrey

=head1 METHODS

=over

=cut

package BBC::GoodFood;

use v5.10;
use strict;
use warnings;

use namespace::autoclean;
use URI;
use Web::Scraper;

use constant SEARCH_URL => 'http://www.bbcgoodfood.com/search.do';

=item BBC::GoodFood->search($search_term, $count)

Returns a list of BBC recipes returned by searching for $search_term.
Returns $count results. $count defaults to 10. (default bbcgoodfood result). 

=cut
sub search {
    my ( $self, $search_term, $count ) = @_;

    my $offset = 0;
    $count ||= 10;

    my @results;
    while($offset < $count) {
        my $result = $self->_search($search_term, $offset);
        last if !$result || !$result->{'recipes'};
        push @results, @{$result->{'recipes'}};

        $offset += 10;
    }
    return @results;
}

## Offset search
sub _search {
    my ( $self, $search, $offset ) = @_;

    my $uri = URI->new(SEARCH_URL);
    $uri->query_form(keywords => $search);
    if ( $offset ) {
        $uri->query_form('pager.offset' => $offset);
    }
    my $scraper = scraper {
        process "ul.recipeList > li", "recipes[]" => scraper {
            process 'div.image > a', 'href' => '@href',
            process 'div.image > img', 'image' => scraper {
                process '.', 'src'    => '@src',
                process '.', 'height' => '@height',
                process '.', 'width'  => '@width',
            },
            process 'div.description > h4 > a', 'title' => 'TEXT',
            process 'span.author', 'author' => scraper {
                process '.', 'name' => 'TEXT',
                process 'span', 'link' => '@href',
            },
            process 'span.icons > img', 'icons[]' => scraper {
                process '.', 'title'  => '@title',
                process '.', 'src'    => '@src',
                process '.', 'height' => '@height',
                process '.', 'width'  => '@width',
            },
            process 'dl > dd', 'time'       => 'TEXT',
            process 'dl + p', 'description' => 'TEXT',
            process 'p.ratings', 'ratings' => scraper {
                #process '.', 'count'  => 'TEXT', # can't get the inline text this way
                process 'img', 'stars'  => '@alt',
            },
            process 'p.difficulty', 'difficulty' => 'TEXT',
        }
    };

    my $res = $scraper->scrape($uri);
    return $res;
}


=item BBC::GoodFood->article($URI)

Returns data for the article on at $URI

=cut
sub article {
    my ( $class, $uri ) = @_;

    my $scraper = scraper {
        process 'p.summary', 'summary' => 'TEXT',
        process 'div#userDetail > div.image', 'uploaded_by' => scraper {
            process 'img', 'thumb'   => scraper {
                process '.', 'src' => '@src',
                process '.', 'width'  => '@width',
                process '.', 'height' => '@height',
            },
            process 'a', 'link' => '@href',
            process 'a', 'name' => 'TEXT',
        },
        process 'p.ratings', 'ratings' => scraper {
            process 'span.count', 'count' => 'TEXT',
            process 'span.rating', 'stars' => 'TEXT',
        },
        process 'p#recipeTested', 'tested' => 'TEXT',
        process 'div#serving > img', 'difficulty' => '@alt',
        process 'div#serving span.yield', 'yield' => 'TEXT',
        process '#printSidebar > div#prep > p', 'times[]' => 'TEXT',
        process '#printSidebar > div#otherInfo > img', 'extras_icons[]' => '@alt',
        process '#printSidebar > div#otherInfo > p', 'extras_texts[]' => 'TEXT',
        process 'div#method > ol > li', 'instructions[]' => 'TEXT',
        process 'div#try', 'try[]' => scraper {
            process 'p', 'texts[]' => 'TEXT',
        },
        process 'div#nutrition > p', 'nutrition[]' => 'TEXT',
        process 'span.published', 'published' => 'TEXT',
        process 'div#ingredients > ul > li', 'ingredients[]' => scraper {
            process '.', 'text' => 'TEXT',
            process 'a', 'link' => '@href',
        },
    };

    my $res = $scraper->scrape($uri);

    ## Clean up a few things
    if ( $res ) {
        my @extras;
        foreach my $key (qw/extras_icons extras_texts/) {
            push @extras, @{delete $res->{$key}} if $res->{$key};
        }
        $res->{'extras'} = \@extras;
        $res->{'source'} = $uri;
    }

    return $res;
}

=back

=cut

1;

