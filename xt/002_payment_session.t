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
# The user must have been onboarded before a payment session can be created.
# Run xt/001_onboard.t first to ensure test user 99001 exists in the sandbox.
# ---------------------------------------------------------------------------

my $TEST_EMAIL = 'test.user.99001@example.com';

subtest 'create_payment_session returns a PaymentSession object' => sub {

    isa_ok(
        my $Session = $Payr->create_payment_session( $TEST_EMAIL ),
        'Business::Payr::PaymentSession',
        '->create_payment_session'
    );

    ok(
        defined $Session->url && length $Session->url,
        '->url is a non-empty string'
    );

    like(
        $Session->url,
        qr{\Ahttps://},
        '->url starts with https://'
    );

    like(
        $Session->url,
        qr{[?&]token=},
        '->url contains a token query parameter'
    );

    like(
        $Session->url,
        qr{[?&]session_id=},
        '->url contains a session_id query parameter'
    );

    note( "Session URL: " . $Session->url );
};

subtest '->iframe_html generates valid HTML' => sub {

    my $Session = $Payr->create_payment_session( $TEST_EMAIL );

    my $html = $Session->iframe_html;

    ok( defined $html && length $html, '->iframe_html returns a non-empty string' );

    like( $html, qr{<iframe\b},     '->iframe_html contains an <iframe> tag'   );
    like( $html, qr{</iframe>},     '->iframe_html closes the <iframe> tag'     );
    like( $html, qr{src="},         '->iframe_html has a src attribute'         );
    like( $html, qr{width="100%"},  '->iframe_html has default width of 100%'   );
    like( $html, qr{height="700"},  '->iframe_html has default height of 700'   );
    like( $html, qr{allow="payment"}, '->iframe_html sets allow="payment"'      );

    note( "iframe HTML:\n$html" );
};

subtest '->iframe_html with custom dimensions' => sub {

    my $Session = $Payr->create_payment_session( $TEST_EMAIL );

    my $html = $Session->iframe_html( width => '90%', height => 850 );

    like( $html, qr{width="90%"},  '->iframe_html custom width applied'  );
    like( $html, qr{height="850"}, '->iframe_html custom height applied' );
};

subtest 'create_payment_session fails for unknown user' => sub {

    throws_ok(
        sub {
            $Payr->create_payment_session( 'nobody@nowhere.invalid' );
        },
        qr/Payr POST .* returned 400/,
        'create_payment_session throws on unknown email'
    );
};

done_testing();

# vim: ts=4:sw=4:et
