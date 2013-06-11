package Iota::Statistics::Quartile;

use Moose;
use Statistics::Descriptive;

sub iterate {
    my ($self, $rows) = @_;

    my @numbers = map { $_->{num} } @{$rows};


    my $stat = Statistics::Descriptive::Full->new();
    $stat->add_data(@numbers);


    my $q1 = $stat->quantile(1);
    my $q2 = $stat->quantile(2);
    my $q3 = $stat->quantile(3);

    my $low = $q1 - (( $q3 - $q1 ) * 1.5);
    my $top = $q3 + (( $q3 - $q1 ) * 1.5);

use DDP; p $q1;p $q2;p $q3;
p$top; p $low;
    foreach my $item (@{$rows}){

        if ($item->{num} < $q1){
            $item->{qt} = 0;
        }elsif ($item->{num} < $q2){
            $item->{qt} = 1;
        }elsif ($item->{num} < $q3){
            $item->{qt} = 2;
        }else{
            $item->{qt} = 3;
        }

    }

}



1;
