require 'puppet'
require 'puppetclassify'

Puppet::Type.type(:node_classify).provide(:rest) do

  defaultfor :rest    => :exist
  defaultfor :feature => :posix
  
  AUTH_INFO = {
    "ca_certificate_path" => "/opt/puppet/share/puppet-dashboard/certs/ca_cert.pem",
    "certificate_path"    => "/opt/puppet/share/puppet-dashboard/certs/pe-internal-dashboard.cert.pem",
    "private_key_path"    => "/opt/puppet/share/puppet-dashboard/certs/pe-internal-dashboard.private_key.pem"
  }
  #CLASSIFIER_URL = Puppet::Type::Node_classify.resource[:classifier_url].strip
  
  def exists?
    classifier_url = resource[:classifier_url].strip
    puppetclassify = PuppetClassify.new(classifier_url, AUTH_INFO)

    parent_id = puppetclassify.groups.get_group_id('default')
    
    group = Hash.new
    group['name'] = resource[:name].strip
    group['parent'] = parent_id
    group['environment'] = resource[:environment].strip
    group['classes'] = {resource[:role] => {}}
    group['rule'] = ["=", ["fact", "fqdn"], resource[:hostname]]
    
    group_id = puppetclassify.groups.get_group_id(resource[:name].strip)
    
    if group_id.nil?
      return false
    end
    
    existing_group = puppetclassify.groups.get_group(group_id)
    
    group.each do |k,v|
      if group[k] != existing_group[k]
        self.destroy
        return false
      end
    end
    
    return true
  end
  
  def create
    classifier_url = resource[:classifier_url].strip
    puppetclassify = PuppetClassify.new(classifier_url, AUTH_INFO)
    
    parent_id = puppetclassify.groups.get_group_id('default')
    
    group = Hash.new
    group['name'] = resource[:name].strip
    group['parent'] = parent_id
    group['environment'] = resource[:environment].strip
    group['classes'] = {resource[:role].strip => {}}
    group['rule'] = ["=", ["fact", "fqdn"], resource[:hostname].strip]
    
    begin
      puppetclassify.groups.create_group(group)
    rescue Exception => e
      puts e.message
      puts e.backtrace.inspect
    end
  end
  
  def destroy
    classifier_url = resource[:classifier_url].strip
    puppetclassify = PuppetClassify.new(classifier_url, AUTH_INFO)
    
    begin
      group_id = puppetclassify.groups.get_group_id(resource[:name].strip)
      
      if group_id.nil?
        return false
      else
        puppetclassify.groups.delete_group(group_id)
        return true
      end
      
    rescue Exception => e
      return false
    end
  end

end
    
    
        