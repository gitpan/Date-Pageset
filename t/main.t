#!/usr/bin/perl -w

use strict;

use lib qw( ./blib/lib ../blib/lib );

use Test::More tests => 380;

##################################
## Test Configs
##################################

# Some configs for testing
my %config = (
	'total_entries'		=> 300,
	'entries_per_page'	=> 10,
	'current_page'		=> 17
);

##################################
## End test configs
##################################

# Check we can load module
BEGIN { use_ok( 'Data::Pageset' ); }

my $page_info = Data::Pageset->new({
	'total_entries'       => $config{'total_entries'}, 
	'entries_per_page'    => $config{'entries_per_page'}, 
	'current_page'		  => $config{'current_page'},
});

isa_ok($page_info,'Data::Pageset');

$page_info->pages_per_set(2);

is('19',$page_info->next_set(),'Know that the next set is 2');

is('15',$page_info->previous_set(),'Know that the next set is 11');

is('17 18',join(' ',@{$page_info->pages_in_set()}),'Pages returned correctly');

is($config{'current_page'},$page_info->current_page(),'Current page matches');

my $name;

foreach my $line (<DATA>) {
  chomp $line;
  next unless $line;

  if ($line =~ /^# ?(.+)/) {
    $name = $1;
    next;
  }

  my @vals = map { $_ = undef if $_ eq 'undef'; $_ } split /\s+/, $line;

  my $page = Data::Pageset->new({
  	'total_entries'	=> $vals[0],
	'entries_per_page'	=> $vals[1],
	'current_page'		=> $vals[2],
	'pages_per_set'		=> $vals[3],
  });

  my @integers = (0..$vals[0]);
  @integers = $page->splice(\@integers);
  my $integers = join ',', @integers;
  my $page_nums = join ',', @{$page->pages_in_set()};
  
  is($vals[4], $page->first_page, "$name: first page");
  is($vals[5], $page->last_page, "$name: last page");
  is($vals[6], $page->first, "$name: first");
  is($vals[7], $page->last, "$name: last");
  is($vals[8], $page->previous_page, "$name: previous_page");
  is($vals[9], $page->current_page, "$name: current_page");
  is($vals[10], $page->next_page, "$name: next_page");
  is($vals[11], $integers, "$name: splice");
  is($vals[12], $page->next_set(), "$name: next_set");
  is($vals[13], $page->previous_set(), "$name: previous_set");
  is($vals[14], $page_nums, "$name: pages_in_set");
  
 
}
  
__DATA__
# Initial test
50 10 1 1   1 5 1 10 undef 1 2 0,1,2,3,4,5,6,7,8,9 2 undef 1
50 10 2 4   1 5 11 20 1 2 3 10,11,12,13,14,15,16,17,18,19 5 undef 1,2,3,4
50 10 3 undef   1 5 21 30 2 3 4 20,21,22,23,24,25,26,27,28,29 undef undef 1
50 10 4 2   1 5 31 40 3 4 5 30,31,32,33,34,35,36,37,38,39 5 1 3,4
50 10 5 1   1 5 41 50 4 5 undef 40,41,42,43,44,45,46,47,48,49 undef 4 1

# Under 10
1 10 1 4   1 1 1 1 undef 1 undef 0,1 undef undef 1
2 10 1 5   1 1 1 2 undef 1 undef 0,1,2  undef undef 1
3 10 1 6   1 1 1 3 undef 1 undef 0,1,2,3 undef undef 1
4 10 1 7   1 1 1 4 undef 1 undef 0,1,2,3,4 undef undef 1
5 10 1 undef   1 1 1 5 undef 1 undef 0,1,2,3,4,5 undef undef 1
6 10 1 9   1 1 1 6 undef 1 undef 0,1,2,3,4,5,6 undef undef 1
7 10 1 10   1 1 1 7 undef 1 undef 0,1,2,3,4,5,6,7 undef undef 1
8 10 1 undef   1 1 1 8 undef 1 undef 0,1,2,3,4,5,6,7,8 undef undef 1
9 10 1 12   1 1 1 9 undef 1 undef 0,1,2,3,4,5,6,7,8,9 undef undef 1
10 10 1 13   1 1 1 10 undef 1 undef 0,1,2,3,4,5,6,7,8,9 undef undef 1

# Over 10
11 10 1 2   1 2 1 10 undef 1 2 0,1,2,3,4,5,6,7,8,9 undef undef 1,2
11 10 2 3   1 2 11 11 1 2 undef 10,11 undef undef 1,2
12 10 1 undef   1 2 1 10 undef 1 2 0,1,2,3,4,5,6,7,8,9 undef undef 1
12 10 2 5   1 2 11 12 1 2 undef 10,11,12  undef undef 1,2
13 10 1 6   1 2 1 10 undef 1 2 0,1,2,3,4,5,6,7,8,9  undef undef 1,2
13 10 2 7   1 2 11 13 1 2 undef 10,11,12,13 undef undef 1,2

# Under 20
19 10 1 2   1 2 1 10 undef 1 2 0,1,2,3,4,5,6,7,8,9 undef undef 1,2
19 10 2 3   1 2 11 19 1 2 undef 10,11,12,13,14,15,16,17,18,19 undef undef 1,2
20 10 1 undef   1 2 1 10 undef 1 2 0,1,2,3,4,5,6,7,8,9 undef undef 1
20 10 2 5   1 2 11 20 1 2 undef 10,11,12,13,14,15,16,17,18,19 undef undef 1,2

# Over 20
21 10 1 5   1 3 1 10 undef 1 2 0,1,2,3,4,5,6,7,8,9 undef undef 1,2,3
21 10 2 5   1 3 11 20 1 2 3 10,11,12,13,14,15,16,17,18,19 undef undef 1,2,3
21 10 3 5   1 3 21 21 2 3 undef 20,21 undef undef 1,2,3
22 10 1 5   1 3 1 10 undef 1 2 0,1,2,3,4,5,6,7,8,9 undef undef 1,2,3
22 10 2 10   1 3 11 20 1 2 3 10,11,12,13,14,15,16,17,18,19 undef undef 1,2,3
22 10 3 10   1 3 21 22 2 3 undef 20,21,22 undef undef 1,2,3
23 10 1 10   1 3 1 10 undef 1 2 0,1,2,3,4,5,6,7,8,9 undef undef 1,2,3
23 10 2 undef   1 3 11 20 1 2 3 10,11,12,13,14,15,16,17,18,19 undef undef 1
23 10 3 10   1 3 21 23 2 3 undef 20,21,22,23 undef undef 1,2,3


















