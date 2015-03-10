devenv::pmaster { 'test' :
  control_repository_url => 'https://github.com/abrader/r10k_demo_http.git',
  role_class             => 'role::mediaserver',
  #role_class             => 'plex::server',
  agent_name             => 'agent.puppetlabs.vm',
  env                    => 'production',
}
