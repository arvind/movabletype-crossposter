# CrossPoster - A plugin for Movable Type.
# Copyright (c) 2007 Arvind Satyanarayan.

package CrossPoster::Account;
use strict;

use MT::Object;
@CrossPoster::Account::ISA = qw( MT::Object );
__PACKAGE__->install_properties({
    column_defs => {
        'id' => 'integer not null auto_increment',
		'blog_id' => 'integer not null',
		'author_id' => 'integer not null',
		'connector_key' => 'string(255) not null',
		'name' => 'string(255) not null',
		'username' => 'string(255)',
		'passwd' => 'string(255)',
		'url' => 'string(255)',
		'excerpt_only' => 'boolean',
		'post_uri' => 'string(255)'
    },
    indexes => {
		author_id => 1,
		connector_key => 1,
        blog_id => 1,
    },
    primary_key => 'id',
    datasource => 'crossposter_account',
	child_of => 'MT::Blog',
});

sub class_label {
    return MT->translate("Account");
}

sub class_label_plural {
    return MT->translate("Accounts");
}

sub connector {
	my $account = shift;
	my $connector = MT->registry('crossposter_connectors', $account->connector_key);
	
	return $connector;
}

sub save {
    my $account = shift;

    ## Getting the PostURI could be an expensive procedure so
    # get it every time an account is saved and store it w/acct
    my $connector_class = $account->connector->{class};
    eval "require $connector_class;";
    Carp::croak($@) if $@;
    
    my $post_uri = $connector_class->post_uri($account);
    $account->post_uri($post_uri);
    
    unless ($account->SUPER::save(@_)) {
        print STDERR "error during save: " . $account->errstr . "\n";
        die $account->errstr;
    }
    
    1;
}

1;