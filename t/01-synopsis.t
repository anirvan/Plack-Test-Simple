use utf8;
use strict;
use warnings;

use FindBin;
use Test::More;

use_ok 'Plack::Test::Simple';

my $t = Plack::Test::Simple->new($FindBin::RealBin.'/apps/env.psgi');
   $t->can_get('/')->status_is(200)->data_is_deeply('/server_name' => 'localhost');

done_testing;
