# ABSTRACT: Object-Oriented PSGI Application Testing
package Plack::Test::Simple;

use HTTP::Request;
use HTTP::Response;
use URI;
use Plack::Util;
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
    $req->headers->authorization_basic('h@cker', 's3cret');
    $req->headers->content_type('application/json');

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

=attribute data

The data attribute contains a hashref corresponding to the UTF-8 decoded JSON
string found in the HTTP response body.

=cut

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

=attribute psgi

The psgi attribute contains a coderef containing the PSGI compliant application
code.

=cut

has psgi => (
    is     => 'rw',
    isa    => sub {
        my $psgi = shift;

        die 'The psgi attribute must must be a valid PSGI filepath or code '.
            'reference' if !$psgi && ('CODE' eq ref($psgi) xor -f $psgi);
    },
    coerce => sub {
        my $psgi = shift;

        # return psgi
        return $psgi if ref $psgi;
        return Plack::Util::load_psgi($psgi);
    }
);

=attribute request

The request attribute contains the L<HTTP::Request> object which will be used
to process the HTTP requests. This attribute is never reset.

=cut

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

=attribute response

The response attribute contains the L<HTTP::Response> object which will be
automatically set upon issuing an HTTP requests. This attribute is reset upon
each request.

=cut

has response => (
    is      => 'rw',
    lazy    => 1,
    builder => 1
);

sub _build_response {
    return HTTP::Response->new
}

=method can_get

The can_get method tests whether an HTTP request to the supplied path is a
success.

    $self->can_get('/users');
    $self->can_get('/users' => 'http get /users ok');

=cut

sub can_get {
    my ($self, $path, $desc) = @_;
    my $res = $self->_http_request('GET', $path);

    $desc ||= "GET $path successful";
    $self->_test_more('ok', $res->is_success, $desc);

    return $self;
}

=method cant_get

The cant_get method tests whether an HTTP request to the supplied path is a
success.

    $self->cant_get('/');
    $self->cant_get('/users' => 'http get /users not ok');

=cut

sub cant_get {
    my ($self, $path, $desc) = @_;
    my $res = $self->_http_request('GET', $path);

    $desc ||= "GET $path successful";
    $self->_test_more('ok', !$res->is_success, $desc);

    return $self;
}

=method can_post

The can_post method tests whether an HTTP request to the supplied path is a
success.

    $self->can_post('/users');
    $self->can_post('/users' => 'http post /users ok');

=cut

sub can_post {
    my ($self, $path, $desc) = @_;
    my $res = $self->_http_request('POST', $path);

    $desc ||= "POST $path successful";
    $self->_test_more('ok', $res->is_success, $desc);

    return $self;
}

=method cant_post

The cant_post method tests whether an HTTP request to the supplied path is a
success.

    $self->cant_post('/users');
    $self->cant_post('/users' => 'http post /users not ok');

=cut

sub cant_post {
    my ($self, $path, $desc) = @_;
    my $res = $self->_http_request('POST', $path);

    $desc ||= "POST $path successful";
    $self->_test_more('ok', !$res->is_success, $desc);

    return $self;
}

=method can_put

The can_put method tests whether an HTTP request to the supplied path is a
success.

    $self->can_put('/users');
    $self->can_put('/users' => 'http put /users ok');

=cut

sub can_put {
    my ($self, $path, $desc) = @_;
    my $res = $self->_http_request('PUT', $path);

    $desc ||= "PUT $path successful";
    $self->_test_more('ok', $res->is_success, $desc);

    return $self;
}

=method cant_put

The cant_put method tests whether an HTTP request to the supplied path is a
success.

    $self->cant_put('/users');
    $self->cant_put('/users' => 'http put /users not ok');

=cut

sub cant_put {
    my ($self, $path, $desc) = @_;
    my $res = $self->_http_request('PUT', $path);

    $desc ||= "PUT $path successful";
    $self->_test_more('ok', !$res->is_success, $desc);

    return $self;
}

=method can_delete

