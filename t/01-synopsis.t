use utf8;
use strict;
use warnings;

use FindBin;
use Test::More;

use_ok 'Plack::Test::Simple';

# prepare test container
my $t  = Plack::Test::Simple->new($FindBin::RealBin.'/apps/env.psgi');

# global request configuration
my $req = $t->request;
$req->headers->authorization_basic('h@cker', 's3cret');
$req->headers->content_type('application/json');

# standard GET request test
my $tx1 = $t->transaction('get', '/')->status_is(200);
$tx1->data_match('/request_uri', '/');

# shorthand GET request test
my $tx2 = $t->get_returns_200('/');
$tx2->data_match('/request_uri', '/');

# shorthand POST request test with content
my $tx3 = $t->post_returns_200('/', 'blah');
$tx3->data_match('/request_uri', '/');

# shorthand POST request test with serialization
my $tx4 = $t->post_returns_200('/', {a => 1});
$tx4->data_match('/request_uri', '/');

done_testing;
