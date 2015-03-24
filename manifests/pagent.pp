define devenv::pagent (
  $control_repository_url,
  $env,
) {
  
  include ::devenv::params
  
  $etcpath = $::devenv::params::etcpath
  $workdir = $::devenv::params::workdir
  
  Package {
    allow_virtual => true,
  }
  
  file_line { 'hiera_line':
    line => "    ${::settings::confdir}/environments/${env}/hieradata",
    path   => "${::settings::confdir}/hiera.yaml",
  }
  
  file { 'envs_dir':
    ensure => present,
    path   => "${::settings::confdir}/environments",
    #force  => true,
  }
  
  file { 'env_dir':
    ensure => absent,
    path   => "${::settings::confdir}/environments/${env}",
    force  => true,
  }
  
  class { 'r10k':
    include_prerun_command => true,
    require => Package['git'],
    provider => 'pe_gem',
    sources  => {
      "${agent_name}-${role_class}-${env}" => {
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
    command => "/opt/puppet/bin/r10k deploy environment ${env} -p",
    creates => "${::settings::confdir}/environments/${env}/modules",
    require => [ Class['r10k'], File['env_dir'] ],
  }
  
}