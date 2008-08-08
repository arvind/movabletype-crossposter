# CrossPoster - A plugin for Movable Type.
# Copyright (c) 2007 Arvind Satyanarayan.

package CrossPoster::App::CMS;
use strict;

use MT::Util qw( encode_url start_background_task );

sub list_crossposting_account {
    my $plugin = shift;
    my ($app) = @_;
    my $q = $app->param;
    my $blog_id = $q->param('blog_id');
    
    return $app->return_to_dashboard( redirect => 1 )
        if !$blog_id; 
        
    $app->add_breadcrumb($plugin->translate("Crossposting Accounts"));
    
    my $hasher = sub {
        my ($obj, $row) = @_;
        
        my $connector = $obj->connector;
        next if !$connector;
        
        foreach my $key (keys %$connector) {
            $row->{"connector_$key"} = $connector->{$key};
        }
        
    };
    
    return $app->listing({
        terms => { blog_id => $blog_id },
        args => { sort => 'name', 'direction' => 'ascend' },
        no_limit => 1,
        type => 'crossposter_account',
        code => $hasher,
        template => $plugin->load_tmpl('list_account.tmpl'),
        params => {
            saved_deleted => $q->param('saved_deleted') || 0,
            saved_added => $q->param('saved_added') || 0,
            saved => $q->param('saved') && !$q->param('saved_added') || 0,
            list_noncron => 1,
            crossposting_accounts => 1,
            use_plugins => $app->config->UsePlugins
        },
    });
}

sub edit_crossposting_account {
    my $plugin = shift;
    my ($app) = @_;
    
    my $q = $app->param;
    my $blog_id = $app->param('blog_id');
    my $id = $app->param('id'); 
    
    my ($param, @connectors_loop);
    
    if ($id) {
        require CrossPoster::Account;
        my $account = CrossPoster::Account->load($id);
        
        # return $app->return_to_dashboard( redirect => 1 )
        #   if $account->author_id != $app->user->id;
        
        $param = $account->column_values();     
    }
    
    my $connectors = $app->registry('crossposter_connectors');
    foreach my $key (keys %$connectors) {
        my $row = $connectors->{$key};
        $row->{key} = $key;
        delete $row->{plugin};
        foreach my $k (keys %$row) {
            my $value = $row->{$k};
            if (ref($value) eq 'CODE') { # handle coderefs
                $value = $value->(@_);
            }
            $row->{$k} = $value;
        }
        push @connectors_loop, $row;
    }

    $param->{connectors} = \@connectors_loop;
    $param->{author_id} = $app->user->id;
        
    return $app->build_page($plugin->load_tmpl('edit_account.tmpl'), $param);   
}

sub _cfg_content_nav {
    my $plugin = shift;
    my ($cb, $app, $tmpl) = @_;
    my $old = qq{</ul>};
    $old = quotemeta($old);
    my $new = <<HTML;
<li<mt:if name="crossposting_accounts"> class="active"</mt:if>><a href="<mt:var name="script_url">?__mode=list_crossposting_account&amp;blog_id=<mt:var name="blog_id">"><__trans phrase="Crossposting"></a></li>   
HTML

    $$tmpl =~ s/($old)/$new\n$1/;
}

