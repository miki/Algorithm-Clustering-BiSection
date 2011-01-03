package Algorithm::Clustering::BiSection::Vector;
use strict;
use vars qw( @EXPORT_OK );
use warnings;
use base qw(Exporter);

@EXPORT_OK = qw( unit_length cosine_similarity composite norm );

sub unit_length {
    my $vec  = shift;
    my $norm = norm($vec);
    while ( my ( $key, $value ) = each %$vec ) {
        $vec->{$key} = $value / $norm;
    }
}

sub cosine_similarity {
    my ( $vector_1, $vector_2 ) = @_;
    my $inner_product = 0.0;
    map {
        if ( $vector_2->{$_} )
        {
            $inner_product += $vector_1->{$_} * $vector_2->{$_};
        }
    } keys %{$vector_1};

    my $norm_1 = 0.0;
    map { $norm_1 += $_**2 } values %{$vector_1};
    $norm_1 = sqrt($norm_1);

    my $norm_2 = 0.0;
    map { $norm_2 += $_**2 } values %{$vector_2};
    $norm_2 = sqrt($norm_2);

    return ( $norm_1 && $norm_2 )
        ? $inner_product / ( $norm_1 * $norm_2 )
        : 0.0;
}

sub composite {
    my @vec = @_;
    my %comp;
    for (@vec) {
        while ( my ( $key, $value ) = each %$_ ) {
            $comp{$key} += $value;
        }
    }
    return \%comp;
}

sub norm {
    my $vec = shift;
    my $norm;
    for ( values %$vec ) {
        $norm += $_**2 if $_;
    }
    sqrt($norm);
}

1;
