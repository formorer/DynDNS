package DynDNS::Controller::Nsupdate;
use Mojo::Base 'Mojolicious::Controller';
use Net::DNS;
use Net::DNS::Update;
use Digest::HMAC_SHA1 qw(hmac_sha1_hex);
# This action will render a template
sub update {
  my $self = shift;
  my $hostname = $self->param('hostname');
  my $ip = $self->param('ip');
  my $key = $self->config->{key}; 
  my $nameserver = $self->config->{nameserver};
  my $zone = $self->config->{zone};
  my $hmac_key = $self->config->{hmac_key};

  my $fqdn = "$hostname.$zone.";

  my $hmac = hmac_sha1_hex($hostname, $hmac_key);
  my $hmac_given = $self->param('key') || '';
  $self->app->log->debug("$hmac vs $hmac_given");
  if ($hmac ne $hmac_given) {
    $self->render(text => "go home, wrong key\n");
    return;
  }

  # Create the update packet.
  my $update = Net::DNS::Update->new($zone);
  $update->push(update => rr_del("$fqdn A"));
  $update->push(update => rr_add("$fqdn 3600 A $ip"));
  # Sign the update packet
  $update->sign_tsig('hs42.com.', $key);
  # Send the update to the zone's primary master.
  my $res = Net::DNS::Resolver->new;
  $res->nameservers($nameserver);

  my $reply = $res->send($update);

  if ($reply) {
    if ($reply->header->rcode ne 'NOERROR') {
      $self->app->log->error("Update of h failed: ", $reply->header->rcode );
      $self->render( text => "Update of h failed: ", $reply->header->rcode );
    } else {
      $self->app->log->info("Updated: $fqdn points now to $ip");
      $self->render(text => "Updated: $fqdn points now to $ip\n");
    }
  } else {
    $self->app->log->error( "Update of h failed: ", $res->errorstring );
    $self->render (  text => "Update of h failed: ", $res->errorstring );
  }
}

1;
