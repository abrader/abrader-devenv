define devenv::pagent(
  $control_repository_url,
  $role_class,
  $agent_name,
  $environment,
  $etcpath = $devenv::params::etcpath,
  $workdir = $devenv::params::devenv,
) inherits devenv::params {

  Package {
    allow_virtual => true,
  }
  
  ini_setting { 'puppet.conf.agent':
    ensure  => present,
    path    => "${etcpath}/puppet.conf",
    section => 'main',
    setting => 'basemodulepath',
    value   => "${workdir}:/etc/puppetlabs/puppet/environments/production/modules:/opt/puppet/share/puppet/modules",
  }

  class { 'r10k':
    include_prerun_command => true,
    sources  => {
      "${agent_name}-${role_class}-${environment}" => {
        'remote'  => $control_repository_url,
        'basedir' => "${workdir}",
        'prefix'  => false,
      },
    }
  }

  class { 'r10k::postrun_command':
    ensure => absent,
  }

  exec { 'r10k_run':
    command => "/opt/puppet/bin/r10k deploy environment ${environment} -p",
    creates => "${workdir}",
    require => Class['r10k'],
  }

  # package { 'puppetclassify':
  #   ensure        => '0.1.0',
  #   provider      => 'pe_gem',
  # }
  #
  # node_classify { 'Puppet Code Development':
  #   ensure         => present,
  #   role           => $role_class,
  #   hostname       => $agent_name,
  #   environment    => $environment,
  #   classifier_url => 'https://master.puppetlabs.vm:4433/classifier-api',
  #   require        => Package['puppetclassify'],
  # }
  
}