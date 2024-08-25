use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";

use AWS::XRay qw/ capture /;
use t::Util qw/ reset segments /;
use Test::More;
use Time::HiRes qw / time sleep /;

subtest "auto_close=1", sub {
    reset();
    AWS::XRay->auto_close(1);

    my $seg;
    capture "myApp", sub {
      $seg = shift;
      sleep 0.1;
    };

    # the segment is closed and flushed immediately
    ok $seg->{end_time} > 0;
    my @segments = segments();
    ok @segments == 1;
    ok $segments[0]->{end_time} > 0;
};

subtest "auto_close=0", sub {
    reset();

    # It implies auto_flush=0
    AWS::XRay->auto_close(0);

    my $seg;
    capture "myApp", sub {
      $seg = shift;
      sleep 0.1;
    };

    # The segment is not closed and not flushed yet
    is $seg->{end_time}, undef;
    my @segments = segments();
    ok @segments == 0;

    # Manually close the segment
    is $seg->{end_time}, undef;
    $seg->close();
    isnt $seg->{end_time}, undef;
    @segments = segments();
    ok @segments == 1;
    ok time - $segments[0]->{end_time} < 0.1;

    sleep 0.1;

    # Manually flush the buffer
    AWS::XRay->sock->flush();
    @segments = segments();
    ok @segments == 1;
    ok time - $segments[0]->{end_time} > 0.1;
};

subtest "auto_close=0 without closing the segment", sub {
    reset();

    # It implies auto_flush=0
    AWS::XRay->auto_close(0);

    my $seg;
    capture "myApp", sub {
      $seg = shift;
      sleep 0.1;
    };

    # The segment is not closed and not flushed yet
    is $seg->{end_time}, undef;
    my @segments = segments();
    ok @segments == 0;

    # Manually flush the buffer and discard the segment
    AWS::XRay->sock->flush();
    @segments = segments();
    ok @segments == 0;
};
done_testing;
