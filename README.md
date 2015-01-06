baremetalcloud's Knife plugin
===========================

This is baremetalcloud's implementation for Chef's Knife command. The plugin allows Chef users to manage compute nodes on baremetalcloud's infrastructure. This is a clone of the original which can be found [here](https://github.com/baremetalcloud/knife-baremetalcloud).

Installation
------------

Add this line to your application's Gemfile:

    gem 'knife-bmc'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install knife-bmc

Usage
-----

## Available commands:
    knife baremetalcloud list configurations (options)
    knife baremetalcloud list images (options)
    knife baremetalcloud list servers (options)
    knife baremetalcloud server create (options)

### List Configurations
#### Description
This command list all available server's configurations at baremetalcloud.


#### Parameters
-P, --password PASSWORD          Customer password
-x, --username USERNAME          Customer username

#### Usage
    $ knife baremetalcloud list configurations -x USERNAME -P PASSWORD

#### Example of Output
Column description:
<table>
  <tr>
    <th>quantity</th><th>configuration</th>
  </tr>
</table>
- *configuration* string is a required argument when running command($ knife baremetalcloud server create).

```
19	santaclara-ca-usa 2.8 GHz Paxville 2GB DDR-400 73.0GB 3.5" SCSI 10000RPM
4	santaclara-ca-usa 2.66 GHz Clovertown X5355 8GB DDR2-667 250.0GB 2.5" SATA 7200RPM
4	santaclara-ca-usa 2.8 GHz Paxville 4GB DDR-400 73.0GB 3.5" SCSI 10000RPM
5	santaclara-ca-usa 2.66 GHz Woodcrest E5150 8GB DDR2-667 250.0GB 2.5" SATA 7200RPM
1	miami-fl-usa 2.0 GHz Gainestown E5504 48GB DDR3-1066 120.0GB 2.5" SATA 7200RPM
3	santaclara-ca-usa 2.66 GHz Clovertown X5355 8GB DDR-400 500.0GB 2.5" SATA 7200RPM
9	santaclara-ca-usa 2.66 GHz Woodcrest E5150 4GB DDR-400 73.0GB 2.5" SAS 10000RPM
1	miami-fl-usa 2.8 GHz Paxville 8GB DDR-400 73.0GB 3.5" SCSI 10000RPM
```

### List Images
#### Description
This command lists all the available images with baremetalcloud.

#### Parameters
-P, --password PASSWORD          Customer password
-x, --username USERNAME          Customer username

#### Usage
    $ knife baremetalcloud list images -x USERNAME -P PASSWORD

#### Example of Output
Column description:
<table>
  <tr>
    <th>image size</th><th>image name</th>
  </tr>
</table>
- *image name* string is a required argument when running command($ knife baremetalcloud server create).
```
361M	CentOS 5.8
565M	CentOS 6.2
319M	XenServer 5.6 SP2
321M	Ubuntu 11.10
441M	Ubuntu 12.04
6.1G	Windows Server 2008 Standard
3.7G	Windows Server 2003 Standard R2
183M	SmartOS
```

### List Servers
#### Description
This command lists all servers from a customers account with baremetalcloud.


#### Parameters
-P, --password PASSWORD          Customer password
-x, --username USERNAME          Customer username

#### Usage
    $ knife baremetalcloud list servers -x USERNAME -P PASSWORD

#### Example of Output
Column description:
<table>
  <tr>
    <th>id</th><th>status</th><th>name</th><th>location</th><th>IP</th><th>username</th><th>password</th>
  </tr>
</table>
```
1234	Active	server-baa	miami-fl-usa	111.222.333.444	ubuntu	PASSWORD
5678	Active	server-foo	miami-fl-usa	555.666.777.888	root	PASSWORD
```

### Server Create
#### Description
The command below will add a server with baremetalcloud and bootstrap.

#### Parameters
-P, --password PASSWORD          Customer password
-x, --username USERNAME          Customer username
-C, --configuration CONFIG       Hardware configuration string of the server
-i, --image IMAGE_NAME           Either baremetalcloud published or customer images
-n, --name NAME                  Label for the new servers
-r, --run-list RUN_LIST          Comma separated list of roles/recipes to apply

#### Usage
    $ knife baremetalcloud list images -x USERNAME -P PASSWORD -C 'santaclara-ca-usa 2.8 GHz Paxville 2GB DDR-400 73.0GB 3.5" SCSI 10000RPM' -i 'CentOS 5.8' -n 'myChefServer' -r 'myrole[cookbook]'


Contributing
------------

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
