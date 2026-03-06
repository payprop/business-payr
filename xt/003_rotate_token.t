#!perl

use strict;
use warnings;

use FindBin qw/ $Bin /;
use lib $Bin;

use Test::Most;
use Test::Warnings;
use Test::Credentials;
use Business::Payr;

plan skip_all => "set PAYR_CREDENTIALS to run author tests"
    if ! $ENV{PAYR_CREDENTIALS};

my $Payr = Business::Payr->new(
    Test::Credentials->new->TO_JSON->%*,
);

isa_ok( $Payr, 'Business::Payr' );

# ---------------------------------------------------------------------------
# NOTE: This test actually rotates your sandbox API token.  After a
# successful run your PAYR_CREDENTIALS file will contain a stale token.
# Update it with the new token printed in the test output before running
# any further author tests.
#
# The old token remains valid for a grace period of 7-15 days, so existing
# integrations will not be broken immediately, but you should update your
# configuration promptly.
# ---------------------------------------------------------------------------

subtest '->rotate_token returns a hash ref with expected keys' => sub {

    my $rotation;

    lives_ok(
        sub { $rotation = $Payr->rotate_token },
        '->rotate_token lives'
    );

    ok( defined $rotation, '->rotate_token returns a defined value' );
    is( ref $rotation, 'HASH', '->rotate_token returns a hash ref' );

    ok(
        exists $rotation->{token},
        '->rotate_token result contains a "token" key'
    );

    ok(
        exists $rotation->{old_token_expiry},
        '->rotate_token result contains an "old_token_expiry" key'
    );
};

subtest 'new token is a non-empty string' => sub {

    my $rotation = $Payr->rotate_token;

    ok(
        defined $rotation->{token} && length $rotation->{token},
        '->token is a non-empty string'
    );

    isnt(
        $rotation->{token},
        $Payr->api_token,
        '->token is different from the current api_token'
    );

    note( "New token: " . $rotation->{token} );
    note( "Old token expires at: " . ( $rotation->{old_token_expiry} // 'N/A' ) );
    note( "Update your PAYR_CREDENTIALS file with the new token above." );
};

subtest 'old_token_expiry is an ISO 8601 datetime string' => sub {

    my $rotation = $Payr->rotate_token;

    my $expiry = $rotation->{old_token_expiry};

    SKIP: {
        skip 'old_token_expiry not present in response', 1
            unless defined $expiry && length $expiry;

        like(
            $expiry,
            qr/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/,
            '->old_token_expiry looks like an ISO 8601 datetime'
        );
    }
};

subtest 'new token can be used to construct a fresh Business::Payr client' => sub {

    my $rotation = $Payr->rotate_token;
    my $new_token = $rotation->{token};

    isa_ok(
        my $NewPayr = Business::Payr->new(
            api_token   => $new_token,
            api_host    => $Payr->api_host,
            iframe_host => $Payr->iframe_host,
        ),
        'Business::Payr',
        'Business::Payr constructed with new token'
    );

    is(
        $NewPayr->api_token,
        $new_token,
        'new client carries the rotated token'
    );
};

done_testing();

# vim: ts=4:sw=4:et
