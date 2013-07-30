use utf8;
use strict;
use warnings;

use FindBin;
use Test::More;

use_ok 'Plack::Test::Simple';

my $t   = Plack::Test::Simple->new($FindBin::RealBin.'/apps/env.psgi');
my $req = $t->request;
my $res = $t->response;

# setup
$req->headers->authorization_basic('h@cker', 's3cret');
$req->headers->content_type('application/json');

$t->can_get('/')->status_is(200)->data_is_deeply('/request_uri' => '/');

done_testing;
