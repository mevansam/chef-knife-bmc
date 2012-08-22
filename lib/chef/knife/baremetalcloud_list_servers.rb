  require 'fog'

class Chef
  class Knife
    class BaremetalcloudListServers < Knife
      
      banner "knife baremetalcloud list servers (options)"
      
      option :baremetalcloud_username,
        :short => '-x USERNAME',
        :long => '--username USERNAME',
        :description => 'Customer username'
       
      option :baremetalcloud_password,
        :short => '-P PASSWORD',
        :long => '--password PASSWORD',
        :description => 'Customer password'

      def locate_config_value(key)
        key = key.to_sym
        config[key] || Chef::Config[:knife][key]
      end
      
      def run
        
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
        
        
        response = @bmc.list_servers.body[:server]
        
        if response.length > 1
          response.each do |r|
            puts "#{r[:id]}\t#{r[:state]}\t#{r[:name]}\t#{r[:location]}\t#{r[:ip][:address]}\t#{r[:login][:username]}\t#{r[:login][:password]}"
          end
        end
        
      end
    end
  end
end