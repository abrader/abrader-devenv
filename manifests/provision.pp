define pmdev::provision($control_repository_url) {
  
  class { 'r10k':
    include_prerun_command => true,
    sources  => {
      'fm_development' => {
        'remote'  => $control_repository_url,
        'basedir' => "${::settings::confdir}/environments",
        'prefix'  => false,
      },
    }
  }
  
  class { 'r10k::postrun_command':
    ensure => absent,
  }
  
  exec {'r10k_run':
    command => '/opt/puppet/bin/r10k deploy environment -p',
    creates => "${::settings::confdir}/environments/production",
    require => Class['r10k'],
  }
  
}