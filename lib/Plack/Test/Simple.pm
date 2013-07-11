# ABSTRACT: Object-Oriented PSGI Application Testing
package Plack::Test::Simple;

use HTTP::Request;
use HTTP::Response;
use URI;
use Plack::Test qw(test_psgi);
use Data::DPath qw(dpath);
use JSON qw(decode_json);
use Test::More ();
use Moo;

use utf8;

=head1 SYNOPSIS

    use Test::More;
    use Plack::Test::Simple;

    my $t   = Plack::Test::Simple->new('/path/to/app.psgi');
    my $req = $t->request;
    my $res = $t->response;

    # setup
    $req->header->content_type('application/json');

    # text request
    $t->can_get('/search')->status_is(200);

    # json request
    $t->can_post('/search')->status_is(200);
    $t->data_has('/results/4/title');

    done_testing;

=head1 SYNOPSIS

Plack::Test::Simple is a collection of testing helpers for anyone developing
Plack applications. This module is a wrapper around L<Plack::Test>, based on the
design of L<Test::Mojo>, providing a unified interface to test PSGI applications
using L<HTTP::Request> and L<HTTP::Response> objects. Typically a Plack web
application's deployment stack includes various middlewares and utilities which
are now even easier to test along-side the actual web application code.

=cut

sub BUILDARGS {
    my ($class, @args) = @_;

    unshift @args, 'psgi' if $args[0] && !$args[1];
    return {@args};
}

has data => (
    is      => 'rw',
    lazy    => 1,
    builder => 1
);

sub _build_data {
    my ($self) = @_;
    return {} unless $self->response->header('Content-Type');
    return {} unless $self->response->header('Content-Type') =~ /json/i;
    return {} unless $self->response->content;

    # only supporting JSON data currently !!!
    return decode_json $self->response->decoded_content;
}

has psgi => (
    is     => 'rw',
    coerce => sub {
        my $psgi = shift;
        die 'The psgi attribute must must be a valid PSGI filepath '.
            'or code reference' unless 'CODE' eq ref($psgi) xor -f $psgi;

        return $psgi if ref $psgi;
        return require $psgi;
    }
);

has request => (
    is      => 'rw',
    lazy    => 1,
    builder => 1
);

sub _build_request {
    return HTTP::Request->new(
        uri => URI->new(scheme => 'http', host => 'localhost', path => '/')
    )
}

has response => (
    is      => 'rw',
    lazy    => 1,
    builder => 1
);

sub _build_response {
    return HTTP::Response->new
}

sub can_get {
    my ($self, $path, $desc) = @_;
    my $res = $self->_http_request('GET', $path);

    $desc ||= "GET $path successful";
    $self->_test_more('ok', $res->is_success, $desc);

    return $self;
}

sub cant_get {
    my ($self, $path, $desc) = @_;
    my $res = $self->_http_request('GET', $path);

    $desc ||= "GET $path successful";
    $self->_test_more('ok', !$res->is_success, $desc);

    return $self;
}

sub can_post {
    my ($self, $path, $desc) = @_;
    my $res = $self->_http_request('POST', $path);

    $desc ||= "POST $path successful";
    $self->_test_more('ok', $res->is_success, $desc);

    return $self;
}

sub cant_post {
    my ($self, $path, $desc) = @_;
    my $res = $self->_http_request('POST', $path);

    $desc ||= "POST $path successful";
    $self->_test_more('ok', !$res->is_success, $desc);

    return $self;
}

sub can_put {
    my ($self, $path, $desc) = @_;
    my $res = $self->_http_request('PUT', $path);

    $desc ||= "PUT $path successful";
    $self->_test_more('ok', $res->is_success, $desc);

    return $self;
}

sub cant_put {
    my ($self, $path, $desc) = @_;
    my $res = $self->_http_request('PUT', $path);

    $desc ||= "PUT $path successful";
    $self->_test_more('ok', !$res->is_success, $desc);

    return $self;
}

sub can_delete {
    my ($self, $path, $desc) = @_;
    my $res = $self->_http_request('DELETE', $path);

    $desc ||= "DELETE $path successful";
    $self->_test_more('ok', $res->is_success, $desc);

    return $self;
}

sub cant_delete {
    my ($self, $path, $desc) = @_;
    my $res = $self->_http_request('DELETE', $path);

    $desc ||= "DELETE $path successful";
    $self->_test_more('ok', !$res->is_success, $desc);

    return $self;
}

sub can_head {
    my ($self, $path, $desc) = @_;
    my $res = $self->_http_request('HEAD', $path);

    $desc ||= "HEAD $path successful";
    $self->_test_more('ok', $res->is_success, $desc);

    return $self;
}

sub cant_head {
    my ($self, $path, $desc) = @_;
    my $res = $self->_http_request('HEAD', $path);

    $desc ||= "HEAD $path successful";
    $self->_test_more('ok', !$res->is_success, $desc);

    return $self;
}

sub can_options {
    my ($self, $path, $desc) = @_;
    my $res = $self->_http_request('OPTIONS', $path);

    $desc ||= "OPTIONS $path successful";
    $self->_test_more('ok', $res->is_success);

    return $self;
}

