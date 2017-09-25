=pod

=head1 OpenAIRE Piwik Data Provider

Provide data for OpenAIRE usage statistics.

Released to the public domain (or CC0 depending on your juristiction).

USE OF THIS EXTENSION IS ENTIRELY AT YOUR OWN RISK

=head2 Installation

See README

=head2 Implementation

Record to the configured Piwik server whenever an item is viewed or full-text object is requested from EPrints.

=head2 Changes

v1.0 Dimitris Pierrakos dpierrakos@gmail.com, Karlo Hrenovic <karlo.hrenovic@irb.hr>, Alen Vodopijevec <alen@irb.hr> 

Initial version
- based on "PIRUS/IRUS-UK PUSH Implementation" <http://files.eprints.org/971/>

=cut

require LWP::UserAgent;
require LWP::ConnCache;

##################
# CONFIG START  #
################

# Modify the following URL to the Piwik tracker location
$c->{OAPiwik}->{tracker} = "https://analytics.openaire.eu/piwik.php";

# Enter the OpenAIRE Piwik Site ID
$c->{OAPiwik}->{siteID} = "1";

# Enter the piwik token_auth
$c->{OAPiwik}->{token_auth} = "32846584f571be9b57488bf4088f30ea";

# Specify the number of bytes, 1,2 or 3, for IP Anonymization (empty for no IP Anonymization)
$c->{OAPiwik}->{noOfBytes} = "";

# Other Config Parameters
$c->{OAPiwik}->{ua} = LWP::UserAgent->new(conn_cache => LWP::ConnCache->new,);

$c->{plugins}->{"Event::OAPiwik"}->{params}->{disable} = 0;


################
# CONFIG END  #
##############

##############################################################################

$c->add_dataset_trigger( 'access', EPrints::Const::EP_TRIGGER_CREATED, sub {
	my( %args ) = @_;

	my $repo = $args{repository};
	my $access = $args{dataobj};

	my $plugin = $repo->plugin( "Event::OAPiwik" );

	my $r = $plugin->log( $access, $repo->current_url( host => 1 ));
});

