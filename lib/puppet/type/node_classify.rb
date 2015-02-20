module Puppet
  newtype(:node_classify) do
    
    @doc = %q{TODO}
    
    ensurable do
      defaultvalues
      defaultto :present
    end
    
    newparam(:name, :namevar => true) do
      desc 'The name of the node group'
      munge do |value|
        String(value)
      end
    end
    
    newparam(:role) do
      desc 'The role/class to be classified/declassified to node'
      munge do |value|
        String(value)
      end
    end
    
    newparam(:classifier_url) do
      desc 'The URL path to the Git management system server.'
      validate do |value|
        unless value =~ /^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\:?(\w*)\/classifier-api$/
          raise(Puppet::Error, "Classifier URL must be fully qualified, not '#{value}'")
        end
      end
    end
    
    newparam(:hostname) do
      desc 'Hostname of the node you want to classify.  Puppet agent must be installed and association with Puppet master must be in place'
      validate do |value|
        unless value =~ /^(?=.{1,255}$)[0-9A-Za-z](?:(?:[0-9A-Za-z]|-){0,61}[0-9A-Za-z])?(?:\.[0-9A-Za-z](?:(?:[0-9A-Za-z]|-){0,61}[0-9A-Za-z])?)*\.?$/
          raise(Puppet::Error, "Hostname for node to be classified must be fully qualified, not '#{value}'")
        end
      end
    end
    
    newparam(:environment) do
      desc 'The puppet environment where the node should exist'
      munge do |value|
        String(value)
      end
    end
    
  end
end