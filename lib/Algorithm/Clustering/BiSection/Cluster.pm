package Algorithm::Clustering::BiSection::Cluster;
use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
use Algorithm::Clustering::BiSection::Vector qw(norm);
use List::Util qw(shuffle);
use base qw(Class::Accessor::Fast Class::Data::Inheritable);

__PACKAGE__->mk_accessors($_) for qw(items sectioned_clusters);
__PACKAGE__->mk_classdata( ids => {} );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( {@_} );
    $self->items( {} );
    $self->sectioned_clusters( [] );
    return $self;
}

sub sectioned_gain {
    my $self = shift;

    my $gain
        = $self->sectioned_clusters->[0]->{norm_}
        + $self->sectioned_clusters->[1]->{norm_} 
        - $self->calc_norm;

    return $gain;
}

sub add_item {
    my $self = shift;
    my $item = shift;

    my $id = $self->_str2id( $item->label );
    $self->items->{$id} = $item;
    my $vector = $item->vector;
    for my $key ( keys %{$vector} ) {
        my $value = $vector->{$key};
        $self->{composite}->{$key} += $value;
    }
}

sub remove_item {
    my $self = shift;
    my $idx  = shift;
    my $item = delete $self->items->{$idx};
    for my $key ( keys %{ $item->vector } ) {
        my $value = $item->vector->{$key};
        $self->{composite}->{$key} -= $value;
    }
    return $item;
}

sub calc_norm {
    my $self = shift;
    Algorithm::Clustering::BiSection::Vector::norm( $self->{composite} );
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

sub item_num {
    my $self = shift;
    return int keys %{ $self->items };
}

sub section {
    my $self = shift;

    my $sectioned;
    for ( 0 .. 1 ) {
        my $new_cluster = __PACKAGE__->new;
        push @$sectioned, $new_cluster;
    }

    #my ( $seed_1, $seed_2 ) = $self->_seed_point_smartly();
    my ( $seed_1, $seed_2 ) = $self->_seed_point();

    my $p = 0;

    print "\t", "section start\n";
    for my $item ( values %{ $self->items } ) {
        my $sim_1 = $item->similarity($seed_1);
        my $sim_2 = $item->similarity($seed_2);
        my $n     = 0;
        $n = 0           if $sim_1 > $sim_2;
        $n = 1           if $sim_1 < $sim_2;
        $n = int rand(2) if $sim_1 == $sim_2;
        $sectioned->[$n]->add_item($item);
    }


    $self->_refine_clusters($sectioned);

    $self->sectioned_clusters($sectioned);

    return $sectioned;
}

sub _refine_clusters {
    my $self      = shift;
    my $sectioned = shift;

    for ( 0 .. 1 ) {
        $sectioned->[$_]->{norm_} = $sectioned->[$_]->calc_norm;
    }

    my $n = 0;
    for ( 1 .. 10 ) {

        my $move_count = 0;

        my @array;
        for my $i ( 0 .. 1 ) {
            for my $j ( keys %{ $sectioned->[$i]->items } ) {
                push @array, { sectioned => $i, items => $j };
            }
        }
        @array = shuffle @array;
        #print "ARRAY: ", int @array, "\n";
        for (@array) {

            #print "\t\t", "should_be?", $move_count, "\n";
            my $from = $_->{sectioned};
            my $to   = $from ? 0 : 1;
            my $idx  = $_->{items};

            if ( $self->_should_be_moved( $sectioned, $from, $to, $idx ) ) {
                my $item = $sectioned->[$from]->remove_item($idx);
                $sectioned->[$to]->add_item($item);
                $move_count++;
            }
        }

        last if $move_count == 0;
    }
	return;
}

sub _should_be_moved {
    my $self      = shift;
    my $sectioned = shift;
    my $from      = shift;
    my $to        = shift;
    my $idx       = shift;

    my $item   = $sectioned->[$from]->{items}->{$idx};
    my $vector = $item->vector;

    my $composite_from = $sectioned->[$from]->{composite};
    my $composite_to   = $sectioned->[$to]->{composite};

    my $sum_1 = 0;
	my $sum_2 = 0;
    for my $key ( keys %$vector ) {


        my $value       = $vector->{$key};
        my $value_power = $value**2;

        # 削除される側のクラスタ
        my $value2 = $composite_from->{$key} || 0;
        $sum_1 += $value_power - 1 * 2 * $value2 * $value;

        # 追加される側のクラスタ
        $value2 = $composite_to->{$key} || 0;
        $sum_2 += $value_power + 1 * 2 * $value2 * $value;
    }

    my $norm_base_moved = $sectioned->[$from]->{norm_}**2 + $sum_1;
    $norm_base_moved = $norm_base_moved > 0 ? sqrt($norm_base_moved) : 0;

    my $norm_target_moved = $sectioned->[$to]->{norm_}**2 + $sum_2;
    $norm_target_moved
        = $norm_target_moved > 0 ? sqrt($norm_target_moved) : 0;

    my $eval
        = $norm_base_moved 
        + $norm_target_moved 
        - $sectioned->[$from]->{norm_}
        - $sectioned->[$to]->{norm_};

    if ( $eval > 0 ) {
        $sectioned->[$from]->{norm_} = $norm_base_moved;
        $sectioned->[$to]->{norm_}   = $norm_target_moved;
        return 1;
    }
    else {
        return 0;
    }
}

sub _seed_point {
    my $self  = shift;
    my $items = $self->items;

    my $idx_1 = [ sort { rand() <=> 0.5 } keys %$items ]->[0];
    my $idx_2;
    while (1) {
        $idx_2 = [ sort { rand() <=> 0.5 } keys %$items ]->[0];
        last if $idx_1 != $idx_2;
    }
    return ( $items->{$idx_1}, $items->{$idx_2} );
}

sub _seed_point_smartly {
    my $self  = shift;
    my $items = $self->items;

    my $cur_potential = 0;
    my @centers;

    # choose one random center
    my $idx_1 = [ sort { rand() <=> 0.5 } keys %$items ]->[0];
    my $random_one = $items->{$idx_1};
    push @centers, $random_one;

    my %closest_dist;
    for my $idx ( keys %{$items} ) {
        $closest_dist{$idx} = 1 - $items->{$idx}->similarity($random_one);
        $cur_potential += $closest_dist{$idx};
    }

    # choose each center
    for ( 1 .. 2 ) {
        my $randval = rand() * $cur_potential;
        my $center_id;
        for my $idx ( keys %{$items} ) {
            $center_id = $idx;
            last if $randval <= $closest_dist{$idx};
            $randval -= $closest_dist{$idx};
        }
        my $new_potential = 0;
        for my $idx ( keys %{$items} ) {
            my $dist = 1 - $items->{$idx}->similarity( $items->{$center_id} );
            $closest_dist{$idx} = $dist if $dist < $closest_dist{$idx};
            $new_potential += $closest_dist{$idx};
        }
        push @centers, $items->{$center_id};
        $cur_potential = $new_potential;
    }

    return @centers;
}

1;