package Iota::Statistics::Frequency;

use Moose;
use Statistics::Descriptive;

sub iterate {
    my ($self, $rows) = @_;

    my @numbers = map { $_->{num} } @{$rows};

    my $stat = Statistics::Descriptive::Full->new();
    $stat->add_data(@numbers);

    my %f = $stat->frequency_distribution(5);

    my @order = sort {$a <=> $b} keys %f;
    foreach my $r (@{$rows}){
        for my $i ( 0.. 4 ){
            if ( $r->{num} <= $order[$i] ){
                $r->{i} = $i;
                last;
            }
        }
    }

    return $rows;
}



1;
