require 'fog'

class Chef
  class Knife
    class BaremetalcloudServerCreate < Knife
      
      deps do
        require 'fog'
        require 'readline'
        require 'chef/json_compat'
        require 'chef/knife/bootstrap'
        Chef::Knife::Bootstrap.load_deps
      end
      
      banner "knife baremetalcloud server create NAME [RUN LIST...] (options)"
      
      attr_accessor :initial_sleep_delay, :bmc

      option :baremetalcloud_username,
        :short => '-x USERNAME',
        :long => '--username USERNAME',
        :description => 'Customer username'
       
      option :baremetalcloud_password,
        :short => '-P PASSWORD',
        :long => '--password PASSWORD',
        :description => 'Customer password'

     option :name,
        :short => '-n NAME',
        :long => '--name NAME',
        :description => 'Label for the new servers'
      
      option :run_list,
        :short => "-r RUN_LIST",
        :long => "--run-list RUN_LIST",
        :description => "Comma separated list of roles/recipes to apply",
        :proc => lambda { |o| o.split(/[\s,]+/) },
        :default => []
          
      option :location,
        :short => '-l LOCATION',
        :long => '--location LOCATION',
        :description => 'Location of the server (possible values: miami-fl-usa, santaclara-ca-usa)',
        :default => "miami-fl-usa"
        
      option :imageName,
        :short => '-i IMAGE_NAME',
        :long => '--image IMAGE_NAME',
        :description => 'Image installed of the server (CentOS5.5x64 or Win2003x64)'

      def tcp_test_ssh(hostname)
        tcp_socket = TCPSocket.new(hostname, "22")
        readable = IO.select([tcp_socket], nil, nil, 5)
        if readable
          Chef::Log.debug("sshd accepting connections on #{hostname}, banner is #{tcp_socket.gets}")
          yield
          true
        else
          false
        end
        rescue SocketError
          sleep 2
          false
        # Connection timed out
        rescue Errno::ETIMEDOUT
          false
        # Operation not permitted
        rescue Errno::EPERM
          false
        # Connection refused  
        rescue Errno::ECONNREFUSED
          sleep 2
          false
        # No route to host
        rescue Errno::EHOSTUNREACH
          sleep 2
          false
        # Network is unreachable
        rescue Errno::ENETUNREACH
          sleep 2
          false
        ensure
          tcp_socket && tcp_socket.close
      end


      def locate_config_value(key)
        key = key.to_sym
        config[key] || Chef::Config[:knife][key]
      end
      
      def bootstrap_for_node(public_ip)
        puts "node bootstrap - #{public_ip}"
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args = [public_ip]
        bootstrap.config[:run_list] = locate_config_value(:run_list)
        bootstrap.config[:ssh_user] = locate_config_value(:ssh_user)
        bootstrap.config[:ssh_password] = locate_config_value(:ssh_password)
        bootstrap
      end



      def addServer(planId, options = {})
        puts "Connecting to baremetalcloud"
        
        # make the request and get the body
        response = @bmc.add_server(planId,options).body
        
        # Loop while SSH is not available and sleep @initial_sleep_delay seconds
        print(".") until tcp_test_ssh(response[:server][:ip][:address]) {
          sleep @initial_sleep_delay
          print("done")
        }
        
        # Get Server's user and password
        config[:ssh_user] = response[:server][:login][:username]
        config[:ssh_password] = response[:server][:login][:password]
        
        # Configure bootstrap and trigger "run" to start up
        bootstrap_for_node(response[:server][:ip][:address]).run
      end 

      def run
        
        # sleeptime for testing ssh connectivity
        @initial_sleep_delay = 3
        
        # Parameters :baremetalcloud_username and :baremetalcloud_password are mandatory
        unless config[:baremetalcloud_username]
          ui.error("--username is a mandatory parameter")
          exit 1
        end
        
        unless config[:baremetalcloud_password]
          ui.error("--password is a mandatory parameter")
          exit 1
        end
        
        # Configure the API abstraction @bmc
        @bmc = Fog::Compute.new({
          :bare_metal_cloud_username => locate_config_value(:baremetalcloud_username),
          :bare_metal_cloud_password => locate_config_value(:baremetalcloud_password),
          :provider => 'BareMetalCloud'
        })
        
        
        # Waiting for API rectoring
        # PlanId = 7
        ## CentOS small
        config[:planId] = 7
        
        # Options
        options = {
          :location => locate_config_value(:location),
          :imageName => locate_config_value(:imageName),
          :name => locate_config_value(:name)
        }
        
        if (config[:planId])
          addServer(locate_config_value(:planId), options)
          
        elsif (config[:config]) # BLOCK WILL BE REMOVED
          @bmc.list_plans.body[:plan].each do | plan |
            if plan[:config] == config[:config]
              addServer(plan[:id], options) # small plan == 7
            end
          end
          
        else
          ui.error("PlanId or Configuration is mandatory")
          exit 1
        end
      end
    end
  end
end