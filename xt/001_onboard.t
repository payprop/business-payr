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

my $creds    = Test::Credentials->new;
my $use_kyc  = $creds->kyc;

my $Payr = Business::Payr->new( $creds->TO_JSON->%* );

isa_ok( $Payr, 'Business::Payr' );

my $auth_desc = $use_kyc ? 'kyc' : 'agent_id';

note( "Onboarding author tests running in '$auth_desc' mode" );

# ---------------------------------------------------------------------------
# _onboard_auth - returns the appropriate auth key/value pair for onboard_user
# depending on the "kyc" flag in the credentials file.
#
# Usage: $Payr->onboard_user({ ..., _onboard_auth() });
#
# kyc:true  -> ( kyc      => { pii_front => undef, ... } )
# kyc:false -> ( agent_id => 1 )
# ---------------------------------------------------------------------------

sub _onboard_auth {
    return $use_kyc
        ? ( kyc => {
                pii_front => undef,
                pii_back  => undef,
                photo     => undef,
                status    => 'pending',
            } )
        : ( agent_id => 1 );
}

# ---------------------------------------------------------------------------
# Single user onboarding
# ---------------------------------------------------------------------------

subtest "onboard a single user (using $auth_desc)" => sub {

    ok(
        $Payr->onboard_user({
            user_id       => 990010,
            email         => 'test.user.990010@example.com',
            first_name    => 'Test',
            last_name     => 'User',
            phone_number  => '+447900000001',
            date_of_birth => '1995-06-15',
            tenant        => [
                {
                    post_code                     => 'E1 6AN',
                    address_1                     => 'Flat 1, 1 Test Street',
                    city                          => 'London',
                    country                       => 'United Kingdom',
                    is_primary                    => \1,
                    start_rent_date               => '2024-09-01',
                    end_rent_date                 => '2025-06-30',
                    rent_due_day                  => 1,
                    amount                        => '850.00',
                    frequency                     => 'every_1_month',
                    is_active                     => \1,
                    payment_reference             => 'TST-2024-990010',
                    recipient_bank_sort_code      => '20-00-00',
                    recipient_bank_account_number => '55779911',
                    recipient_bank_account_name   => 'Test Housing Ltd',
                    agreement                     => 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
                },
            ],
            _onboard_auth(),
        }),
        "->onboard_user returns true for a single user using $auth_desc"
    );
};

# ---------------------------------------------------------------------------
# Re-onboarding the same user (idempotency) - should update mutable fields
# ---------------------------------------------------------------------------

subtest "onboard the same user again (idempotency / update, using $auth_desc)" => sub {

    ok(
        $Payr->onboard_user({
            user_id       => 990010,
            email         => 'test.user.990010@example.com',
            first_name    => 'Test',
            last_name     => 'User',
            phone_number  => '+447900000001',
            date_of_birth => '1995-06-15',
            tenant        => [
                {
                    post_code                     => 'E1 6AN',
                    address_1                     => 'Flat 1, 1 Test Street',
                    city                          => 'London',
                    country                       => 'United Kingdom',
                    is_primary                    => \1,
                    start_rent_date               => '2024-09-01',
                    # Updated end date and amount - these are the mutable fields
                    end_rent_date                 => '2025-08-31',
                    rent_due_day                  => 1,
                    amount                        => '875.00',
                    frequency                     => 'every_1_month',
                    is_active                     => \1,
                    payment_reference             => 'TST-2024-990010',
                    recipient_bank_sort_code      => '20-00-00',
                    recipient_bank_account_number => '55779911',
                    recipient_bank_account_name   => 'Test Housing Ltd',
                    agreement                     => 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
                },
            ],
            _onboard_auth(),
        }),
        "->onboard_user returns true when re-onboarding the same user using $auth_desc"
    );
};

# ---------------------------------------------------------------------------
# Onboarding a user with quarterly rent frequency
# ---------------------------------------------------------------------------

subtest "onboard a user with quarterly rent frequency (using $auth_desc)" => sub {

    ok(
        $Payr->onboard_user({
            user_id       => 99002,
            email         => 'test.user.99002@example.com',
            first_name    => 'Quarterly',
            last_name     => 'Payer',
            phone_number  => '+447900000002',
            date_of_birth => '1993-03-22',
            tenant        => [
                {
                    post_code                     => 'SW1A 1AA',
                    address_1                     => 'Flat 2, 2 Quarterly Court',
                    city                          => 'London',
                    country                       => 'United Kingdom',
                    is_primary                    => \1,
                    start_rent_date               => '2024-09-01',
                    end_rent_date                 => '2025-08-31',
                    rent_due_day                  => 1,
                    amount                        => '2550.00',
                    frequency                     => 'every_3_month',
                    is_active                     => \1,
                    payment_reference             => 'TST-2024-99002',
                    recipient_bank_sort_code      => '20-00-00',
                    recipient_bank_account_number => '55779922',
                    recipient_bank_account_name   => 'Test Housing Ltd',
                    agreement                     => 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
                },
            ],
            _onboard_auth(),
        }),
        "->onboard_user returns true for quarterly rent frequency using $auth_desc"
    );
};

