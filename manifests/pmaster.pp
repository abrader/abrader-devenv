define devenv::pmaster (
  $control_repository_url,
  $master_name,
  $role_class,
  $agent_name,
  $env,
) {

  Package {
    allow_virtual => true,
  }
  
  ini_setting {'autosign_setting':
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    section => 'master',
    setting => 'autosign',
    value   => 'true',
  }
  
  file { 'autosign_file':
    ensure  => file,
    owner   => 'pe-puppet',
    group   => 'pe-puppet',
    path    => "${::settings::confdir}/autosign.conf",
    content => '*\n',
    require => Ini_Setting['autosign_setting'],
  }
  
  file_line { 'hiera_line':
    line => "    ${::settings::confdir}/environments/${environment}/hieradata",
    path   => "${::settings::confdir}/hiera.yaml",
  }
  
  service {'pe-puppetserver':
    ensure => running,
    enable => true,
    subscribe => [ File['autosign_file'], File_Line['hiera_line'] ],
  }

  class { 'r10k' :
    include_prerun_command => true,
    sources  => {
      "${agent_name}-${environment}" => {
        'remote'  => $control_repository_url,
        'basedir' => "${::settings::confdir}/environments",
        'prefix'  => false,
      },
    }
  }

  class { 'r10k::postrun_command' :
    ensure => absent,
  }
  
  file { 'modules_dir':
    ensure => absent,
    path   => "${::settings::confdir}/environments/${environment}/modules",
    force  => true,
  }

  file { 'manifests_dir':
    ensure => absent,
    path   => "${::settings::confdir}/environments/${environment}/manifests",
    force  => true,
  }

  exec { 'r10k_run' :
    command => '/opt/puppet/bin/r10k deploy environment -p',
    creates => "${::settings::confdir}/environments/${environment}/Puppetfile",
    require => [ Class['r10k'], File['modules_dir'], File['manifests_dir'], File['autosign_file'] ],
  }

  file { 'control_repo_inclusion' :
    ensure  => file,
    path    => "${::settings::confdir}/environments/${environment}/environment.conf",
    content => "modulepath = control:site:dist:modules:\$basemodulepath\n",
    require => Exec['r10k_run'],
  }

  package { 'puppetclassify' :
    ensure        => '0.1.0',
    provider      => 'pe_gem',
  }

  node_classify { 'pcd' :
    ensure         => present,
    name           => 'Puppet Code Development',
    role_class     => $role_class,
    hostname       => $agent_name,
    env            => $env,
    classifier_url => "https://${master_name}:4433/classifier-api",
    require        => [ Package['puppetclassify'], File['control_repo_inclusion'] ],
  }
  
}