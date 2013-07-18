#!/usr/bin/perl
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

use 5.006;
use strict;
use warnings;

use Config::MultiJSON;
use JSON;
use Test::More tests => 17;

is(Config::MultiJSON::parse_value(''), '');
is_deeply(Config::MultiJSON::parse_value('[1, 2, "three"]'), [1, 2, 'three']);
is_deeply(Config::MultiJSON::parse_value('{"test": false}'),
    {'test' => JSON::false});
is(Config::MultiJSON::parse_value('test string'), 'test string');
is(Config::MultiJSON::parse_value('5'), 5);
is(Config::MultiJSON::parse_value('-1.2'), -1.2);
ok(Config::MultiJSON::parse_value('true'));
ok(!Config::MultiJSON::parse_value('false'));
ok(!defined(Config::MultiJSON::parse_value('null')));

is_deeply(Config::MultiJSON::update({}, {}), {});

my $original = {'a' => 0, 'b' => 0, 'c' => {'d' => 0, 'e' => 0}};
my $config = Config::MultiJSON::update($original, {'a' => 1, 'b' => 1},
    {'a' => 2}, {'c' => {'d' => 3}});
is_deeply($config, {'a' => 2, 'b' => 1, 'c' => {'d' => 3, 'e' => 0}});
is_deeply($original, {'a' => 0, 'b' => 0, 'c' => {'d' => 0, 'e' => 0}});

$config = Config::MultiJSON::update_option({}, 'a.b.c', 3);
is_deeply($config, {'a' => {'b' => {'c' => 3}}});

$config = Config::MultiJSON::load_file({}, 't/00-config.d/test_config.json');
is_deeply($config, {'a' => {'b' => {'c' => 3}}});

eval { $config = Config::MultiJSON::load_file({}, 'bad'); };
ok($@);

$config = Config::MultiJSON::load_dir({}, 't/00-config.d');
is_deeply($config, {'a' => {'b' => {'c' => 3}}});

eval { $config = Config::MultiJSON::load_dir({}, 'bad'); };
ok($@);
