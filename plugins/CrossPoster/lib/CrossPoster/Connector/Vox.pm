# Vox Connector for CrossPoster - A plugin for Movable Type.
# Copyright (c) 2007 Arvind Satyanarayan.

package CrossPoster::Connector::Vox;
use strict;

use constant NS_DC => 'http://purl.org/dc/elements/1.1/';

sub edit_uri { return ''; } # Vox doesn't support editing entries via Atom API yet

sub post_uri {
	my $self = shift;
	my ($account) = @_;
	
    require XML::Atom::Feed;
    my $feed = XML::Atom::Feed->new( URI->new($account->url) );
    
    if($feed) {
        my @links = $feed->link;
        for my $link (@links) {
            if ( $link->rel eq 'service.post' ) {
                return $link->href;
            }
        }        
    }

	die MT->translate("Could not find PostURI from %s", $account->url);
}

sub entry_details {
	my $self = shift;
	my ($app, $account, $entry, $xml_entry) = @_;
	my @tags = $self->_get_entry_tags( $entry );
    my $dc = XML::Atom::Namespace->new( dc => NS_DC );
	my $enc = MT->instance->config('PublishCharset') || undef;
	
	require XML::Atom::Category;	
    foreach my $tag (@tags) {
		my $category = XML::Atom::Category->new;
		$category->term($tag->name);
		$category->label($tag->name);
		
		$xml_entry->add_category($category);
    }

	return $xml_entry;	
}


sub _get_entry_tags {
    my $self = shift;
    my($entry) = @_;

    return () unless $entry;

    require MT::ObjectTag;
    require MT::Entry;
    require MT::Tag;
    my $iter = MT::Tag->load_iter(undef, { 'sort' => 'name',
        join => ['MT::ObjectTag', 'tag_id',
        { object_id => $entry->id, blog_id => $entry->blog_id, object_datasource => MT::Entry->datasource }, { unique => 1 } ]});
    my @tags;
    while (my $tag = $iter->()) {
        next if $tag->is_private;
        push @tags, $tag;
    }
    return @tags;
}

1;