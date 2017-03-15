=pod

=head1 OpenAIRE Piwik Data Provider

Provide data for OpenAIRE usage statistics.

Released to the public domain (or CC0 depending on your juristiction).

USE OF THIS EXTENSION IS ENTIRELY AT YOUR OWN RISK

=head2 Installation

See README

=head2 Implementation

This code will PING the configured tracker server whenever an item is viewed or full-text object is requested from EPrints.

=head2 Changes

0.99 Karlo Hrenovic <karlo.hrenovic@irb.hr>, Alen Vodopijevec <alen@irb.hr>

Initial version
- based on "PIRUS/IRUS-UK PUSH Implementation" <http://files.eprints.org/971/>

=cut

require LWP::UserAgent;
require LWP::ConnCache;

##################
# CONFIG START  #
################

# Modify the following URL to the Piwik tracker location
$c->{OAPiwik}->{tracker} = "http://jurica.irb.hr/oapiwik/";

# Enter the OpenAIRE Piwik Site ID
my $SITE_ID = '';

################
# CONFIG END  #
##############



# you may want to revise the settings for the user agent e.g. increase or
# decrease the network timeout
$c->{OAPiwik}->{ua} = LWP::UserAgent->new(
	from => $c->{adminemail},
	agent => $c->{version},
	timeout => 20,
	conn_cache => LWP::ConnCache->new,
);

$c->{plugins}->{"Event::OAPiwik"}->{params}->{disable} = 0;

##############################################################################

$c->add_dataset_trigger( 'access', EPrints::Const::EP_TRIGGER_CREATED, sub {
	my( %args ) = @_;

	my $repo = $args{repository};
	my $access = $args{dataobj};

	my $plugin = $repo->plugin( "Event::OAPiwik" );

	my $r = $plugin->log( $access, $repo->current_url( host => 1 ), $SITE_ID );

	if( defined $r && !$r->is_success )
	{
		my $event = $repo->dataset( "event_queue" )->dataobj_class->create_unique( $repo, {
			eventqueueid => Digest::MD5::md5_hex( "Event::OAPiwik::replay" ),
			pluginid => "Event::OAPiwik",
			action => "replay",
		});
		if( defined $event )
		{
			$event->set_value( "params", [$access->id] );
			$event->commit;
		}
	}
});
