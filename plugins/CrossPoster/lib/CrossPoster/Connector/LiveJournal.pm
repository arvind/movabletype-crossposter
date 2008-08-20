# LiveJournal Connector for CrossPoster - A plugin for Movable Type.
# Copyright (c) 2007 Arvind Satyanarayan.

package CrossPoster::Connector::LiveJournal;
use strict;

sub edit_uri { 
	my $self = shift;
	my ($account, $entry) = @_;
	
	my $cache = $entry->crossposter_cache || {};
	
	return $cache->{$account->id};	
}

sub post_uri {
	return 'http://www.livejournal.com/interface/atom/post';
}


1;