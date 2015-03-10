#!/opt/puppet/bin/ruby

require 'optparse'
require 'puppetclassify'

class NodeClassify
  attr_accessor :options

  AUTH_INFO = {
    "ca_certificate_path" => "/opt/puppet/share/puppet-dashboard/certs/ca_cert.pem",
    "certificate_path"    => "/opt/puppet/share/puppet-dashboard/certs/pe-internal-dashboard.cert.pem",
    "private_key_path"    => "/opt/puppet/share/puppet-dashboard/certs/pe-internal-dashboard.private_key.pem"
  }

  # Intialize is already used
  def start(classifier_url='https://master.puppetlabs.vm:4433/classifier-api')
    @options = {}
    classifier_url ||= 'https://localhost:4433/classifier-api'
    @puppetclassify = PuppetClassify.new(classifier_url, AUTH_INFO)
  end
  
  # Gets all options from the command line
  def get_options
    OptionParser.new do |opts|
      # Default banner is "Usage: #{opts.program_name} [options]".
  
      opts.banner += " [arguments...]"
      opts.separator "This script calls the Puppet Node Classifier API to handle classifcation tasks."
      opts.version = "0.1.1"
      
      opts.on('--ag', '--addgroup GROUPNAME', 'Add/manage node group') do |g|
        @options[:an]  = g
        @options[:ag] = true
      end
  
      opts.on('--dg', '--delgroup GROUPNAME', 'Delete node group') do |g|
        @options[:dn]  = g
        @options[:dg] = true
      end
  
      opts.on('--ah', '--addhost FQDN', 'Add Hostname, FQDN, or Puppet ::certname') do |f|
        @options[:fqdn] = f
        @options[:ah] = true
      end
      
      opts.on('--dh', '--delhost FQDN', 'Delete Hostname, FQDN, or Puppet ::certname') do |f|
        @options[:fqdn] = f
        @options[:dh] = true
      end
      
      opts.on('-c', '--class ENVIRONMENT', 'Class name. To be used with parameters \(--ap or --dp\)') do |c|
        @options[:class] = c
      end
  
      opts.on('-e', '--environment ENVIRONMENT', 'Environment to be bound to group name') do |e|
        @options[:env] = e
      end
      
      opts.on('-g', '--group GROUPNAME', 'Group name. Must be provided with host, class, or parameter calls') do |g|
        @options[:ng] = g
      end
  
      opts.on('--ac', '--addclasses CLASSES', Array, 'Classes to be classified to Puppet node') do |c|
        @options[:classes] = c
        @options[:ac] = true
      end
      
      opts.on('--dc', '--delclasses CLASSES', Array, 'Classes to be classified to Puppet node') do |c|
        @options[:classes] = c
        @options[:dc] = true
      end
  
      opts.on('--ap', '--addparams PARAMETERS', Array, 'Add overiding class parameters ') do |p|
        @options[:params] = p
        @options[:ap] = true
      end
      
      opts.on('--dp', '--delparams PARAMETERS', Array, 'Remove overiding class parameters ') do |p|
        @options[:params] = p
        @options[:dp] = true
      end
  
      opts.on('-r', '--parent PARENTGROUPNAME', 'Parent group name to be associated with group') do |r|
        @options[:pgn] = r
      end
  
      begin
        # Parse and remove options from ARGV.
        opts.parse!
      rescue OptionParser::ParseError => error
        # Without this rescue, Ruby would print the stack trace
        # of the error. Instead, we want to show the error message,
        # suggest -h or --help, and exit 1.
 
        $stderr.puts error
        $stderr.puts "(-h or --help will show valid options)"
        exit 1
      end
    end
  end

  # Used in conjunction with get_group_id and get_group_id_by_name
  def get_groups
    begin
      groups = @puppetclassify.groups.get_groups
    rescue Exception => e
      puts e.message
    end
    return groups unless groups.nil?
  end
  
  # Need to get group id to translate group name to something usable by the API
  def get_group_id
    groupname = String.new
    
    if @options[:dg]
      groupname = @options[:dn]
    elsif @options[:ag]
      groupname = @options[:an]
    else
      groupname = @options[:ng]
    end
      
    self.get_groups.each do |g|
      if groupname.strip.eql?(g['name'])
        return g['id']
      end
    end
    return nil
  end
  
  # Need this for the simple case of getting the parent group id
  def get_group_id_by_name(groupname)
    self.get_groups.each do |g|
      if groupname.strip.eql?(g['name'])
        return g['id']
      end
    end
    return nil
  end

  # Removes classified node from group
  def remove_node_from_group
    if @options[:ng] && @options[:fqdn]
    
      group_id = get_group_id
    
      if group_id.nil?
        return false
      end
    
      # Get existing group info first
      egr = @puppetclassify.groups.get_group(group_id)
    
      group = Hash.new
      group['id'] = group_id
    
      # Check to see if rules already exist.
      if egr['rule'].nil?
        group['rule'] = ["=", "name", @options[:fqdn].strip]
      else
        # Check to see rule contain node already.
        egr['rule'].each do |el|
          eqrule = ["=", "name", @options[:fqdn].strip]
          if el.eql?(eqrule)
            rule_array = egr['rule']
      
            if rule_array[0].eql?('or')
              rule_array -= [["=", "name", @options[:fqdn].strip]] 
              group['rule'] = rule_array
            end
          end
        end
      
      end
    
      begin
        @puppetclassify.groups.update_group(group)
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
    
      return true    
    end
  end

  # Adds node to group for classification
  def add_node_to_group
    if @options[:ng] && @options[:fqdn]
    
      group_id = get_group_id
    
      if group_id.nil?
        return false
      end
    
      # Get existing group info first
      egr = @puppetclassify.groups.get_group(group_id)
    
      group = Hash.new
      group['id'] = group_id
    
      # Check to see if rules already exist.
      if egr['rule'].nil?
        group['rule'] = ["or", ["=", "name", @options[:fqdn].strip]]
      else
        # Check to see rule contain node already.
        egr['rule'].each do |el|
          eqrule = ["=", "name", @options[:fqdn].strip]
          if el.eql?(eqrule)
            return true
          end
        end
      
        rule_array = egr['rule']
      
        if rule_array[0].eql?('or')
          rule_array += [["=", "name", @options[:fqdn].strip]] 
          group['rule'] = rule_array
        end
      end
      
      #puts "rule = #{group['rule']}"
    
      begin
        @puppetclassify.groups.update_group(group)
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
    
      return true    
    end
  end
  
  # Adds parameters to a given class
  def add_params_to_class
    if @options[:ng] && @options[:class] && @options[:params]
      group_id = get_group_id
      
      if group_id.nil?
        return false
      end
      
      egr = @puppetclassify.groups.get_group(group_id)
      
      group = egr
      
      clparams = Hash.new
      
      # Check if class exists in list of classes for this node group already.
      if group['classes'].include?(@options[:class].strip)
        @options[:params].each do |p|
          k = p.split('=')[0]
          v = p.split('=')[1]
          
          clparams[k] = v
        end
        
        group['classes'][@options[:class].strip] = clparams
      else
        # Figure out what to do in the case classes are not provided.
      end
      
      begin
        @puppetclassify.groups.update_group(group) unless @puppetclassify.validate.validate_group(group)
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
      
      return true
    end
  end
  
  # Removes specific parameters from being associated with a class
  def remove_params_from_class
    if @options[:ng] && @options[:class] && @options[:params]
      group_id = get_group_id
      
      if group_id.nil?
        return false
      end
      
      egr = @puppetclassify.groups.get_group(group_id)
      
      group = egr
      
      clparams = Hash.new
      
      # Check if class exists in list of classes for this node group already.
      if group['classes'].include?(@options[:class].strip)
        
        clparams = Hash.new
        
        @options[:params].each do |p|
          k = p.split('=')[0]
          v = p.split('=')[1]

          clparams[k] = nil
        end
        
        group['classes'].each do |cl|
          cl.each do |k,v|
            if k.class == Hash
              k.each do |q,p|
                if clparams.key?(q)
                  k[q] = nil
                end
              end
            end
          end
        end
        
      else
        # Figure out what to do in the case classes are not provided.
      end
      
      begin
        @puppetclassify.groups.update_group(group) #if @puppetclassify.validate.validate_group(group)
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
      
      return true
    end
  end

  # Adds class to group for classification
  def add_classes_to_group
    if @options[:ng] && @options[:classes]
      group_id = get_group_id
    
      if group_id.nil?
        return false
      end
    
      egr = @puppetclassify.groups.get_group(group_id)
    
      group = Hash.new
    
      group['id'] = group_id unless group_id.nil?
      group['classes'] = egr['classes']
     
      @options[:classes].each do |cl|
        cl_hash = Hash.new
        cl_hash[cl] = {}
        group['classes'].merge!(cl_hash)
      end

      begin
        @puppetclassify.groups.update_group(group)
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
    
      return true
    end
  end

  # Removes class from classification within a group
  def remove_classes_from_group
    if @options[:ng] && @options[:classes]
      
      group_id = get_group_id
    
      if group_id.nil?
        return false
      end
    
      egr = @puppetclassify.groups.get_group(group_id)
    
      group = Hash.new
    
      group['id'] = group_id unless group_id.nil?
      group['classes'] = egr['classes']
    
      #puts group['classes'].inspect
    
      if group['classes'].size != 0
        group['classes'].each do |k,v|
          @options[:classes].each do |cl|
            if k.eql?(cl)
              group['classes'][k] = nil
            end
          end
        end
      end

      begin
        @puppetclassify.groups.update_group(group)
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
    
      return true
    end
  end
  
  # Create a node group for classifying node(s)
  def create_node_group
    if @options[:an] && @options[:fqdn] && @options[:env] && @options[:classes]
      if @options[:pgn].nil?
        @options[:pgn] = get_group_id_by_name('default')
      end
    
      group_id = get_group_id
    
      group = Hash.new
    
      group['id'] = group_id unless group_id.nil?
      group['name'] = @options[:an]
      group['parent'] = @options[:pgn]
      group['environment'] = @options[:env].strip
      
      if group_id
        egr = @puppetclassify.groups.get_group(group_id)
        group['classes'] = egr['classes']
      else
        group['classes'] = Hash.new
      end
      
      @options[:classes].each do |cl|
        group['classes'].merge!(cl => {})
      end
     
      begin
        @puppetclassify.groups.create_group(group)
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
    else
      raise OptionParser::MissingArgument
    end
  end

  def delete_node_group
    group_id = get_group_id
    @puppetclassify.groups.delete_group(group_id) unless group_id.nil?
  end

