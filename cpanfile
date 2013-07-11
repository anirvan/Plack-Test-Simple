requires "Data::DPath" => "0";
requires "Data::Dumper" => "0";
requires "HTTP::Request" => "0";
requires "HTTP::Response" => "0";
requires "JSON" => "0";
requires "Moo" => "0";
requires "Plack" => "0";
requires "Plack::Test" => "0";
requires "Test::More" => "0";
requires "URI" => "0";

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.30";
};
