package Data::Pageset;

use strict;
use Carp;

use Data::Page;

use vars qw(@ISA $VERSION);

@ISA = qw(Data::Page);

$VERSION = '0.04';

=head1 NAME

Data::Pageset - Page numbering and page sets

=head1 SYNOPSIS

  use Data::Pageset;
  my $page_info = Data::Pageset->new({
    'total_entries'       => $total_entries, 
    'entries_per_page'    => $entries_per_page, 
    # Optional, will use defaults otherwise.
    'current_page'        => $current_page,
    'pages_per_set'       => $pages_per_set,
  });

  # General page information
  print "         First page: ", $page_info->first_page, "\n";
  print "          Last page: ", $page_info->last_page, "\n";
  print "          Next page: ", $page_info->next_page, "\n";
  print "      Previous page: ", $page_info->previous_page, "\n";

  # Results on current page
  print "First entry on page: ", $page_info->first, "\n";
  print " Last entry on page: ", $page_info->last, "\n";

  # Can add in the pages per set after the object is created
  $page_info->pages_per_set($pages_per_set);
  
  # Page set information
  print "First page of previous page set: ",  $page_info->previous_set, "\n";
  print "    First page of next page set: ",  $page_info->next_set, "\n";
  
  # Print the page numbers of the current set
  foreach my $page (@{$page_info->pages_in_set()}) {
    if($page == $page_info->current_page()) {
      print "<b>$page</b> ";
    } else {
      print "$page ";
    }
  }

=head1 DESCRIPTION

The object produced by Data::Pageset can be used to create page
navigation, it inherits from Data::Page and has access to all 
methods from this object.

In addition it also provides methods for dealing with set of pages,
so that if there are too many pages you can easily break them
into chunks for the user to browse through.

The object can easily be passed to a templating system
such as Template Toolkit or be used within a script.

=head1 METHODS

=head2 new()

  use Data::Pageset;
  my $page_info = Data::Pageset->new({
    'total_entries'       => $total_entries, 
    'entries_per_page'    => $entries_per_page, 
    # Optional, will use defaults otherwise.
    'current_page'        => $current_page,
    'pages_per_set'       => $pages_per_set,
  });

This is the constructor of the object, it requires an anonymous
hash containing the 'total_entries', how many data units you have,
and the number of 'entries_per_page' to display. Optionally
the 'current_page' (defaults to page 1) and pages_per_set (how
many pages to display) can be added. If the pages_per_set are
not passed in they can be added later, though obviously if it
is never added you will not be able to use the page set specific
functionality.

=cut

sub new {
	my ($proto,$conf) = @_;
	my $class = ref($proto) || $proto;
	my $self = {};
	
	croak "total_entries and entries_per_page must be supplied"
		unless defined $conf->{'total_entries'} && defined $conf->{'entries_per_page'}; 

	$conf->{'current_page'} = 1 unless defined $conf->{'current_page'};

	$self->{TOTAL_ENTRIES}		= $conf->{'total_entries'};
	$self->{ENTRIES_PER_PAGE}	= $conf->{'entries_per_page'};
	$self->{CURRENT_PAGE}		= $conf->{'current_page'};
	
	bless($self, $class);
	
	croak("Fewer than one entry per page!") if $self->entries_per_page < 1;
	$self->{CURRENT_PAGE} = $self->first_page unless defined $self->current_page;
	$self->{CURRENT_PAGE} = $self->first_page if $self->current_page < $self->first_page;
	$self->{CURRENT_PAGE} = $self->last_page if $self->current_page > $self->last_page;

	$self->pages_per_set($conf->{'pages_per_set'}) if defined $conf->{'pages_per_set'};

	return $self;
}

=head2 pages_per_set()

  $page_info->pages_per_set($number_of_pages_per_set);

Calling this method initalises the calculations required to use
the paging methods below. The value can also be passed into
the constructor method new().

If called without any arguments it will return the current
number of pages per set.

=cut

sub pages_per_set {
	my $self = shift;
	my $max_pages_per_set = shift;
	
	$self->{PAGE_SET_PAGES_PER_SET} = undef unless defined $self->{PAGE_SET_PAGES_PER_SET};
	
	return $self->{PAGE_SET_PAGES_PER_SET} unless $max_pages_per_set;

	$self->{PAGE_SET_PAGES_PER_SET} = $max_pages_per_set;	
	
	my $starting_page = $self->_calc_start_page($max_pages_per_set);
	
	unless ($max_pages_per_set > 1) {
		# Only have one page in the set, must be page 1
		$self->{PAGE_SET_PREVIOUS} = $self->current_page() - 1 if $self->current_page != 1;
		$self->{PAGE_SET_PAGES} = [1] ;
		$self->{PAGE_SET_NEXT} = $self->current_page() + 1 if $self->current_page() < $self->last_page();
	} else {
  
		my $end_page = $starting_page + $max_pages_per_set - 1;

		if ($end_page < $self->last_page()) {
			$self->{PAGE_SET_NEXT} = $end_page + 1;
		}

		if ($starting_page > 1) {
			$self->{PAGE_SET_PREVIOUS} = $starting_page - $max_pages_per_set;
			$self->{PAGE_SET_PREVIOUS} =  1 if $self->{PAGE_SET_PREVIOUS} < 1;
		}

		$end_page = $self->last_page() if $self->last_page() < $end_page;
		$self->{PAGE_SET_PAGES} = [$starting_page .. $end_page];
	}

}

=head2 previous_set()

  print "Back to previous set which starts at ", $page_info->previous_set(), "\n";

This method returns the page number at the start of the previous page set.
undef is return if pages_per_set has not been set.

=cut  
  
sub previous_set {
	my $self = shift;
	return $self->{PAGE_SET_PREVIOUS} if defined $self->{PAGE_SET_PREVIOUS};
	return undef;
}

=head2 next_set()

  print "Next set starts at ", $page_info->next_set(), "\n";

This method returns the page number at the start of the next page set.
undef is return if pages_per_set has not been set.

=cut  

sub next_set {
	my $self = shift;
	return $self->{PAGE_SET_NEXT} if defined $self->{PAGE_SET_NEXT};
	return undef;
}

=head2 pages_in_set()

  foreach my $page_num (@{$page_info->pages_in_set()}) {
    print "Page: $page_num \n";
  }

This method returns an array ref of the the page numbers within
the current set. undef is return if pages_per_set has not been set.

=cut  

sub pages_in_set {
	my $self = shift;
	return $self->{PAGE_SET_PAGES} if defined $self->{PAGE_SET_PAGES};
	return [1];
}

# Calc the first page in the current set
sub _calc_start_page {
	my($self,$max_page_links_per_page) = @_;
	my $start_page;
	
	my $current_page = $self->current_page();
	my $max_pages_per_set;
	
	my $current_page_set;
	
	if ($max_page_links_per_page > 0) {
		$current_page_set = int($current_page/$max_page_links_per_page);
	
		if ($current_page % $max_page_links_per_page == 0) {
			$current_page_set = $current_page_set - 1;
		}
	}
	
	$start_page = ($current_page_set * $max_page_links_per_page) + 1;
	
	return $start_page;
}

=head1 ISSUES

There has been one report of problems with Perl 5.6.0 and
Apache::Template, please let me know if you experience
this as well.

=head1 EXPORT

None by default.

=head1 AUTHOR

Leo Lapworth <lt>LLAP@cuckoo.org<gt> - let me know if you've used
this module - go on... you know you want to.

=head1 SEE ALSO

L<Data::Page>.

=head1 COPYRIGHT

Copyright (C) 2003, Leo Lapworth

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut

1;

