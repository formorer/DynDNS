package DynDNS;
use Mojo::Base 'Mojolicious';
use Data::Validate::Struct;


# This method will run once at server start
sub startup {
  my $self = shift;

  # Router
  my $r = $self->routes;
  my @configfiles = qw ( /etc/dyndns/dyndns.conf dyndns.conf );
  my $config = undef;
  foreach my $cfg (@configfiles) {
      if (-e $cfg) {
          $config = $self->plugin('Config', {file => $cfg});
      }
  }

  if (! defined($config)) {
      die "Could not load configuration file from " . join (", ", @configfiles);
  }
  my $reference = { 
      zone => 'hostname', 
      key => 'text',
      hmac_key => 'text',
      nameserver => 'hostname'
  };
  my $validator = new Data::Validate::Struct($reference);
  if ( ! $validator->validate($self->config) ) {
      die "config invalid " . $validator->errstr() . "\n";
  }
  # Normal route to controller
  $r->get('/update/#hostname/#ip')->to('nsupdate#update', ip => undef);
}

1;
