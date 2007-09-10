# Tests for RandomNumbers.info site

use strict;
use warnings;

use Test::More;

my $ua;
eval {
    require LWP::UserAgent;
    $ua = LWP::UserAgent->new('timeout' => 5, 'env_proxy' => 1);
};
if ($@) {
    plan skip_all => 'LWP::UserAgent not available';
}
eval {
    my $req = HTTP::Request->new('GET' => 'http://www.randomnumbers.info/cgibin/wqrng.cgi?limit=255&amount=4');
    my $res = $ua->request($req);
    die if ! $res->is_success();
    my (@bytes) = $res->content =~ / ([\d]+)/g;
    die if (@bytes < 4);
};
if ($@) {
    plan skip_all => 'Seed from randomnumbers.info not available';
} else {
    plan tests => 90;
}

my @WARN;
BEGIN {
    # Warning signal handler
    $SIG{__WARN__} = sub { push(@WARN, @_); };

    use_ok('Math::Random::MT::Auto', qw(rand irand get_seed), 'rn_info');
}
can_ok('main', qw(rand irand get_seed));

# Check for warnings
if (@WARN) {
    @WARN = grep { $_ !~ /Partial seed/ } @WARN;
    if (@WARN) {
        diag('Seed warnings: ' . join(' | ', @WARN));
    }
} else {
    ok(@WARN, 'No short seed error');
    diag('seed: ' . scalar(@{get_seed()}));
}
undef(@WARN);

my ($rn, @rn);

# Test rand()
eval { $rn = rand(); };
ok(! $@,                    'rand() died: ' . $@);
ok(defined($rn),            'Got a random number');
ok(Scalar::Util::looks_like_number($rn),  'Is a number: ' . $rn);
ok($rn >= 0.0 && $rn < 1.0, 'In range: ' . $rn);

# Test several values from irand()
for my $ii (0 .. 9) {
    eval { $rn[$ii] = irand(); };
    ok(! $@,                        'irand() died: ' . $@);
    ok(defined($rn[$ii]),           'Got a random number');
    ok(Scalar::Util::looks_like_number($rn[$ii]), 'Is a number: ' . $rn[$ii]);
    ok(int($rn[$ii]) == $rn[$ii],   'Integer: ' . $rn[$ii]);
    for my $jj (0 .. $ii-1) {
        ok($rn[$jj] != $rn[$ii],    'Randomized');
    }
}

# EOF
