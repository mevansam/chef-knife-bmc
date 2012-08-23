require 'fog'

class Chef
  class Knife
    class BaremetalcloudServerCreate < Knife
      
      deps do
        require 'fog'
#        require 'readline'
        require 'chef/knife/bootstrap'
        Chef::Knife::Bootstrap.load_deps
      end
      
      banner "knife baremetalcloud server create (options)"
      
      attr_accessor :initial_sleep_delay, :bmc

      option :baremetalcloud_username,
        :short => '-x USERNAME',
        :long => '--username USERNAME',
        :description => 'Customer username'
       
      option :baremetalcloud_password,
        :short => '-P PASSWORD',
        :long => '--password PASSWORD',
        :description => 'Customer password'
      
      option :config,
        :short => '-C CONFIG',
        :long => '--configuration CONFIG',
        :description => 'Hardware configuration string of the server'

      option :name,
        :short => '-n NAME',
        :long => '--name NAME',
        :description => 'Label for the new servers'
        
      option :imageName,
        :short => '-i IMAGE_NAME',
        :long => '--image IMAGE_NAME',
        :description => 'Either baremetalcloud published or customer images'
      
      option :run_list,
        :short => "-r RUN_LIST",
        :long => "--run-list RUN_LIST",
        :description => "Comma separated list of roles/recipes to apply",
        :proc => lambda { |o| o.split(/[\s,]+/) },
        :default => []
          
      

      # Method to check when "system" credentials are available
      # Node's IP Address is updated
      def isNodeReady(serverId)
        
        # Sleep @initial_sleep_delay seconds
        sleep @initial_sleep_delay
        
        # Get server's status
        response = @bmc.get_server(serverId).body 
        
        # 1855 and 1955 have only "system" credentials
        if ( response[:server][:login].class == Hash )
          if ( response[:server][:login][:name] == "system" )
            config[:ssh_user] = response[:server][:login][:username]
            config[:ssh_password] = response[:server][:login][:password]
            config[:chef_node_name] =  response[:server][:ip][:address]
            return true
          end
        elsif ( response[:server][:login].class == Array )  # M600 and M610 have iDRAC credentials
          response[:server][:login].each do |r|
            if ( r[:name] == "system")
              config[:ssh_user] = r[:username]
              config[:ssh_password] = r[:password]
              config[:chef_node_name] =  response[:server][:ip][:address]
              return true
            end
          end
        end
        false
      end

      # Method to test if SSH service is running on a node
      def testSSH(hostname)
        sleep @initial_sleep_delay
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

      # Method to lacate configuration variables
      def locateConfigValue(key)
        key = key.to_sym
        config[key] || Chef::Config[:knife][key]
      end
      
      # Method to configure Knife Bootstrap object
      def bootstrapNode()
        puts "Bootstrapping node id #{locateConfigValue(:chef_node_name)}"
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args = locateConfigValue(:chef_node_name)
        bootstrap.config[:run_list] = locateConfigValue(:run_list)
        bootstrap.config[:identity_file] = locateConfigValue[:identity_file]
        bootstrap.config[:ssh_user] = locateConfigValue(:ssh_user)
        bootstrap.config[:ssh_password] = locateConfigValue(:ssh_password)
        bootstrap.config[:use_sudo] = true unless locateConfigValue[:ssh_user] == 'root'
        bootstrap.config[:environment] = config[:environment]
        bootstrap
      end

      # Method to handle baremetalcloud errors
      def errorHandling(response)
        # Error handling
        unless response[:error].nil?
          puts "#{ui.color("ERROR:", :bold)} #{response[:error][:name]}"
          puts "Description: #{response[:error][:description]}"
          exit 1 
        end
      end

      # Method to add baremetalcloud's node and configure
      def addNode(config, options = {})
        
        # Get the API response
        response = @bmc.add_server_by_configuration(config,options).body
        
        # Error handling
        errorHandling(response)
        
        # get Server id
        serverId = response[:server][:id]
        
        # Loop while server's status is not "Active"
        print "Waiting for server#{serverId} to be ready"
        print(".") until isNodeReady(serverId){
          print "done\n"
        }
        
        # Loop while SSH is not available and sleep @initial_sleep_delay seconds
        print "Connecting to server#{serverId}" 
        print(".") until testSSH(response[:server][:ip][:address]) {
          print "done\n"
        }

      end 

      # Method to verify mandatory arguments
      def verifyArguments
        # Parameters :baremetalcloud_username and :baremetalcloud_password are mandatory
        unless config[:baremetalcloud_username]
          ui.error("--username is a mandatory parameter")
          exit 1
        end
        
        unless config[:baremetalcloud_password]
          ui.error("--password is a mandatory parameter")
          exit 1
        end
        
        unless config[:config]
          ui.error("--configuration is a mandatory parameter")
          exit 1
        end
        
        unless config[:imageName]
          ui.error("--image is a mandatory parameter")
          exit 1
        end

      end
        
      # Plugin method called by Knife
      def run
        
        # sleeptime for testing ssh connectivity
        @initial_sleep_delay = 3

        # Verify mandatory arguments
        verifyArguments
        
        # Configure the API abstraction @bmc
        @bmc = Fog::Compute.new({
          :bare_metal_cloud_username => locateConfigValue(:baremetalcloud_username),
          :bare_metal_cloud_password => locateConfigValue(:baremetalcloud_password),
          :provider => 'BareMetalCloud'
        })
        
        # Options
        options = {
          :imageName => locateConfigValue(:imageName),
          :name => locateConfigValue(:name)
        }
        
        # Add server method
        addNode(locateConfigValue(:config), options)
        
        # Configure bootstrap and trigger "run" to start up
        bootstrapNode().run
        
      end
    end
  end
end