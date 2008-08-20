# TypePad Connector for CrossPoster - A plugin for Movable Type.
# Copyright (c) 2007 Arvind Satyanarayan.

package CrossPoster::Connector::TypePad;
use strict;

use constant ENDPOINT => 'http://www.typepad.com/t/atom/weblog';

sub edit_uri { 
	my $self = shift;
	my ($account, $entry) = @_;
	
	my $cache = $entry->crossposter_cache || {};
	
	return $cache->{$account->id};	
}

sub post_uri {
	my $self = shift;
	my ($account) = @_;
	
	my $blog_name = $account->url;
	
	require XML::Atom::Client;
	
	my $api = XML::Atom::Client->new;
	$api->username($account->username);
	$api->password($account->passwd);
	
	my $services = $api->getFeed(ENDPOINT);
	
    my @links = $services->link;
    for my $link (@links) {
        if ( $link->rel eq 'service.post' && $link->title eq $blog_name) {
            return $link->href;
        }
    }

	return undef;
}

1;