The can_delete method tests whether an HTTP request to the supplied path is a
success.

    $self->can_delete('/users');
    $self->can_delete('/users' => 'http delete /users ok');

=cut

sub can_delete {
    my ($self, $path, $desc) = @_;
    my $res = $self->_http_request('DELETE', $path);

    $desc ||= "DELETE $path successful";
    $self->_test_more('ok', $res->is_success, $desc);

    return $self;
}

=method cant_delete

The cant_delete method tests whether an HTTP request to the supplied path is a
success.

    $self->cant_delete('/users');
    $self->cant_delete('/users' => 'http delete /users not ok');

=cut

sub cant_delete {
    my ($self, $path, $desc) = @_;
    my $res = $self->_http_request('DELETE', $path);

    $desc ||= "DELETE $path successful";
    $self->_test_more('ok', !$res->is_success, $desc);

    return $self;
}

=method can_head

The can_head method tests whether an HTTP request to the supplied path is a
success.

    $self->can_head('/users');
    $self->can_head('/users' => 'http head /users ok');

=cut

sub can_head {
    my ($self, $path, $desc) = @_;
    my $res = $self->_http_request('HEAD', $path);

    $desc ||= "HEAD $path successful";
    $self->_test_more('ok', $res->is_success, $desc);

    return $self;
}

=method cant_head

The cant_head method tests whether an HTTP request to the supplied path is a
success.

    $self->cant_head('/users');
    $self->cant_head('/users' => 'http head /users ok');

=cut

sub cant_head {
    my ($self, $path, $desc) = @_;
    my $res = $self->_http_request('HEAD', $path);

    $desc ||= "HEAD $path successful";
    $self->_test_more('ok', !$res->is_success, $desc);

    return $self;
}

=method can_options

The can_options method tests whether an HTTP request to the supplied path is
a success.

    $self->can_options('/users');
    $self->can_options('/users' => 'http options /users ok');

=cut

sub can_options {
    my ($self, $path, $desc) = @_;
    my $res = $self->_http_request('OPTIONS', $path);

    $desc ||= "OPTIONS $path successful";
    $self->_test_more('ok', $res->is_success);

    return $self;
}

=method cant_options

The cant_options method tests whether an HTTP request to the supplied path is
a success.

    $self->cant_options('/users');
    $self->cant_options('/users' => 'http options /users not ok');

=cut

sub cant_options {
    my ($self, $path, $desc) = @_;
    my $res = $self->_http_request('OPTIONS', $path);

    $desc ||= "OPTIONS $path successful";
    $self->_test_more('ok', !$res->is_success);

    return $self;
}

=method can_trace

The can_trace method tests whether an HTTP request to the supplied path is
a success.

    $self->can_trace('/users');
    $self->can_trace('/users' => 'http trace /users ok');

=cut

sub can_trace {
    my ($self, $path, $desc) = @_;
    my $res = $self->_http_request('TRACE', $path);

    $desc ||= "TRACE $path successful";
    $self->_test_more('ok', $res->is_success);

    return $self;
}

=method cant_trace

The cant_trace method tests whether an HTTP request to the supplied path is
a success.

    $self->cant_trace('/users');
    $self->cant_trace('/users' => 'http trace /users not ok');

=cut

sub cant_trace {
    my ($self, $path, $desc) = @_;
    my $res = $self->_http_request('TRACE', $path);

    $desc ||= "TRACE $path successful";
    $self->_test_more('ok', !$res->is_success);

    return $self;
}

=method content_is

The content_is method tests ...

=cut

sub content_is {
    my ($self, $value, $desc) = @_;
    $desc ||= 'exact match for content';
    return $self->_test_more(
        'is', $self->request->decoded_content, $value, $desc
    );
}

=method content_isnt

The content_isnt method tests ...

=cut

sub content_isnt {
    my ($self, $value, $desc) = @_;
    $desc ||= 'no match for content';
    return $self->_test_more(
        'isnt', $self->request->decoded_content, $value, $desc
    );
}

