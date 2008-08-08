# LiveJournal Connector for CrossPoster - A plugin for Movable Type.
# Copyright (c) 2007 Arvind Satyanarayan.

package CrossPoster::Connector::LiveJournal;
use strict;

sub edit_uri { 
	my $self = shift;
	my ($app, $account, $entry) = @_;
	
	require CrossPoster::Cache;
	my $cache = CrossPoster::Cache->load({ entry_id => $entry->id, blog_id => $entry->blog_id, account_id => $account->id });
	
	return '' if !$cache;
	
	return $cache->response;	
} 

sub post_uri {
	return 'http://www.livejournal.com/interface/atom/post';
}


1;