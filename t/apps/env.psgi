use JSON qw(encode_json);

my $handler = sub {
    my $e = shift;
    my $j = encode_json {
        map { lc($_), $e->{$_} }
            grep { !ref $e->{$_} } keys %$e
    };

    return [ 200, [ "Content-Type" => "application/json" ], [ $j ] ];
};
