#!/opt/puppet/bin/ruby

require 'optparse'
require 'puppetclassify'

AUTH_INFO = {
  "ca_certificate_path" => "/opt/puppet/share/puppet-dashboard/certs/ca_cert.pem",
  "certificate_path"    => "/opt/puppet/share/puppet-dashboard/certs/pe-internal-dashboard.cert.pem",
  "private_key_path"    => "/opt/puppet/share/puppet-dashboard/certs/pe-internal-dashboard.private_key.pem"
}

options = {} 

def start(classifier_url='https://master.puppetlabs.vm:4433/classifier-api')
  classifier_url ||= 'https://localhost:4433/classifier-api'
  @puppetclassify = PuppetClassify.new(classifier_url, AUTH_INFO)
end

def get_groups
  begin
    groups = @puppetclassify.groups.get_groups
    #puts groups.inspect
    #puts abrule = groups[1]['rule'].inspect
    #puts @puppetclasify.rules.translate(abrule)
  rescue Exception => e
    puts e.message
  end
  return groups unless groups.nil?
end

def get_group_id(groupname)
  get_groups.each do |g|
    if groupname.strip.eql?(g['name'])
      return g['id']
    end
  end
  return nil
end

def remove_node_from_group(options)
  if options[:gn] && options[:fqdn]
    
    group_id = get_group_id(options[:gn])
    
    if group_id.nil?
      return false
    end
    
    # Get existing group info first
    egr = @puppetclassify.groups.get_group(group_id)
    
    group = Hash.new
    group['id'] = group_id
    
    # Check to see if rules already exist.
    if egr['rule'].nil?
      group['rule'] = ["=", "name", options[:fqdn].strip]
    else
      # Check to see rule contain node already.
      egr['rule'].each do |el|
        eqrule = ["=", "name", options[:fqdn].strip]
        if el.eql?(eqrule)
          rule_array = egr['rule']
      
          if rule_array[0].eql?('or')
            rule_array -= [["=", "name", options[:fqdn].strip]] 
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

def add_node_to_group(options)
  if options[:gn] && options[:fqdn]
    
    group_id = get_group_id(options[:gn])
    
    if group_id.nil?
      return false
    end
    
    # Get existing group info first
    egr = @puppetclassify.groups.get_group(group_id)
    
    group = Hash.new
    group['id'] = group_id
    
    # Check to see if rules already exist.
    if egr['rule'].nil?
      group['rule'] = ["=", "name", options[:fqdn].strip]
    else
      # Check to see rule contain node already.
      egr['rule'].each do |el|
        eqrule = ["=", "name", options[:fqdn].strip]
        if el.eql?(eqrule)
          return true
        end
      end
      
      rule_array = egr['rule']
      
      if rule_array[0].eql?('or')
        rule_array += [["=", "name", options[:fqdn].strip]] 
        group['rule'] = rule_array
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

def add_classes_to_group(options)
  if options[:gn] && options[:classes]
    group_id = get_group_id(options[:gn])
    
    if group_id.nil?
      return false
    end
    
    egr = @puppetclassify.groups.get_group(group_id)
    
    group = Hash.new
    
    group['id'] = group_id unless group_id.nil?
    group['classes'] = egr['classes']
     
    options[:classes].each do |cl|
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

def remove_classes_from_group(options)
  if options[:gn] && options[:classes]
    group_id = get_group_id(options[:gn])
    
    if group_id.nil?
      return false
    end
    
    egr = @puppetclassify.groups.get_group(group_id)
    
    group = Hash.new
    
    group['id'] = group_id unless group_id.nil?
    group['classes'] = egr['classes']
    
    puts group['classes'].inspect
    
    if group['classes'].size != 0
      group['classes'].each do |k,v|
        options[:classes].each do |cl|
          if k.eql?(cl)
            group['classes'][k] = nil
          end
        end
      end
    end

    puts group.inspect

    begin
      @puppetclassify.groups.update_group(group)
    rescue Exception => e
      puts e.message
      puts e.backtrace
    end
    
    return true
  end
end
  
def create_node_group(options)
  if options[:gn] && options[:fqdn] && options[:env] && options[:classes]
    if options[:pgn].nil?
      options[:pgn] = get_group_id('default')
    end
    
    group_id = get_group_id(options[:gn])
    
    group = Hash.new
    
    group['id'] = group_id unless group_id.nil?
    group['name'] = options[:gn]
    group['parent'] = options[:pgn]
    group['environment'] = options[:env].strip
    if options[:classes].size == 1
      group['classes'] = {options[:classes][0].strip => {}}
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
  if options[:gn]
    group_id = get_group_id(options[:gn])
    @puppetclassify.groups.delete_group(group_id) unless group_id.nil?
  else
    raise OptionParser::InvalidArgument, gn
  end
end

OptionParser.new do |opts|
  # Default banner is "Usage: #{opts.program_name} [options]".
  
  opts.banner += " [arguments...]"
  opts.separator "This script calls the Puppet Node Classifier API to handle classifcation tasks."
  opts.version = "0.1.0"
 
  opts.on('-a', '--add GROUPNAME', 'Add/manage node group') do |g|
    options[:gn]  = g
    options[:add] = true
  end
  
  opts.on('-d', '--delete GROUPNAME', 'Delete node group') do |g|
    options[:gn]  = g
    options[:del] = true
  end
  
  opts.on('-f', '--fqdn FQDN', 'Hostname, FQDN, or Puppet ::certname') do |f|
    options[:fqdn] = f
  end
  
  opts.on('-e', '--environment ENVIRONMENT', 'Environment to be bound to group name') do |e|
    options[:env] = e
  end
  
  opts.on('-c', '--classes CLASSES', Array, 'Classes to be classified to Puppet node') do |c|
    options[:classes] = c
  end
  
  opts.on('-p', '--parameters PARAMETERS', Array, 'Overide class parameters ') do |p|
    options[:params] = p
  end
  
  opts.on('-r', '--parent PARENTGROUPNAME', 'Parent group name to be associated with group') do |r|
    options[:pgn] = r
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
 
puts options

if @puppetclassify.nil?
  start
end

#get_groups

if options[:del]
  puts "Gonna delete a group now!"
else
  #create_node_group(options)
  #add_node_to_group(options)
  #remove_node_from_group(options)
  remove_classes_from_group(options)
end
  
  