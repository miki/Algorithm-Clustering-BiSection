package Algorithm::Clustering::BiSection;
use strict;
use warnings;
use Algorithm::Clustering::BiSection::Item;
use Algorithm::Clustering::BiSection::Cluster;
use List::PriorityQueue;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors($_) for qw();

our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( {@_} );
    return $self;
}

sub read_file {
    my $self      = shift;
    my $file_name = shift;
    my $cluster   = Algorithm::Clustering::BiSection::Cluster->new;
    open( my $fh, "<", $file_name );
    my $n = 0;
    while (<$fh>) {
        chomp $_;
        my @f      = split( "\t", $_ );
        my $label  = shift @f;
        my %vector = @f;
        my $item   = Algorithm::Clustering::BiSection::Item->new(
            label  => $label,
            vector => \%vector,
        );
        $cluster->add_item($item);
    }
    close($fh);
    return $cluster;
}

sub bisection {
    my $self    = shift;
    my $cluster = shift;
    my $limit   = shift || 1.5;

    my $queue = List::PriorityQueue->new;

    # まず最初にクラスタを分割する
    my $sectioned = $cluster->section;

    # gainを計算しセットする
    my $gain = $cluster->sectioned_gain;

    # とりあえず突っ込む（gainは逆数にする)
    $queue->insert( $cluster, 1 / $gain );

    while ( @{ $queue->{queue} } > 0 ) {

        ## queueからpopする前にgainの値を調べ、リミットを下回っていたら終了
        my $prios = $queue->{prios}->{ $queue->{queue}->[0] };
        my $gain = 1 / $prios if $prios;
        print "gain:", $gain, "\n";
        last if ( $limit && $gain < $limit ) || !$gain;

        # pop
        my $cluster = $queue->pop;

        # クラスタのアイテム数が２未満になったら終了
        last if $cluster->item_num < 2;

        # 分割済みのクラスタを取得
        my $sectioned = $cluster->sectioned_clusters;
        for ( 0 .. 1 ) {

            # アイテム数が２未満にならスキップ
            next if $sectioned->[$_]->item_num < 2;

            # クラスタを分割
            my $new_sectioned = $sectioned->[$_]->section;

            # gainを計算
            my $gain = $sectioned->[$_]->sectioned_gain;

            # とりあえず突っ込む（gainは逆数にする)
            $queue->insert( $sectioned->[$_], 1 / $gain ) if $gain;
        }

    }

    while ( my $cluster = $queue->pop ) {
        while ( my ( $idx, $item ) = each %{ $cluster->{items} } ) {
            print $item->{label}, "\n";
        }
        print "-" x 100, "\n";
    }
}

1;
__END__

=head1 NAME

Algorithm::Clustering::BiSection -

=head1 SYNOPSIS

  use Algorithm::Clustering::BiSection;

=head1 DESCRIPTION

Algorithm::Clustering::BiSection is

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
