package EPrints::Plugin::Event::OAPiwik;

our $VERSION = v0.99;

@ISA = qw( EPrints::Plugin::Event );

use strict;

# borrowed from EPrints 3.3's EPrints::OpenArchives::archive_id
sub _archive_id
{
	my( $repo, $any ) = @_;

	my $v1 = $repo->config( "oai", "archive_id" );
	my $v2 = $repo->config( "oai", "v2", "archive_id" );

	$v1 ||= $repo->config( "host" );
	$v2 ||= $v1;

	return $any ? ($v1, $v2) : $v2;
}


sub replay
{
	my( $self, $accessid ) = @_;

	my $repo = $self->{session};

	local $SIG{__DIE__};
	eval { $repo->dataset( "access" )->search(filters => [
				{ meta_fields => [qw( accessid )], value => "$accessid..", },
###				{ meta_fields => [qw( service_type_id )], value => "?fulltext=yes", match => "EX", },
			],
			limit => 1000, # lets not go crazy ...
	)->map(sub {
		(undef, undef, my $access) = @_;

		my $r = $self->log( $access );
		die "failed\n" if !$r->is_success;
		$accessid = $access->id;
	}) };
	if( $@ eq "failed\n" )
	{
		$repo->log( "Attempt to re-send OAPiwik trackback failed, trying again in 24 hours time" );

		my $event = $self->{event};
		$event->set_value( "params", [$accessid] );
		$event->set_value( "start_time", EPrints::Time::iso_datetime( time + 86400 ) );
		#return EPrints::Const::HTTP_RESET_CONTENT;
		return 0;
	}
	elsif( $@ )
	{
		die $@;
	}

	return;
}

sub log
{
	my( $self, $access, $request_url, $SITE_ID, $token ) = @_;

	my $repo = $self->{session};
	my $action_name = 'View';
	if($access->value( "service_type_id" ) eq "?fulltext=yes")
	{ 
		$action_name = 'Download'; 
	}
###	return if $access->value( "service_type_id" ) ne "?fulltext=yes";

	my $doc = $repo->dataset( "document" )->dataobj( $access->value( "referent_docid" ) );

	my $url = URI->new(
		$repo->config( "OAPiwik", "tracker" )
	);

	my $url_tim = $access->value( "datestamp" );
	$url_tim =~ s/^(\S+) (\S+)$/$1T$2Z/;

	my $artnum = EPrints::OpenArchives::to_oai_identifier(
		###	EPrints::OpenArchives::archive_id( $repo ),
			_archive_id( $repo ),
			$access->value( "referent_id" ),
		);
	my $cvar = '{"1":["oaipmhID","'.$artnum.'"]}'; 
	
	my $eprint = $self->{processor}->{eprint};
	my $title = $eprint->get_value("title");
	
	my %qf_params = (
		###url_ver => "Z39.88-2004",
		url_tim => $url_tim,
		cip => $access->value( "requester_id" ),
		ua => $access->value( "requester_user_agent" ),
		'rft.artnum' => $artnum,
		idsite => $SITE_ID,
		rec => '1',
		url => $request_url,
		#action_name => $action_name,
		action_name => $title,
		token_auth => $token,
		cvar => $cvar,
	);
	
	if( $access->is_set( "referring_entity_id" ) )
	{
		$qf_params{urlref} = $access->value( "referring_entity_id" );
	}
	
	$url->query_form( %qf_params );

	my $ua = $repo->config( "OAPiwik", "ua" );

	return $ua->head( $url );
}

1;
