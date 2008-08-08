# CrossPoster - A plugin for Movable Type.
# Copyright (c) 2007 Arvind Satyanarayan.

package CrossPoster::Cache;
use strict;

use MT::Object;
@CrossPoster::Cache::ISA = qw( MT::Object );
__PACKAGE__->install_properties({
    column_defs => {
        'id' => 'integer not null auto_increment',
		'blog_id' => 'integer not null',
		'account_id' => 'integer not null',
		'entry_id' => 'integer not null',
		'response' => 'string(255)'
    },
    indexes => {
        blog_id => 1,
		account_id => 1,
		entry_id => 1
    },
	meta => 1,
	audit => 1,
    primary_key => 'id',
    datasource => 'crossposter_cache',
	child_of => 'MT::Blog',
});

1;