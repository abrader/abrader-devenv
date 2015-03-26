devenv::pagent { 'test' :
  control_repository_url => 'https://github.com/abrader/r10k_demo_http.git',
  master_name            => 'master.puppetlabs.vm',
  env                    => 'production',
}