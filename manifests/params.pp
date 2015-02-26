class devenv::params {
  if $::osfamily == 'windows' {
    $workdir = 'c:/puppetcode'
    $etcpath = 'C:/ProgramData/PuppetLabs/puppet/etc'
  }
  else {
    $workdir = '/root/puppetcode'
    $etcpath = '/etc/puppetlabs/puppet'
  }
}