sub _edit_entry_param {
    my $plugin = shift;
    my ($cb, $app, $param, $tmpl) = @_;
    
    my $blog_id = $app->param('blog_id');
    
    # First populate all the accounts we have
    
    require CrossPoster::Account;
    my @accounts = CrossPoster::Account->load({ blog_id => $blog_id });
    my @accounts_loop;
    
    foreach my $account (@accounts) {   
        my $row = $account->column_values();
        
        # Skip if the connector has been uninstalled
        my $connector = $account->connector;
        next if !$connector;        
        
        if(my $id = $app->param('id')) {
            require CrossPoster::Cache;
            my $cache = CrossPoster::Cache->load({ account_id => $account->id, entry_id => $id, blog_id => $blog_id });
            $row->{is_selected} = $cache ? 1 : 0;
        }
        
        push @accounts_loop, $row;
    }
    
    $param->{crossposter_accts_loop} = \@accounts_loop;
    
    # Add our fancy javascript to the head
    my $header_include = $tmpl->getElementById('header_include');
    my $head_setvar = $tmpl->createElement('setvarblock', { name => 'html_head', append => 1 });
    
    my $innerHTML = <<HTML;
    
    <script type="text/javascript">
    <!--
        function toggleCrossposter() {
            toggleVisible('crossposter-selector', 'visible');
            toggleVisible('select-crossposter-link', 'hidden');
        }


        function toggleVisible(id, cn) {
            var d = getByID(id);
            if( DOM.hasClassName( d, cn ) )
                DOM.removeClassName( d, cn );
            else
                DOM.addClassName( d, cn );
        }

    //-->
    </script>
    
HTML
    
    $head_setvar->innerHTML($innerHTML);
    $tmpl->insertBefore($head_setvar, $header_include);
    
    # Next add the crossposter field after entry basename
    my $basename_field = $tmpl->getElementById('basename');
    
    my $crossposter_field = $tmpl->createElement('app:setting', { id => 'select-crossposters', label => $plugin->translate('Crosspost To') });
    
    $innerHTML = <<HTML;
    
    <a class="add-new-category-link visible" href="javascript:toggleCrossposter();" id="select-crossposter-link"><__trans phrase="Select Accounts"></a>

    <div id="crossposter-selector" class="category-selector autolayout-flyout-smart flyout" style="position: static;">
        <div id="crossposter-selector-inner" class="inner">
            <h4 style="font-size: 14px; margin: 0pt 0pt 5px;"><__trans phrase="Crossposting Accounts"></h4>

            <div id="crossposter-selector-list" class="category-selector-list">
                <mt:loop name="crossposter_accts_loop">
                    <div style="text-align: left;">
                        <label><input type="checkbox" name="crosspost_acct_<mt:var name="id">" value="1" class="add-category-checkbox"<mt:if name="is_selected"> checked="checked"</mt:if> /> <mt:var name="name"></label>
                    </div>
                </mt:loop>
            </div>

            <a class="add-category-ok-link" href="javascript:toggleCrossposter()" mt:command="close"><__trans phrase="OK"></a>
        </div>
    </div>  
    
HTML
        
    $crossposter_field->innerHTML($innerHTML);
    $tmpl->insertAfter($crossposter_field, $basename_field);
    


}

# Getting the PostURI could be an expensive procedure so
# get it every time an account is saved and save it

sub post_save_account {
    my $plugin = shift;
    my ($cb, $account) = @_;
    my $app = MT->instance;
    
    my $connector_class = $account->connector->{class};
    eval "require $connector_class;";
    return _show_error($plugin, $app, $@, 0)
        if $@;
        
    my $post_uri = $connector_class->post_uri($app, $account);
    $account->post_uri($post_uri);
    $account->save or die $account->errstr;
}

sub CMSPostSave_entry {
    my $plugin = shift;
    my ($cb, $app, $entry) = @_;
    
    my @param = $app->param();
    foreach (@param) {
        if (m/^crosspost_acct_(\d+)$/) {
            _cross_post($plugin, $cb, $app, $entry, $1);
            # my $res = MT::Util::start_background_task(sub {
            #       _cross_post($plugin, @_, $1);
            #                 1;
            #             });
        }
    }
    
    return 1;
}

