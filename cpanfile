requires "Email::MIME" => "1.934";
requires "Email::Sender" => "1.300018";
requires "File::DataClass" => "v0.66.0";
requires "MIME::Types" => "2.11";
requires "Moo" => "2.000001";
requires "Try::Tiny" => "0.22";
requires "Unexpected" => "v0.40.0";
requires "Web::Components::Role::TT" => "v0.3.0";
requires "namespace::autoclean" => "0.26";
requires "perl" => "5.010001";

on 'build' => sub {
  requires "Module::Build" => "0.4004";
  requires "version" => "0.88";
};

on 'test' => sub {
  requires "File::Spec" => "0";
  requires "Module::Build" => "0.4004";
  requires "Module::Metadata" => "0";
  requires "Sys::Hostname" => "0";
  requires "Test::Requires" => "0.06";
  requires "version" => "0.88";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "Module::Build" => "0.4004";
  requires "version" => "0.88";
};
