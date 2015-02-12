define pmdev::provision($control_repository_url) {
  
  class { 'r10k':
    sources  => {
      'fm_development' => {
        'remote'  => $control_repository_url,
        'basedir' => "${::settings::confdir}/environments",
        'prefix'  => false,
      },
    }
    include_prerun_command => true,
  }
  
  class { 'r10k::postrun_command':
    ensure => absent,
  }
  
  exec {'r10k_run':
    command => '/opt/puppet/bin/r10k deploy environment -p',
    creates => "${::settings::confdir}/environments/production",
    require => Class['r10k'],
  }
  
  node_classify { 'classify_agent':
    ensure         => present,
    role           => 'role::mediaserver',
    hostname       => 'agent.puppetlabs.vm',
    classifier_url => 'https://master.puppetlabs.vm:4433/classifier-api',
  }
  
}