=method content_like

The content_like method tests ...

=cut

sub content_like {
    my ($self, $regex, $desc) = @_;
    $desc ||= 'content is similar';
    return $self->_test_more(
        'like', $self->request->decoded_content, $regex, $desc
    );
}

=method content_unlike

The content_unlike method tests ...

=cut

sub content_unlike {
    my ($self, $regex, $desc) = @_;
    $desc ||= 'content is not similar';
    return $self->_test_more(
        'unlike', $self->request->decoded_content, $regex, $desc
    );
}

=method content_type_is

The content_type_is method tests ...

=cut

sub content_type_is {
    my ($self, $type, $desc) = @_;
    my $name = 'Content-Type';
    $desc ||= "$name: $type";
    return $self->_test_more(
        'is', $self->request->header($name), $type, $desc
    );
}

=method content_type_isnt

The content_type_isnt method tests ...

=cut

sub content_type_isnt {
    my ($self, $type, $desc) = @_;
    my $name = 'Content-Type';
    $desc ||= "not $name: $type";
    return $self->_test_more(
        'is', $self->request->header($name), $type, $desc
    );
}

=method content_type_like

The content_type_like method tests ...

=cut

sub content_type_like {
    my ($self, $regex, $desc) = @_;
    my $name = 'Content-Type';
    $desc ||= "$name is similar";
    return $self->_test_more(
        'like', $self->request->header($name), $regex, $desc
    );
}

=method content_type_unlike

The content_type_unlike method tests ...

=cut

sub content_type_unlike {
    my ($self, $regex, $desc) = @_;
    my $name = 'Content-Type';
    $desc ||= "$name is not similar";
    return $self->_test_more(
        'unlike', $self->request->header($name), $regex, $desc
    );
}

=method header_is

The header_is method tests ...

=cut

sub header_is {
    my ($self, $name, $value, $desc) = @_;
    $desc ||= "$name: " . ($value ? $value : '');
    return $self->_test_more(
        'is', $self->request->header($name), $value, $desc
    );
}

=method header_isnt

The header_isnt method tests ...

=cut

sub header_isnt {
    my ($self, $name, $value, $desc) = @_;
    $desc ||= "not $name: " . ($value ? $value : '');
    return $self->_test_more(
        'isnt', $self->request->header($name), $value, $desc
    );
}

=method header_like

The header_like method tests ...

=cut

sub header_like {
    my ($self, $name, $regex, $desc) = @_;
    $desc ||= "$name is similar";
    return $self->_test_more(
        'like', $self->request->header($name), $regex, $desc
    );
}

=method header_unlike

The header_unlike method tests ...

=cut

sub header_unlike {
    my ($self, $name, $regex, $desc) = @_;
    $desc ||= "$name is not similar";
    return $self->_test_more(
        'unlike', $self->request->header($name), $regex, $desc
    );
}

=method data_has

The data_has method tests ...

=cut

sub data_has {
    my ($self, $path, $desc) = @_;
    $desc ||= qq{has value for data path "$path"};
    my $rs = [ dpath($path)->match($self->data) ];
    return $self->_test_more(
        'ok', $rs->[0], $desc
    );
}

=method data_hasnt

The data_hasnt method tests ...

=cut

sub data_hasnt {
    my ($self, $path, $desc) = @_;
    $desc ||= qq{has no value for data path "$path"};
    my $rs = [ dpath($path)->match($self->data) ];
    return $self->_test_more(
        'ok', !$rs->[0], $desc
    );
}

=method data_is_deeply

The data_is_deeply method tests ...

=cut

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

=method data_match

The data_match method tests ...

=cut

sub data_match {
    goto data_is_deeply;
}

=method status_is

The status_is method tests ...

=cut

sub status_is {
    my ($self, $code, $desc) = @_;
    $desc ||= "status is $code";
    return $self->_test_more(
        'is', $self->response->code, $code, $desc
    );
}

=method status_isnt

The status_isnt method tests ...

=cut

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
