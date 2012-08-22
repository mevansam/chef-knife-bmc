require 'fog'

class Chef
  class Knife
    class BaremetalcloudListAvailableServers < Knife
      
      banner "knife baremetalcloud list available servers (options)"
      
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
          :bare_metal_cloud_username => config[:baremetalcloud_username],
          :bare_metal_cloud_password => config[:baremetalcloud_password],
          :provider => 'BareMetalCloud'
        })
        
        response = @bmc.list_available_servers.body[:"available-server"]
        
       if response.length > 1
          #puts "#{ui.color("String", :cyan)}\t#{ui.color("Quantity", :cyan)}"
          response.each do |r|
            puts "#{r[:configuration]}\t#{r[:quantity]}"
          end
        end
        
      end
    end
  end
end