end


# Essentially the main() class in Ruby  
  
nc = NodeClassify.new

if @puppetclassify.nil?
  nc.start
  nc.get_options
  #puts nc.options.inspect
end

# Create Node Group
if nc.options[:ag]
  if nc.options[:an] && nc.options[:fqdn] && nc.options[:env] && nc.options[:classes]
    nc.create_node_group
  else
    raise OptionParser::MissingArgument
  end
end

# Delete Node Group
if nc.options[:dg]
  if nc.options[:dn]
    nc.delete_node_group
  else
    raise OptionParser::MissingArgument, nc.options[:dn]
  end
end 

# Add Node to Group
if nc.options[:ah]
  if nc.options[:ng]
    nc.add_node_to_group
  else
    raise OptionParaser::MissingArgument
  end
end

# Remove Node from Group
if nc.options[:dh]
  if nc.options[:ng]
    nc.remove_node_from_group
  else
    raise OptionParser::MissingArgument
  end
end

# Add class(es) to Group
if nc.options[:ac]
  if nc.options[:ng] && nc.options[:classes]
    nc.add_classes_to_group
  else
    raise OptionParser.MissingArgument
  end
end

# Remove Class(es) from Group
if nc.options[:dc]
  if nc.options[:ng] && nc.options[:classes]
    nc.remove_classes_from_group
  else
    raise OptionParser.MissingArgument
  end
end

# Add Parameter(s) to Class
if nc.options[:ap]
  if nc.options[:ng] && nc.options[:class] && nc.options[:params]
    nc.add_params_to_class
  else
    raise OptionParser.MissingArgument
  end
end

# Remove Parameters from within a Class
if nc.options[:dp]
  if nc.options[:ng] && nc.options[:class] && nc.options[:params]
    nc.remove_params_from_class
  else
    raise OptionParser.MissingArgument
  end
end 
  