sub _cross_post {
    my ($plugin, $cb, $app, $entry, $account_id) = @_;
    my ($username, $passwd, $api_url, $content, $xml_entry, $api_response);

    require MT::Entry;
    return 1 if $entry->status != MT::Entry::RELEASE();

    require CrossPoster::Account;
    my $account = CrossPoster::Account->load($account_id);
    my $connector_class = $account->connector->{class};
    eval "require $connector_class;";
    return _show_error($plugin, $app, $@, 0)
        if $@;
    
    # CLIENT
    require XML::Atom::Client;
    my $api = XML::Atom::Client->new;

    if(my $creds_meth = $connector_class->can('credentials')) {     
        eval { ($username, $passwd) = $creds_meth->($connector_class, $app, $account, $entry); };
        
        return _show_error($plugin, $app, $@, 0)
            if $@;
    } 

    $api->username( $username || $account->username );
    $api->password( $passwd || $account->passwd );  
    
    require XML::Atom::Entry;
    require CrossPoster::Cache;
    my $cache = CrossPoster::Cache->load({ entry_id => $entry->id, 
                    blog_id => $entry->blog_id, account_id => $account->id });
    
    if($cache) {
        eval { $api_url = $connector_class->edit_uri($app, $account, $entry); };
        
        return _show_error($plugin, $app, $@, 0)
            if $@;
            
        return _show_error($plugin, $app, 
            $plugin->translate('No EditURI was found for crosspost \'[_1]\'', $account->name), 1)
                unless $api_url;
            
        $xml_entry = $api->getEntry($api_url);
        
        return _show_error($plugin, $app, $api->errstr, 0)
            unless $xml_entry;          
            
    } else {
        eval { $api_url = $account->post_uri; };
        
        return _show_error($plugin, $app, $@, 0)
            if $@;
            
        return _show_error($plugin, $app, 
            $plugin->translate('No PostURI was found for crosspost \'[_1]\'', $account->name), 1)
                unless $api_url;
            
        $xml_entry = XML::Atom::Entry->new;
    }

    # ENTRY 
    my $enc = MT->instance->config('PublishCharset') || undef;
    
    $xml_entry->title( MT::I18N::encode_text( $entry->title , $enc, 'utf-8' ) );

    if (my $excerpt_only = $account->excerpt_only) {
        my $blog = MT::Blog->load($entry->blog_id);
        $content = $entry->get_excerpt();
        $content .= $plugin->translate('<a href="[_1]" title="Continue Reading">Continue Reading &raquo;</a>', $entry->permalink);
    } else {
        # Apply filters to entry text and extended entry if available
        my $text = $entry->text;
        my $text_more = $entry->text_more;
        $text = '' unless defined $text;
        $text_more = '' unless defined $text_more;
        my $filters = $entry->text_filters;
        push @$filters, '__default__' unless @$filters;

        $content = join "\n\n", MT->apply_text_filters($text, $filters), MT->apply_text_filters($text_more, $filters);
    }

    $xml_entry->content( MT::I18N::encode_text( $content, $enc, 'utf-8' ) );

    if(my $entry_details_meth = $connector_class->can('entry_details')) {
        eval { $xml_entry = $entry_details_meth->($connector_class, $app, $account, $entry, $xml_entry); };
        
        return _show_error($plugin, $app, $@, 0)
            if $@;      
    }

    require MT::Log;
    if($cache) {
        $api_response = $api->updateEntry( $api_url, $xml_entry )
            or return _show_error($plugin, $app, $api->errstr);
                
        $app->log({
            message     => $app->translate("Entry '[_1]' (ID:[_2]) cross-updated to '[_3]' by user '[_4]'", $entry->title, $entry->id, $account->name, $app->user->name),
            level       => MT::Log::INFO(),
            class       => 'entry',
            category    => 'crosspost_update',
            metadata    => $entry->id
        }); 
            
    } else {    
        $api_response = $api->createEntry( $api_url, $xml_entry )
                or return _show_error($plugin, $app, $api->errstr);
    
        $cache = CrossPoster::Cache->new;
        $cache->set_values({
            entry_id    => $entry->id,
            blog_id     => $entry->blog_id,
            account_id  => $account->id,
            response    => $api_response
        });
        $cache->save or die $cache->errstr;
        
        $app->log({
            message     => $app->translate("Entry '[_1]' (ID:[_2]) cross-posted to '[_3]' by user '[_4]'", $entry->title, $entry->id, $account->name, $app->user->name),
            level       => MT::Log::INFO(),
            class       => 'entry',
            category    => 'new_crosspost',
            metadata    => $entry->id
        });
    }
    
    if(my $api_response_meth = $connector_class->can('api_response')) {
        eval { $api_response = $api_response_meth->($connector_class, $app, $account, $entry, $api_response); };
        
        return _show_error($plugin, $app, $@, 0)
            if $@;      
    }
    
    return 1;
}

#####################################################################
# UTILITY SUBROUTINES
#####################################################################

sub _show_error {
    my ($plugin, $app, $msg, $log) = @_;
    $msg = $plugin->translate('An error occured [_1]', $msg);
    
    if($log) {
        $app->log({
            message     => $msg,
            level       => MT::Log::ERROR(),
            class       => 'entry',
            category    => 'crosspost_error',
        });
    } else {
        $app->send_http_header;
        $app->print($app->show_error($msg));
        $app->{no_print_body} = 1;
        exit();
    }
}

1;