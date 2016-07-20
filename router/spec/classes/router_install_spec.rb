require 'spec_helper'

describe 'router::install' do

  context "on a Ubuntu OS" do
    let :facts do
      {
        :osfamily        => 'Debian',
        :operatingsystem => 'Ubuntu',
        :lsbdistid       => 'Ubuntu',
        :lsbdistcodename => 'precise',
        :hostname        => 'foo.bar'
      }
    end

    context "with default parameters" do

      it 'install required classes' do
        should contain_class('base')
        should contain_class('router')
        should contain_class('router::install')
        should contain_class('base::ubuntu')
      end

      it 'required by apt' do

        should contain_class('apt')
        should contain_class('apt::params')
        should contain_class('apt::update')

        should contain_exec('apt_update')
        should contain_exec('add-apt-repository-ppa:tsuru/ppa')

        should contain_file('docker.list')
        should contain_file('sources.list')
        should contain_file('sources.list.d')
        should contain_file('preferences.d')
        should contain_file('99unauth')
        should contain_file('01proxy')
        should contain_file('old-proxy-file')
        should contain_file('/etc/apt/apt.conf.d/15update-stamp')
        should contain_file('/etc/apt/sources.list.d/tsuru-ppa-precise.list')

        should contain_anchor('apt::update')
        should contain_anchor('apt::source::docker')
        should contain_anchor('apt::ppa::ppa:tsuru/ppa')
        should contain_anchor('apt_key 383F073D present')
        should contain_anchor('apt_key A88D21E9 present')

        should contain_apt__ppa('ppa:tsuru/ppa')

        should contain_apt__source('docker')

        should contain_apt_key('tsuru')
        should contain_apt_key('docker')

        should contain_apt__key('tsuru')
        should contain_apt__key('docker')

      end
hipache_conf = <<EOF
{
    "server": {
        "accessLog": "/var/log/hipache/access_log",
        "accessLogMode": "file",
        "port": 80,
        "workers": 5,
        "maxSockets": 100,
        "deadBackendTTL": 30,
        "tcpTimeout": 30,
        "httpKeepAlive": true
    },
    "redisHost": "127.0.0.1",
    "redisPort": 6379,
    "redisMasterHost": "127.0.0.1",
    "redisMasterPort": 6379
}
EOF
      it 'required by hipache' do
        should contain_package('node-hipache')
        should contain_service('hipache')
        should contain_file('/etc/hipache.conf').with_content(/#{hipache_conf}/m)
      end

      it 'required by hchecker' do
        should contain_package('hipache-hchecker')
        should contain_service('hipache-hchecker')
        should contain_file('/etc/default/hipache-hchecker')
      end

    end

    context "using router planb" do
      let :params do
        {
          :router_mode => 'planb',
          :router_access_log_mode => 'syslog'
        }
      end

      it 'uninstall all packages related with hipache' do
        should contain_package('node-hipache').with_ensure('purged')
        should contain_service('hipache').with_ensure('stopped')
      end

      it 'install planb package' do
        should contain_package('planb').with_ensure('latest')
        should contain_service('planb').with_ensure('running')
      end

planb_conf = <<EOF
PLANB_OPTS="--listen 0.0.0.0:80 --read-redis-host 127.0.0.1 --read-redis-port 6379
            --write-redis-host 127.0.0.1 --write-redis-port 6379
            --access-log syslog
            --request-timeout  30  --dial-timeout 10
            --dead-backend-time 30
            "
EOF
      it "generates planb default" do
        should contain_file('/etc/default/planb').with_content(/#{planb_conf}/)
      end

    end

    context "using router planb-docker" do
      let :params do
        {
          :router_mode => 'planb-docker'
        }
      end

      it 'uninstall all packages related with hipache' do
        should contain_package('node-hipache').with_ensure('purged')
        should contain_service('hipache').with_ensure('stopped')
        should contain_package('planb').with_ensure('purged')
        should contain_service('planb').with_ensure('stopped')
      end

      it 'install docker package' do
        should contain_package('docker-engine').with_ensure('latest')
      end

      it 'exec planb commands' do
        should contain_exec('pull planb').with_command('/usr/bin/docker pull tsuru/planb:v1')
        should contain_exec('start planb').with_command('/usr/bin/docker run -d --restart=always --net=host --name=planb tsuru/planb:v1                                       --listen :80                                       --request-timeout 30                                       --dial-timeout 10                                       --dead-backend-time 30                                       --access-log /var/log/hipache/access_log')
      end

    end

  end
end
