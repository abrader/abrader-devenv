define devenv::pagent(
  $control_repository_url,
  $role_class,
  $agent_name,
  $environment,
) {

  Package {
    allow_virtual => true,
  }

  class { 'r10k':
    include_prerun_command => true,
    sources  => {
      "${agent_name}-${role_class}-${environment}" => {
        'remote'  => $control_repository_url,
        'basedir' => "${::settings::confdir}/environments",
        'prefix'  => false,
      },
    }
  }

  class { 'r10k::postrun_command':
    ensure => absent,
  }

  exec { 'r10k_run':
    command => '/opt/puppet/bin/r10k deploy environment -p',
    creates => "${::settings::confdir}/environments/production",
    require => Class['r10k'],
  }

  package { 'puppetclassify':
    ensure        => '0.1.0',
    provider      => 'pe_gem',
  }
  
  node_classify { 'Puppet Code Development':
    ensure         => present,
    role           => $role_class,
    hostname       => $agent_name,
    environment    => $environment,
    classifier_url => 'https://master.puppetlabs.vm:4433/classifier-api',
    require        => Package['puppetclassify'],
  }
  
}