sub cant_options {
    my ($self, $path, $desc) = @_;
    my $res = $self->_http_request('OPTIONS', $path);

    $desc ||= "OPTIONS $path successful";
    $self->_test_more('ok', !$res->is_success);

    return $self;
}

sub can_trace {
    my ($self, $path, $desc) = @_;
    my $res = $self->_http_request('TRACE', $path);

    $desc ||= "TRACE $path successful";
    $self->_test_more('ok', $res->is_success);

    return $self;
}

sub cant_trace {
    my ($self, $path, $desc) = @_;
    my $res = $self->_http_request('TRACE', $path);

    $desc ||= "TRACE $path successful";
    $self->_test_more('ok', !$res->is_success);

    return $self;
}

sub content_is {
    my ($self, $value, $desc) = @_;
    $desc ||= 'exact match for content';
    return $self->_test_more(
        'is', $self->request->decoded_content, $value, $desc
    );
}

sub content_isnt {
    my ($self, $value, $desc) = @_;
    $desc ||= 'no match for content';
    return $self->_test_more(
        'isnt', $self->request->decoded_content, $value, $desc
    );
}

sub content_like {
    my ($self, $regex, $desc) = @_;
    $desc ||= 'content is similar';
    return $self->_test_more(
        'like', $self->request->decoded_content, $regex, $desc
    );
}

sub content_unlike {
    my ($self, $regex, $desc) = @_;
    $desc ||= 'content is not similar';
    return $self->_test_more(
        'unlike', $self->request->decoded_content, $regex, $desc
    );
}

sub content_type_is {
    my ($self, $type, $desc) = @_;
    my $name = 'Content-Type';
    $desc ||= "$name: $type";
    return $self->_test_more(
        'is', $self->request->header($name), $type, $desc
    );
}

sub content_type_isnt {
    my ($self, $type, $desc) = @_;
    my $name = 'Content-Type';
    $desc ||= "not $name: $type";
    return $self->_test_more(
        'is', $self->request->header($name), $type, $desc
    );
}

sub content_type_like {
    my ($self, $regex, $desc) = @_;
    my $name = 'Content-Type';
    $desc ||= "$name is similar";
    return $self->_test_more(
        'like', $self->request->header($name), $regex, $desc
    );
}

sub content_type_unlike {
    my ($self, $regex, $desc) = @_;
    my $name = 'Content-Type';
    $desc ||= "$name is not similar";
    return $self->_test_more(
        'unlike', $self->request->header($name), $regex, $desc
    );
}

sub header_is {
    my ($self, $name, $value, $desc) = @_;
    $desc ||= "$name: " . ($value ? $value : '');
    return $self->_test_more(
        'is', $self->request->header($name), $value, $desc
    );
}

sub header_isnt {
    my ($self, $name, $value, $desc) = @_;
    $desc ||= "not $name: " . ($value ? $value : '');
    return $self->_test_more(
        'isnt', $self->request->header($name), $value, $desc
    );
}

sub header_like {
    my ($self, $name, $regex, $desc) = @_;
    $desc ||= "$name is similar";
    return $self->_test_more(
        'like', $self->request->header($name), $regex, $desc
    );
}

sub header_unlike {
    my ($self, $name, $regex, $desc) = @_;
    $desc ||= "$name is not similar";
    return $self->_test_more(
        'unlike', $self->request->header($name), $regex, $desc
    );
}

sub data_has {
    my ($self, $path, $desc) = @_;
    $desc ||= qq{has value for data path "$path"};
    my $rs = [ dpath($path)->match($self->data) ];
    return $self->_test_more(
        'ok', $rs->[0], $desc
    );
}

sub data_hasnt {
    my ($self, $path, $desc) = @_;
    $desc ||= qq{has no value for data path "$path"};
    my $rs = [ dpath($path)->match($self->data) ];
    return $self->_test_more(
        'ok', !$rs->[0], $desc
    );
}

sub data_is_deeply {
    my $self = shift;
    my ($path, $data) = ref $_[0] ? ('', shift) : (shift, shift);
    $path ||= '/';
    my $desc ||= qq{exact match for data path "$path"};
    my $rs = [ dpath($path)->match($self->data) ];
    return $self->_test_more(
        'is_deeply', $rs->[0], $data, $desc
    );
}

sub status_is {
    my ($self, $code, $desc) = @_;
    $desc ||= "status is $code";
    return $self->_test_more(
        'is', $self->response->code, $code, $desc
    );
}

sub status_isnt {
    my ($self, $code, $desc) = @_;
    $desc ||= "status is not $code";
    return $self->_test_more(
        'isnt', $self->response->code, $code, $desc
    );
}

sub _test_more {
    my ($self, $name, @args) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 2;
    Test::More->can($name)->(@args);

    return $self;
}

sub _http_request {
    my ($self, $method, $path, $desc) = @_;
    $method = $method ? uc $method : 'GET';

    $path ||= '/';
    $desc ||= "got response for $method $path";

    $self->request->method($method);
    $self->request->uri->path($path);

    my $response =
        test_psgi $self->psgi => sub { shift->($self->request) };

    $self->response($response);
    $self->request($response->request);
    $self->_test_more('ok', $self->response && $self->request, $desc);

    return $self->response;
}

1;
