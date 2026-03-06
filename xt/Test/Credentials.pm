package Test::Credentials;

=head1 NAME

Test::Credentials - load Payr sandbox credentials for author tests

=head1 SYNOPSIS

    use FindBin qw/ $Bin /;
    use lib $Bin;

    use Test::Credentials;

    my $creds = Test::Credentials->new;

    my $Payr = Business::Payr->new(
        api_token   => $creds->api_token,
        api_host    => $creds->api_host,
        iframe_host => $creds->iframe_host,
    );

=head1 DESCRIPTION

Loads Payr sandbox credentials from the JSON file pointed to by the
C<PAYR_CREDENTIALS> environment variable and exposes them as object
attributes.  Author tests (under C<xt/>) use this module so that live
credential handling is kept in one place.

The JSON file is expected to contain:

    {
        "api_token"   : "your_sandbox_server_api_token",
        "api_host"    : "sandbox-api.mypayr.co.uk",
        "iframe_host" : "sandbox.mypayr.co.uk"
    }

=cut

use strict;
use warnings;

use Moose;
use JSON  qw/ decode_json /;
use Carp  qw/ croak       /;

has '_data' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_data',
);

sub _build_data {
    my $path = $ENV{PAYR_CREDENTIALS}
        or croak "PAYR_CREDENTIALS environment variable is not set";

    open( my $fh, '<', $path )
        or croak "Cannot open credentials file '$path': $!";

    local $/;
    my $raw = <$fh>;
    close $fh;

    my $data = eval { decode_json( $raw ) };
    croak "Could not parse credentials file '$path' as JSON: $@" if $@;

    return $data;
}

=head1 ATTRIBUTES

=head2 api_token

The sandbox server API token.

=head2 api_host

The Payr sandbox API hostname (e.g. C<sandbox-api.mypayr.co.uk>).
Defaults to C<sandbox-api.mypayr.co.uk> if not present in the credentials file.

=head2 iframe_host

The Payr sandbox iframe hostname (e.g. C<sandbox.mypayr.co.uk>).
Defaults to C<sandbox.mypayr.co.uk> if not present in the credentials file.

=cut

sub api_token   { $_[0]->_data->{api_token}                             }
sub api_host    { $_[0]->_data->{api_host}    // 'sandbox-api.mypayr.co.uk' }
sub iframe_host { $_[0]->_data->{iframe_host} // 'sandbox.mypayr.co.uk'     }

=head1 METHODS

=head2 TO_JSON

Returns a plain hash reference of all credentials, suitable for passing
directly to C<< Business::Payr->new( %{ $creds->TO_JSON } ) >>.

=cut

sub TO_JSON {
    my $self = shift;
    return {
        api_token   => $self->api_token,
        api_host    => $self->api_host,
        iframe_host => $self->iframe_host,
    };
}

1;

# vim: ts=4:sw=4:et
