require 'puppetclassify'

Puppet::Type.type(:node_classify).provide(:rest, :parent => Puppet::Provider::Package) do

  defaultfor :rest    => :exist
  defaultfor :feature => :posix
  
  def exists?
    auth_info = {
      "ca_certificate_path" => "/opt/puppet/share/puppet-dashboard/certs/ca_cert.pem",
      "certificate_path"    => "/opt/puppet/share/puppet-dashboard/certs/pe-internal-dashboard.cert.pem",
      "private_key_path"    => "/opt/puppet/share/puppet-dashboard/certs/pe-internal-dashboard.private_key.pem"
    }

    classifier_url = 'https://master.puppetlabs.vm:4433/classifier-api'
    puppetclassify = PuppetClassify.new(classifier_url, auth_info)
    # Get all the groups
    puppetclassify.groups.get_groups
  end

end
    
    
        