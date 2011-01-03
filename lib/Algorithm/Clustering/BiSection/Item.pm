package Algorithm::Clustering::BiSection::Item;
use strict;
use warnings;
use Algorithm::Clustering::BiSection::Vector qw(cosine_similarity unit_length);
use base qw( Class::Accessor::Fast Class::Data::Inheritable);

__PACKAGE__->mk_accessors($_) for qw( label vector normalize_flag );
__PACKAGE__->mk_classdata( ids => {} );

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(
        {   label          => undef,
            vector         => {},
            normalize_flag => 0,
            @_
        }
    );
    $self->normalize if keys %{ $self->vector };
    return $self;
}

sub similarity {
    my $self        = shift;
    my $target_item = shift;
    unless ( $self->normalize_flag ) {
        $self->normalize;
    }
    my $similarity = cosine_similarity( $self->vector, $target_item->vector );
}

sub normalize {
    my $self = shift;

    for my $key ( keys %{ $self->vector } ) {
        my $id = $self->_str2id($key);
        $self->vector->{$id} = delete $self->vector->{$key};
    }

    unit_length( $self->vector );

    $self->normalize_flag(1);
}

sub _str2id {
    my $self = shift;
    my $str  = shift;
    my $hash = __PACKAGE__->ids;
    $hash->{$str} || sub {
        $hash->{$str} = int( keys %$hash ) + 1;
        }
        ->();
}
1;