require 'fog'

class Chef
  class Knife
    class BaremetalcloudListImages < Knife
      
      banner "knife baremetalcloud list images (options)"
      
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
        
        response = @bmc.list_images.body[:image]
        if response.length > 1
          #puts "#{ui.color("Id", :cyan)}\t#{ui.color("Name", :cyan)}\t#{ui.color("Size", :cyan)}"
          response.each do |r|
            puts "#{r[:id]}\t#{r[:name]}\t#{r[:size]}"
          end
        end
        
      end
    end
  end
end