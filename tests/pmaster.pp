devenv::pmaster { 'test' :
  control_repository_url => 'https://github.com/abrader/r10k_demo_http.git',
  role_class             => 'role::mediaserver',
  master_name            => 'master.puppetlabs.vm',
  agent_name             => 'agent.puppetlabs.vm',
  env                    => 'production',
}