# ---------------------------------------------------------------------------
# Onboarding a user with an installment schedule
# ---------------------------------------------------------------------------

subtest "onboard a user with an installment schedule (using $auth_desc)" => sub {

    ok(
        $Payr->onboard_user({
            user_id       => 99003,
            email         => 'test.user.99003@example.com',
            first_name    => 'Installment',
            last_name     => 'Scheduler',
            phone_number  => '+447900000003',
            date_of_birth => '1998-11-05',
            tenant        => [
                {
                    post_code                     => 'EC1A 1BB',
                    address_1                     => 'Room 3, 3 Instalment House',
                    city                          => 'London',
                    country                       => 'United Kingdom',
                    is_primary                    => \1,
                    start_rent_date               => '2024-09-01',
                    end_rent_date                 => '2025-06-30',
                    rent_due_day                  => 1,
                    amount                        => '750.00',
                    frequency                     => 'every_1_month',
                    is_active                     => \1,
                    payment_reference             => 'TST-2024-99003',
                    recipient_bank_sort_code      => '20-00-00',
                    recipient_bank_account_number => '55779933',
                    recipient_bank_account_name   => 'Test Housing Ltd',
                    agreement                     => 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
                },
            ],
            installments => [
                { installment_number => 1, due_date => '2025-02-01', amount => 75000 },
                { installment_number => 2, due_date => '2025-03-01', amount => 75000 },
                { installment_number => 3, due_date => '2025-04-01', amount => 75000 },
                { installment_number => 4, due_date => '2025-05-01', amount => 75000 },
            ],
            _onboard_auth(),
        }),
        "->onboard_user returns true for user with installment schedule using $auth_desc"
    );
};

# ---------------------------------------------------------------------------
# Batch onboarding
# ---------------------------------------------------------------------------

subtest "batch onboard multiple users (using $auth_desc)" => sub {

    ok(
        $Payr->onboard_user([
            {
                user_id       => 99004,
                email         => 'test.user.99004@example.com',
                first_name    => 'Batch',
                last_name     => 'UserOne',
                phone_number  => '+447900000004',
                date_of_birth => '1997-07-14',
                tenant        => [
                    {
                        post_code                     => 'N1 9GU',
                        address_1                     => 'Flat 4a, 4 Batch Road',
                        city                          => 'London',
                        country                       => 'United Kingdom',
                        is_primary                    => \1,
                        start_rent_date               => '2024-09-01',
                        end_rent_date                 => '2025-06-30',
                        rent_due_day                  => 5,
                        amount                        => '650.00',
                        frequency                     => 'every_1_month',
                        is_active                     => \1,
                        payment_reference             => 'TST-2024-99004',
                        recipient_bank_sort_code      => '20-00-00',
                        recipient_bank_account_number => '55779944',
                        recipient_bank_account_name   => 'Test Housing Ltd',
                        agreement                     => 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
                    },
                ],
                _onboard_auth(),
            },
            {
                user_id       => 99005,
                email         => 'test.user.99005@example.com',
                first_name    => 'Batch',
                last_name     => 'UserTwo',
                phone_number  => '+447900000005',
                date_of_birth => '1996-12-03',
                tenant        => [
                    {
                        post_code                     => 'SE1 7PB',
                        address_1                     => 'Flat 4b, 4 Batch Road',
                        city                          => 'London',
                        country                       => 'United Kingdom',
                        is_primary                    => \1,
                        start_rent_date               => '2024-09-01',
                        end_rent_date                 => '2025-06-30',
                        rent_due_day                  => 5,
                        amount                        => '700.00',
                        frequency                     => 'every_1_month',
                        is_active                     => \1,
                        payment_reference             => 'TST-2024-99005',
                        recipient_bank_sort_code      => '20-00-00',
                        recipient_bank_account_number => '55779955',
                        recipient_bank_account_name   => 'Test Housing Ltd',
                        agreement                     => 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
                    },
                ],
                _onboard_auth(),
            },
        ]),
        "->onboard_user returns true for batch of two users using $auth_desc"
    );
};

done_testing();

# vim: ts=4:sw=4:et
