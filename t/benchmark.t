# This is primarily here as a very rough benchmark, but it also has some
# value as part of the test suite since it's checking that various large
# random arrays are sorted into the same order as CORE::sort(). 

use strict;
use warnings;

use Sort::Bucket qw(inplace_bucket_sort);
use Test::More;
use Time::HiRes;

our @timings;

my @array = map { "" . rand()*1_000_000 } 1 .. 1_000_000;

compare_sorts([@array[0..10_000]], "10k decimals");
compare_sorts([@array[0..100_000]], "100k decimals");
compare_sorts([@array[0..200_000]], "200k decimals");
compare_sorts([@array[0..500_000]], "500k decimals");
compare_sorts(\@array, "1M decimals");

@array = map {pack 'NN', rand()*1_000_000, rand()*1_000_000 } 1 .. 1_000_000;

compare_sorts([@array[0..10_000]], "10k binary");
compare_sorts([@array[0..100_000]], "100k binary");
compare_sorts([@array[0..200_000]], "200k binary");
compare_sorts([@array[0..500_000]], "500k binary");
compare_sorts(\@array, "1M binary");

diag "
  Benchmark  | CORE::sort() | Sort::Bucket |   Ratio\n" . join("\n", @timings);

done_testing;

sub compare_sorts {
    my ($array, $name, $bits) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my @a = @$array;
    my $perl_took = timeit(sub{ @a = sort @a });
    my @perl_sorted = @a;

    @a = @$array;
    my $bucket_took = timeit(sub{
        inplace_bucket_sort(@a, $bits||0);
    });

    foreach my $i (0 .. $#perl_sorted) {
        unless ($a[$i] eq $perl_sorted[$i]) {
            ok 0, "$name disorder at elt $i";
            return;
        }
    }
    ok 1, "$name sorted order same as perl";

    push @timings, sprintf "%13s|%13.4gs|%13.4gs|%10.4g",
                 $name, $perl_took, $bucket_took, $perl_took/$bucket_took;
}

sub timeit {
    my $code = shift;

    my $start = Time::HiRes::time();
    $code->();
    my $end = Time::HiRes::time();

    return $end - $start;
}

