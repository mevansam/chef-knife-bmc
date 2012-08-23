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

      def locateConfigValue(key)
        key = key.to_sym
        config[key] || Chef::Config[:knife][key]
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
        
      end
      
      # Plugin method called by Knife
      def run
        
        # Verify mandatory arguments
        verifyArguments
        
        # Configure the API abstraction @bmc
        @bmc = Fog::Compute.new({
          :bare_metal_cloud_username => locateConfigValue(:baremetalcloud_username),
          :bare_metal_cloud_password => locateConfigValue(:baremetalcloud_password),
          :provider => 'BareMetalCloud'
        })
        
        # Get the API response
        response = @bmc.list_images.body
        
        # Error handling
        errorHandling(response)
        
        if response[:image].length > 1
          response[:image].each do |resp|
            puts "#{resp[:size]}\t#{resp[:name]}"
          end
        end
        
      end
    end
  end
end