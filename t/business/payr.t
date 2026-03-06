#!perl

use strict;
use warnings;

use Test::Most;
use Test::Warnings;

use_ok( 'Business::Payr' );

isa_ok(
    my $Payr = Business::Payr->new(
        api_token   => 'test-server-api-token',
        api_host    => 'sandbox-api.mypayr.co.uk',
        iframe_host => 'sandbox.mypayr.co.uk',
    ),
    'Business::Payr'
);

is( $Payr->api_token,   'test-server-api-token',      '->api_token' );
is( $Payr->api_host,    'sandbox-api.mypayr.co.uk',   '->api_host' );
is( $Payr->iframe_host, 'sandbox.mypayr.co.uk',       '->iframe_host' );

subtest 'default hosts' => sub {

    isa_ok(
        my $Prod = Business::Payr->new( api_token => 'prod-token' ),
        'Business::Payr',
    );

    is( $Prod->api_host,    'api.mypayr.co.uk', '->api_host defaults to production' );
    is( $Prod->iframe_host, 'mypayr.co.uk',     '->iframe_host defaults to production' );
};

subtest '->onboard_user (single user)' => sub {

    no warnings qw/ once redefine /;
    local *Business::Payr::Request::api_post = sub {
        return { message => 'Users onboarded successfully' };
    };

    ok(
        $Payr->onboard_user( _single_user_args() ),
        '->onboard_user returns true on success'
    );
};

subtest '->onboard_user (batch)' => sub {

    no warnings qw/ once redefine /;
    local *Business::Payr::Request::api_post = sub {
        return { message => 'Users onboarded successfully' };
    };

    ok(
        $Payr->onboard_user( [ _single_user_args(), _single_user_args() ] ),
        '->onboard_user returns true on batch success'
    );
};

subtest '->create_payment_session' => sub {

    no warnings qw/ once redefine /;
    local *Business::Payr::Request::api_post = sub {
        return {
            url => 'https://sandbox.mypayr.co.uk/third-party?token=abc123&session_id=def456',
        };
    };

    isa_ok(
        my $Session = $Payr->create_payment_session( '[email protected]' ),
        'Business::Payr::PaymentSession',
    );

    is(
        $Session->url,
        'https://sandbox.mypayr.co.uk/third-party?token=abc123&session_id=def456',
        '->url set correctly on PaymentSession'
    );

    like(
        $Session->iframe_html,
        qr{<iframe\s+src="https://sandbox\.mypayr\.co\.uk/third-party\?token=abc123&session_id=def456"},
        '->iframe_html contains the session URL'
    );

    like(
        $Session->iframe_html,
        qr{width="100%"},
        '->iframe_html has default width'
    );

    like(
        $Session->iframe_html,
        qr{height="700"},
        '->iframe_html has default height'
    );

    like(
        $Session->iframe_html( width => '80%', height => 900 ),
        qr{width="80%"\s+height="900"},
        '->iframe_html respects custom width and height'
    );

    like(
        $Session->iframe_html,
        qr{allow="payment"},
        '->iframe_html includes allow="payment"'
    );
};

subtest '->rotate_token' => sub {

    no warnings qw/ once redefine /;
    local *Business::Payr::Request::api_post = sub {
        return {
            token            => 'a1b2c3d4e5f6new-token',
            old_token_expiry => '2024-01-22T14:30:00Z',
        };
    };

    my $rotation = $Payr->rotate_token;

    is( ref $rotation, 'HASH', '->rotate_token returns a hash ref' );
    is( $rotation->{token},            'a1b2c3d4e5f6new-token', '->token set correctly' );
    is( $rotation->{old_token_expiry}, '2024-01-22T14:30:00Z',  '->old_token_expiry set correctly' );
};

# --- Helper data builders ---

sub _single_user_args {
    return {
        user_id       => 12345,
        email         => '[email protected]',
        first_name    => 'John',
        last_name     => 'Smith',
        phone_number  => '+447900123456',
        date_of_birth => '2000-03-15',
        tenant        => [ _tenant_args() ],
        kyc           => _kyc_args(),
    };
}

sub _tenant_args {
    return {
        post_code                    => 'E1 6AN',
        address_1                    => 'Flat 4, 123 Student Hall',
        city                         => 'London',
        country                      => 'United Kingdom',
        is_primary                   => \1,
        start_rent_date              => '2024-09-01',
        end_rent_date                => '2025-06-30',
        rent_due_day                 => 1,
        amount                       => '850.00',
        frequency                    => 'every_1_month',
        is_active                    => \1,
        payment_reference            => 'STU-2024-12345',
        recipient_bank_sort_code     => '20-00-00',
        recipient_bank_account_number => '55779911',
        recipient_bank_account_name  => 'University Housing Ltd',
        agreement                    => 'https://storage.example.com/agreements/stu_12345.pdf',
    };
}

sub _kyc_args {
    return {
        pii_front => 'https://storage.example.com/kyc/12345_passport_front.jpg',
        pii_back  => undef,
        photo     => 'https://storage.example.com/kyc/12345_selfie.jpg',
        status    => 'pending',
    };
}

done_testing();

# vim: ts=4:sw=4:et
