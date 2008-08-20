# Movable Type Connector for CrossPoster - A plugin for Movable Type.
# Copyright (c) 2007 Arvind Satyanarayan.

package CrossPoster::Connector::MovableType;
use strict;

sub edit_uri { 
	my $self = shift;
	my ($account, $entry) = @_;
	
	my $cache = $entry->crossposter_cache || {};
	
	return $cache->{$account->id};	
} 

sub post_uri {
	my $self = shift;
	my ($account) = @_;
	
	my $url = $account->url;
	if ( $url !~ m!rsd\.xml$! ) {
        if ( $url =~ m!/$! ) {
            $url .= 'rsd.xml';
        } else {
            $url .= '/rsd.xml';
        }
    }
    if ($url !~ m!^http://!i ) {
        $url = 'http://'.$url;
    }
    
	my $apilink = $self->_find_apilink_rsd( $url );
	return $apilink;
}

sub _find_apilink_rsd {
    my $self = shift;
    my ($rsd_uri) = @_;

    require XML::Simple;
    require LWP::Simple;
    my $xml_data = LWP::Simple::get($rsd_uri);
    my $xml     = XML::Simple::XMLin( $xml_data, KeyAttr => 'name' );
    my $apilink = $xml->{service}->{apis}->{api}->{Atom}->{apiLink};
	my $blog_id = $xml->{service}->{apis}->{api}->{Atom}->{blogID};

	require MT::Log;
    return 0, MT->log({
        message => "Couldn't retrieve 'apiLink' from $xml",
        level => MT::Log::ERROR(),
        class => 'entry',
        category => 'crosspost_error',
    }) unless $apilink;

    return $apilink . '/blog_id=' . $blog_id;
}

1;