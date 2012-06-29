require 'yaml'
require 'fileutils'

class Host
  attr_accessor :current_env, :config, :deletable_cache_dirs, :env_names

  def initialize()
    @deletable_cache_dirs = []
  end
  
  def load_hosts
    @output_host = @config['out_file']
    @cached_global_host = path+'/cached_global_hosts.yml'

    @cache_dirs = @config['cache_directories']
    @after_cmds = @config['after_switch_cmds']
    
    begin
		@local_settings = YAML::load_file path+"/"+@config['local_file']
	rescue
      fire :warn, "Could not locate local hosts file: #{@local_host}"
      @local_settings = []
    end
    
    begin
      @global_settings = YAML::load_file path+"/"+@config['global_file']

      # write out cache file
      begin
		File.open(@cached_global_host,"w+") do |f|
			f.write(YAML::dump(@global_settings))
		end
        
      rescue
        #fire :warn, "Could not create cached global file."
      end
    rescue
      #fire :warn, "Could not locate global hosts file: #{@global_host}\nUsing local cached copy from last load."
      begin
        # load local cached copy
        @global_settings = YAML::load_file @cached_global_host
      rescue
        #fire :warn, "Could not load cached global file either.  Please check your config."
        return false
      end
    end
    @env_names = []
    @global_settings.keys.each do |key|
      unless key == "ALL"
        @env_names << key
      end
    end
    unless @local_settings.nil? or @local_settings.empty?
      @local_settings.keys.each do |key|
        unless key == "ALL" or  @env_names.include? key
          @env_names << key
        end
      end
    end
    if File.exist? current_env_file_name
      @current_env = File.open(current_env_file_name,"r").read
    end
    @env_names.sort!
    return true
  end

  def path()
	path = File.dirname(__FILE__)
  end

  def load_config
	
	@config = YAML::load_file path+'/config.yml'
  end
  
  def get_current_env
    @current_env || "UNKNOWN"
  end

  def set_host(env)
    if File.exists? @output_host
      unless File.exists? "#{@output_host}.bak"
        FileUtils.copy @output_host, "#{@output_host}.bak"
      end
    end
    
    found_env = false
    File.open @output_host, 'w+' do |out_file|
      #write local stuff
      out_file.puts "#============ LOCAL ============#"
      
      unless @local_settings.nil? or @local_settings.empty?
        @local_settings.each do |key, values|
          if key == env or key == "ALL"
            found_env = true if key == env
            unless values.nil?
              out_file.puts "\##{key}"
              values.each do |line|
                out_file.puts "#{line}\n"
              end
            end
          end
        end
      end
      
      #write global stuff
      out_file.puts "#============ GLOBAL ============#"
      @global_settings.each do |key, values|
        if key == env or key == "ALL"
          found_env = true if key == env
          unless values.nil?
            out_file.puts "\##{key}"
            values.each do |line|
              out_file.puts "#{line}\n"
            end
          end
        end
      end
    end

    execute_cmds env
    unless @cache_dirs.nil?
      clear_cache_dirs
    end
    File.open(current_env_file_name,"w") do |env_file|
      env_file.write env
    end
    @current_env = env
    #fire :warn, "#{env} was not a match for any known rHost environments." unless found_env
  end

  def current_env_file_name()
    env_file_dir = ENV['TEMP']
    env_file_dir ||= path
    return env_file_dir + '/rhost_env.txt'
  end

  def execute_cmds(env)
    unless @after_cmds.nil?
      @after_cmds.each do |cmd|
        new_cmd = cmd.gsub 'NEW_ENV', env 
		cmd_path, *args = new_cmd.split(" ")
        t = NSTask.new
		t.arguments = args if args
		t.launchPath = cmd_path
		t.launch
		#exec("#{new_cmd}")
      end
    end
  end
  
  def clear_cache_dirs
    @cache_dirs.each do |dir|
      unless ENV['USERNAME'].nil?
      	dir.gsub! 'USERNAME', ENV['USERNAME']
      end
      unless ENV['USER'].nil?
      	dir.gsub! 'USERNAME', ENV['USER']
      end
      unless ENV['SUDO_USER'].nil?
      	dir.gsub! 'USERNAME', ENV['SUDO_USER']
      end
      if dir.match(/IE|Safari|Mozilla|Internet|Firefox/).nil?

        # if already prompted once, remember their response
        unless @deletable_cache_dirs.include? dir
          fire :prompt_cache_dir_delete, dir
          unless @deletable_cache_dirs.include? dir
            next
          end
        end
      end
      empty_dir dir
    end
  end
  
  def empty_dir(dir_name)
    begin
      if File.exists?(dir_name) and File.directory?(dir_name)
        Dir.foreach dir_name do |file_in_dir|
          unless file_in_dir == '.' or file_in_dir == '..'
            full_file_name = File.expand_path(file_in_dir, dir_name)
            if File.directory?(full_file_name)
              empty_dir full_file_name
              begin
                Dir.delete full_file_name
              rescue => ex
                # nope
                puts ex
              end
            else
              begin
                File.delete full_file_name
              rescue => ex
                # nope
                puts ex
              end
            end
          end
        end
      end
    rescue Exception => ex
      puts ex
    end
  end
  
end
