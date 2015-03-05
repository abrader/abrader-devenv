class devenv {
  package { 'puppetclassify':
    ensure        => '0.1.0',
    provider      => 'pe_gem',
  }
}