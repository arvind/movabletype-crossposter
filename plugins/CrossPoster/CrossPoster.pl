# CrossPoster - A plugin for Movable Type.
# Copyright (c) 2007 Arvind Satyanarayan.
# This program is distributed under the terms of the
# GNU General Public License, version 2.

package MT::Plugin::CrossPoster;
use strict;

use MT 4.0;   # requires MT 4.0 or later

use base 'MT::Plugin';
our $VERSION = '1.0';
our $SCHEMA_VERSION = '1.0001';

my $plugin;
MT->add_plugin($plugin = __PACKAGE__->new({
	name            => "CrossPoster",
	version         => $VERSION,
	schema_version 	=> $SCHEMA_VERSION, 
	description     => "<__trans phrase=\"Allows you to cross-post entries to other blogs\">",
	author_name     => "Arvind Satyanarayan",
	author_link     => "http://www.movalog.com/",
	plugin_link     => "http://plugins.movalog.com/crossposter/",
	doc_link        => "http://plugins.movalog.com/crossposter/manual",
}));

# Allows external access to plugin object: MT::Plugin::CrossPoster->instance
sub instance { $plugin; }

sub init_registry {
	my $plugin = shift;
	$plugin->registry({
		object_types => {
			'crossposter_account' => 'CrossPoster::Account',
			'crossposter_cache'   => 'CrossPoster::Cache'
		},
		crossposter_connectors => {
			'Vox' => {
				class => 'CrossPoster::Connector::Vox',
				label => 'Vox',
				url_required => 1,
				url_label => 'Vox URL',
				url_hint => 'A URL to your Vox blog',
				username_required => 1,
				username_label => 'Email Address',
				username_hint => 'The email address you use to sign into Vox',
				password_required => 1
			},
			'MovableType' => {
				class => 'CrossPoster::Connector::MovableType',
				label => 'Movable Type',
				url_required => 1,
				url_label => 'Blog URL',
				url_hint => 'A URL to your Movable Type blog',
				username_required => 1,
				password_required => 1,
				password_label => 'API Password',
				password_hint => 'Your MT API password (set in your profile)'
			},
			'LiveJournal' => {
				class => 'CrossPoster::Connector::LiveJournal',
				label => 'LiveJournal', 
				url_required => 0,
				username_required => 1,
				password_required => 1
			},
			'TypePad' => {
				class => 'CrossPoster::Connector::TypePad',
				label => 'TypePad',
				username_required => 1,
				password_required => 1,
				url_required => 1,
				url_label => 'Blog Name',
				url_hint => 'The name of your blog'
			},
			# 'Blogger' => {
			#                class => 'CrossPoster::Connector::Blogger',
			#                label => 'Blogger',
			#                username_required => 1,
			#                password_required => 1,
			#                url_required => 1,
			#                url_label => 'Blog Name',
			#                url_hint => 'The name of your blog'             
			#            }
			# 'WordPressOrg' => {
			# 	class => 'CrossPoster::Connector::WordPressOrg',
			# 	label => 'WordPress.org',
			# 	url_required => 1,
			# 	url_hint => 'A URL to your WordPress blog',
			# 	username_required => 1,
			# 	password_required => 1
			# }
		},
		applications => {
			cms => {
				menus => {
					'prefs:crossposter' => {
						label             => "Crossposting",
			            mode              => 'list_crossposting_account',
			            order             => 550,
			            permission        => 'administer_blog',
			            system_permission => 'administer',
						view              => "blog"
					}
				},
				methods => {
					'list_crossposting_account' => sub { runner('list_crossposting_account', 'CrossPoster::App::CMS', @_); },
					'edit_crossposting_account' => sub { runner('edit_crossposting_account', 'CrossPoster::App::CMS', @_); }
				},
				list_filters => {
					crossposter_account => \&load_crossposter_list_filters
				}
			}
		},
		callbacks => {
			'CrossPoster::Account::post_save' => sub { runner('post_save_account', 'CrossPoster::App::CMS', @_); },
			'cms_post_save.entry' => sub { runner('CMSPostSave_entry', 'CrossPoster::App::CMS', @_); },
			'MT::App::CMS::template_param.edit_entry' => sub { runner('_edit_entry_param', 'CrossPoster::App::CMS', @_); },
			'MT::App::CMS::template_source.cfg_content_nav' => sub { runner('_cfg_content_nav', 'CrossPoster::App::CMS', @_); }
		}
	});
}

sub load_crossposter_list_filters {
    my %filters;
    my $connectors = MT->registry('crossposter_connectors');
    foreach my $connector_key ( keys %$connectors ) {
        $filters{$connector_key} = {
            label   => $plugin->translate('[_1] Accounts', $connectors->{$connector_key}->{label}),
            handler => sub {
                my ( $terms, $args ) = @_;
                $terms->{connector_key} = $connector_key;
            },
        };
    }
    my @connectors =
      sort { $filters{$a}{label} cmp $filters{$b}{label} } keys %filters;
    my $order = 100;
    foreach (@connectors) {
        $filters{$_}{order} = $order;
        $order += 100;
    }
    return \%filters;
}

sub runner {
    my $method = shift;
	my $class = shift;
    eval "require $class;";
    if ($@) { die $@; $@ = undef; return 1; }
    my $method_ref = $class->can($method);
    return $method_ref->($plugin, @_) if $method_ref;
    die $plugin->translate("Failed to find [_1]::[_2]", $class, $method);
}

1;