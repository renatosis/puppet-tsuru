# class rpaas
class rpaas {

  $service_provider = $::operatingsystem ? {
    Ubuntu          => 'upstart',
    CentOS          => 'init',
    default         => fail('OS not supported')
  }

  $consul_ssl_dir = '/etc/nginx/certs'
  $consul_ssl_key_file = "${consul_ssl_dir}/nginx.key"
  $consul_ssl_crt_file = "${consul_ssl_dir}/nginx.crt"

  $nginx_dirs = [ '/etc/nginx', '/etc/nginx/sites-enabled', '/etc/nginx/sites-enabled/consul',
                  '/etc/nginx/sites-enabled/consul/blocks', $consul_ssl_dir ]

}
