package Iota::Statistics::Frequency;

use Moose;
use Statistics::Descriptive;

use Statistics::Basic qw(:all nofill);

sub iterate {
    my ( $self, $rows ) = @_;


    my @numbers = map { $_->{num} } grep { defined $_->{num} } @{$rows};

    if ( scalar @numbers < 5 ) {
        $_->{i} = 5 for @{$rows};
    }
    else {

        my %seen;
        @numbers = grep{!$seen{$_}++} @numbers;

        my $stat = Statistics::Descriptive::Full->new();

        my $stddev    = stddev(@numbers);
        my $meio      = mean(@numbers);

        my (@mid);
        foreach (@numbers){
            if (!($_ - $stddev > $meio) && $_ + $stddev > $meio) {
                push @mid, $_ ;
            }
        }
        $stat->add_data(sort {$a <=> $b} @mid);

        my %f = $stat->frequency_distribution(5);
        my @order = sort { $a <=> $b } keys %f;

        foreach my $r (@$rows){
            next unless defined $r->{num};
            my $num = $r->{num};

            if ($num < $order[0]){
                $r->{i} = 0;
            }elsif ($num < $order[1]){
                $r->{i} = 1;
            }elsif ($num < $order[2]){
                $r->{i} = 2;
            }elsif ($num < $order[3]){
                $r->{i} = 3;
            }else{
                $r->{i} = 4;
            }
        }



        return $stat;
    }
    return undef;
}

1;
