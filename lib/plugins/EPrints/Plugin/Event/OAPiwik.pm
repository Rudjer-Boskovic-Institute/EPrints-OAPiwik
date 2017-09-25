package EPrints::Plugin::Event::OAPiwik;


our $VERSION = v1.0;

@ISA = qw( EPrints::Plugin::Event );

use strict;

sub _archive_id
{
	my( $repo, $any ) = @_;

	my $v1 = $repo->config( "oai", "archive_id" );
	my $v2 = $repo->config( "oai", "v2", "archive_id" );

	$v1 ||= $repo->config( "host" );
	$v2 ||= $v1;

	return $any ? ($v1, $v2) : $v2;
}

sub log
{
	my( $self, $access, $request_url, $token) = @_;

	my $repo = $self->{session};
	#my $eprint=$repo->dataset( EPrints::DataObj::EPrint->get_dataset_id )->dataobj($access->value( "referent_id" ));

	#Get Page title
	#my $action_name=$eprint->get_value("title");
	my $action_name= 'View';

	if($access->value( "service_type_id" ) eq "?fulltext=yes")
	{
		$action_name = 'Download';
	}

	my $piwik_url = URI->new($repo->config( "OAPiwik", "tracker" ));

	my $url_tim = $access->value( "datestamp" );
	$url_tim =~ s/^(\S+) (\S+)$/$1T$2Z/;

	my $oaipmh = EPrints::OpenArchives::to_oai_identifier(
		###	EPrints::OpenArchives::archive_id( $repo ),
			_archive_id( $repo ),
			$access->value( "referent_id" ),
		);

	my $cvar = '{"1":["oaipmhID","'.$oaipmh.'"]}';

	my $piwikrandrange = 10000;
	my $piwik_rand = int(rand($piwikrandrange));

	#Visitor's IP
	my $ip= $access->value( "requester_id" );

	#Check IP Anonymization

	my $noOfBytes=$repo->config( "OAPiwik", "noOfBytes" );
	my $ipanonymized= $ip;

	if($noOfBytes and $noOfBytes==1){
		$ipanonymized = (join '.', ( split('\.', $ip) )[0 .. 3-$noOfBytes]).".0" ;
	}
	elsif($noOfBytes and $noOfBytes==2){
		$ipanonymized = (join '.', ( split('\.', $ip) )[0 .. 3-$noOfBytes]).".0.0" ;
	}

	elsif($noOfBytes and $noOfBytes==3){
		$ipanonymized = (join '.', ( split('\.', $ip) )[0 .. 3-$noOfBytes]).".0.0.0" ;
	}

	my %qf_params = (
		url_tim => $url_tim,
		cip => $ipanonymized,
		ua => $access->value( "requester_user_agent" ),
		idsite => $repo->config( "OAPiwik", "siteID" ),
		rec => '1',
		url => $request_url,
		action_name => $action_name,
		rand => $piwik_rand,
		token_auth => $repo->config( "OAPiwik", "token_auth" ),
		cvar => $cvar,
	);

	if( $access->is_set( "referring_entity_id" ) )
	{
		$qf_params{urlref} = $access->value( "referring_entity_id" );
	}

	if($action_name eq 'Download')
	{
	   $qf_params{download} = $request_url;
	}

	$piwik_url->query_form( %qf_params );

	my $ua = $repo->config( "OAPiwik", "ua" );

	return $ua->head( $piwik_url );

}

1;
