class Vagrant

  def initialize()
    VAGRANTFILE_API_VERSION = "2"

  def configure(switches, nodes)
    ###############################################################################
    # IMPORTANT: use your own link_prefix to avoid duplication error 
    # with other vagrant instances
    # use current directory name as link_prefix 
    @link_prefix=File.basename(Dir.getwd)

    # Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
    Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
      prepare_switch(config, switches)
      prepare_host(config, nodes)
    end
  end
 
  def prepare_switch(config, switches)  
    switches.each do | switch |
      hostname        	= switch.get_hostname
      ssh_nat_port    	= switch.get_ssh_nat_port
      interfaces      	= switch.get_interfaces
      bridged_interface   = switch.get_bridged_interface
      cpu         	= switch.get_cpu
      memory      	= switch.get_memory
      switch_type         = switch.switch_type
      switch_ver          = switch.switch_ver
  
      interface_count = interfaces.length
      if bridged_interface != ""
        interface_count += 1
      end
   
      config.vm.define "#{hostname}" do |cfg_sw|
        cfg_sw.vm.box = "ubuntu/trusty64"
        cfg_sw.vm.boot_timeout = 90
  
        cfg_sw.ssh.username = "vagrant"
        cfg_sw.ssh.password = "vagrant"
      
        for i in interfaces
          cfg_sw.vm.network "private_network", auto_config: false, virtualbox__intnet: "#{@link_prefix}_switch_interface_#{i}"     
        end
  
        # bridged interface to have external network connectivity
        if bridged_interface != ""
          cfg_sw.vm.network "public_network", auto_config: false, bridge: "#{bridged_interface}"
        end
  
        if switch_type != ""
          cfg_sw.vm.provision :shell, :path => "../common/install_#{switch_type}_#{switch_ver}.sh"
        end
  
        if File.exist?("init_node_#{hostname}.sh")
          cfg_sw.vm.provision :shell, :path => "init_node_#{hostname}.sh"
        end
  
        cfg_sw.vm.provider "virtualbox" do |v|
          v.cpus = cpu
          v.memory = memory
          v.customize ["modifyvm", :id, "--hpet", "on"]
        
          # 스위칭에 이용하는 인터페이스에 대해서 promiscuous mode를 allow vms로 설정해줌
          for i in 2..(interface_count + 1)
            v.customize ["modifyvm", :id, "--nicpromisc#{i}", "allow-all"]                      
          end
          #v.gui = true
        end
  
        if ssh_nat_port != -1
          cfg_sw.vm.network :forwarded_port, guest: 22, host: "#{ssh_nat_port}", id: "ssh"
        end
        cfg_sw.vm.synced_folder "../common", "/root/common", disabled: false
      end
  
    end
  end
 
  def prepare_host(config, nodes)  
    nodes.each do | node |
      hostname 		= node.get_hostname
      cpu 	        = node.get_cpu
      memory 	        = node.get_memory
      ssh_nat_port 	= node.get_ssh_nat_port
      http_nat_port 	= node.get_http_nat_port
      novnc_nat_port 	= node.get_novnc_nat_port
      interfaces 		= node.get_interfaces
      bridged_interface   = node.get_bridged_interface
      bridged_ip          = node.get_bridged_ip
  
      interface_count	= interfaces.length 
   
      config.vm.define "#{hostname}" do |cfg_node|
        cfg_node.vm.box = "ubuntu/trusty64"
        cfg_node.vm.boot_timeout = 300
  
        # Run our shell script on provisioning
        if File.exist?("init_node_#{hostname}.sh")
          cfg_node.vm.provision :shell, :path => "init_node_#{hostname}.sh"
        end
    	
        # 여러 개의 인터페이스를 할당
        # 하나의 VM에 최대 생성 가능한 8개 인터페이스 중 첫 번째는 NAT, 나머지 7개에 대해서 다른 VM과의 연결을 고려하여 연결
        for i in interfaces
          cfg_node.vm.network "private_network", auto_config: false, virtualbox__intnet: "#{@link_prefix}_switch_interface_#{i}"  	
        end
  
        if bridged_interface != ""
          if bridged_ip != ""
            cfg_node.vm.network "public_network", ip: "#{bridged_ip}", bridge: "#{bridged_interface}"
          else
            cfg_node.vm.network "public_network", auto_config: false, bridge: "#{bridged_interface}"
          end
        end
    
        cfg_node.vm.provider "virtualbox" do |v|
          for i in 2..(interface_count+1)
    	  v.customize ["modifyvm", :id, "--nicpromisc#{i}", "allow-all"]  	        	      
        	end
    	v.customize ["modifyvm", :id, "--hpet", "on"]
          #v.gui = true
          v.memory = memory
          v.cpus = cpu
        end  	  
  
        if ssh_nat_port != -1
          cfg_node.vm.network :forwarded_port, guest: 22, host: "#{ssh_nat_port}", id: "ssh"  
        end
      end
    end
  end 
end
