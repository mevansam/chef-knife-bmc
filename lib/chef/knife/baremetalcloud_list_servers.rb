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
        response = @bmc.list_servers.body
        
        # Error handling
        errorHandling(response)
        
        # only one server
        if ( response[:server].class == Hash ) 
          puts "#{response[:server][:id]}\t#{response[:server][:state]}\t#{response[:server][:name]}\t#{response[:server][:location]}\t#{response[:server][:ip][:address]}\t#{response[:server][:login][:username]}\t#{response[:server][:login][:password]}"
        
        # more than one server
        elsif ( response[:server].class == Array ) 
          response[:server].each do |resp|
            
            # 1855 and 1955 have only "system" credentials
            if ( resp[:login].class == Hash )
              puts "#{resp[:id]}\t#{resp[:state]}\t#{resp[:name]}\t#{resp[:location]}\t#{resp[:ip][:address]}\t#{resp[:login][:username]}\t#{resp[:login][:password]}"
           
            # M600 and M610 have iDRAC credentials
            else
              # Username and password variables
              username = password = nil
              
              # Get only system login. Skip iDRAC
              resp[:login].each do |r|
                if ( r[:name] == "system")
                    username = r[:username]
                    password = r[:password]
                end
              end
              puts "#{resp[:id]}\t#{resp[:state]}\t#{resp[:name]}\t#{resp[:location]}\t#{resp[:ip][:address]}\t#{username}\t#{password}"
              
            end
            
          end
          
        end
        
      end
      
    end
    
  end
  
end