class Box
  attr_accessor :name, :user, :pass
  
  def initialize(name, user, pass)
    @name = name
    @user = user
    @pass = pass
  end
end

class Node
  attr_accessor :switch_type, :switch_ver, :box

  def initialize(hostname, internal_interfaces, cpu, memory, ssh_nat_port, http_nat_port = -1, novnc_nat_port = -1, bridged_interface = "", bridged_ip = "")
    @hostname=hostname
    @cpu=cpu
    @memory=memory
    @ssh_nat_port=ssh_nat_port
    @http_nat_port=http_nat_port
    @novnc_nat_port=novnc_nat_port
    @bridged_interface=bridged_interface
    @bridged_ip=bridged_ip
    @box = Box.new("ubuntu/trusty64", "vagrant", "vagrant")
    
    # if internal_innterfaces are type of Range, change it to Array
    if internal_interfaces.instance_of? Range
      @interfaces=internal_interfaces.to_a
    else
      @interfaces=internal_interfaces
    end    
  end
  
  def get_hostname
    return "#{@hostname}"
  end

  def get_interfaces
    return @interfaces
  end

  def get_cpu
    return @cpu
  end

  def get_memory
    return @memory
  end

  def get_ssh_nat_port
    return @ssh_nat_port
  end

  def get_http_nat_port
    return @http_nat_port
  end

  def get_novnc_nat_port
    return @novnc_nat_port
  end

  def get_bridged_interface
    return @bridged_interface
  end

  def get_bridged_ip
    return @bridged_ip
  end
  
end

# vm_type: SWITCH or NODE
def create_vm(vms, vm_type, config)
  vms.each do | vm |
    hostname          = vm.get_hostname
    
    # cpu & memory
    cpu               = vm.get_cpu
    memory            = vm.get_memory
    
    # nat port
    ssh_nat_port      = vm.get_ssh_nat_port
    http_nat_port     = vm.get_http_nat_port
    novnc_nat_port    = vm.get_novnc_nat_port            
    
    # list of interfaces
    interfaces        = vm.get_interfaces
    bridged_interface = vm.get_bridged_interface
          
    # box info
    box_name          = vm.box.name
    box_user          = vm.box.user
    box_pass          = vm.box.pass
    
    switch_type       = vm.switch_type
    switch_ver        = vm.switch_ver  
    
    # IMPORTANT: use your own link_prefix to avoid duplication error with other vagrant instances
    link_prefix=File.basename(Dir.getwd)
        
    interface_count = interfaces.length
    if bridged_interface != ""
      interface_count += 1
    end
        
    config.vm.define "#{hostname}" do |cfg|
      cfg.vm.box = box_name
      cfg.vm.boot_timeout = 90
            
      cfg.ssh.username = box_user
      cfg.ssh.password = box_pass
          
      for i in interfaces
        cfg.vm.network "private_network", auto_config: false, virtualbox__intnet: "#{link_prefix}_switch_interface_#{i}"     
      end
          
      # bridged interface to have external network connectivity
      if bridged_interface != ""
        cfg.vm.network "public_network", auto_config: false, bridge: "#{bridged_interface}"
      end
          
      #if switch_type != ""
      #  cfg.vm.provision :shell, :path => "../common/install_#{switch_type}_#{switch_ver}.sh"
      #end
          
      if File.exist?("init_node_#{hostname}.sh")
        cfg.vm.provision :shell, :path => "init_node_#{hostname}.sh"
      end
          
      cfg.vm.provider "virtualbox" do |v|
        v.cpus = cpu
        v.memory = memory
        v.customize ["modifyvm", :id, "--hpet", "on"]
                    
        # 스위칭에 이용하는 인터페이스에 대해서 promiscuous mode를 allow vms로 설정해줌
        for i in 2..(interface_count + 1)
          v.customize ["modifyvm", :id, "--nicpromisc#{i}", "allow-all"]                      
        end
        v.gui = true
      end
          
      if ssh_nat_port != -1
        cfg.vm.network :forwarded_port, guest: 22, host: "#{ssh_nat_port}", id: "ssh"
      end
      
      if http_nat_port != -1
        cfg.vm.network :forwarded_port, guest: 80, host: "#{http_nat_port}", id: "http"  
      end
      
      if novnc_nat_port != -1
        cfg.vm.network :forwarded_port, guest: 6080, host: "#{novnc_nat_port}", id: "novnc"  
      end
                  
      cfg.vm.synced_folder "../common", "/root/common", disabled: false
    end
  end
end

def create_switches(switches, config)
  create_vm(switches, "SWITCH", config)   
end

def create_nodes(nodes, config)
  create_vm(nodes, "NODE", config)    
end
