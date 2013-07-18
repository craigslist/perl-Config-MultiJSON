# Copyright 2013 craigslist
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package Config::MultiJSON;

use 5.006;
use strict;
use warnings;

use File::HomeDir;
use JSON;

my %VALID_JSON_BYTES = map { $_, 1 } ('0'..'9', '-', '[', '{', '"');
my %VALID_JSON_WORDS = map { $_, 1 } ('true', 'false', 'null');

=head1 NAME

Config::MultiJSON - Config module for loading multiple JSON files.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 AUTHOR

craigslist, C<< <opensource at craigslist.org> >>

=cut

=head1 SYNOPSIS

This module provides functions to handle loading and working with
configuration from various sources. Configuration objects are nested
hashes that can be updated to provide multiple versions if needed. All
configuration should start with some default hash.

All config files are JSON files for ease to use across languages and via
HTTP. Any lines in configuration files that begin with any whitespace
and then a '#' will be removed during parsing to allow for comments.

=head1 SUBROUTINES/METHODS

=head2 parse_value

Convert a string value to a native type. We don't use raw JSON so we can
pass unquoted strings and read from standard input.

=cut

sub parse_value {
    my $value = shift;
    if (ref($value)) {
        return $value;
    }
    if ($value eq '-') {
        $value = do { local $/; <STDIN> };
    }
    if ($value eq '') {
        return $value;
    }
    if (exists $VALID_JSON_BYTES{substr($value, 0, 1)} ||
        exists $VALID_JSON_WORDS{$value}) {
        my $json = new JSON;
        $json->allow_nonref();
        return $json->decode($value);
    }
    return $value;
}

=head2 load_file

Load a JSON file into the given config, stripping out comments.

=cut

sub load_file {
    my $config = shift;
    my $config_file = shift;
    $config_file =~ s/^~(\w+)/File::HomeDir->users_home("$1")/e;
    $config_file =~ s/^~/File::HomeDir->my_home/e;
    open CONFIG_FILE, $config_file or die "Could not open $config_file";
    my $config_data = do { local $/; <CONFIG_FILE> };
    close CONFIG_FILE;
    $config_data =~ s/[ \t]*#.*//g;
    return update($config, decode_json($config_data));
}

=head2 load_dir

Load a directory of JSON files in sorted order into the given config.

=cut

sub load_dir {
    my $config = shift;
    my $config_dir = shift;
    $config_dir =~ s/^~(\w+)/File::HomeDir->users_home("$1")/e;
    $config_dir =~ s/^~/File::HomeDir->my_home/e;
    opendir CONFIG_DIR, $config_dir or die "Could not open $config_dir";
    my @config_files = grep { $_ ne '.' && $_ ne '..' } readdir CONFIG_DIR;
    closedir CONFIG_DIR;
    foreach (sort(@config_files)) {
        $config = load_file($config, "$config_dir/$_");
    }
    return $config;
}

=head2 update

Update the given config with a new one, copying if needed to ensure the
original config hash passed in is not modified.

=cut

sub update {
    my $config = shift;
    my $copied = 0;
    foreach (@_) {
        while ((my $key, my $value) = each(%$_)) {
            if (ref($value) eq 'HASH' and exists($config->{$key})) {
                $value = update($config->{$key}, $value);
            }
            if (!$copied) {
                $config = { %$config };
                $copied = 1;
            }
            $config->{$key} = $value;
        }
    }
    return $config;
}

=head2 update_option

Update a single value in the given config using dot notation (a.b.c)
for the name, where each part in the name becomes a nested hash key.

=cut

sub update_option {
    my $config = shift;
    my $name = shift;
    my $value = shift;
    my $option = parse_value($value);
    foreach (reverse(split(/\./, $name))) {
        $option = {$_ => $option};
    }
    return update($config, $option)
}

1;
