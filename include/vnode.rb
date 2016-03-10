require 'singleton'

class Box
  attr_accessor :name, :user, :pass
  @@default_name="ubuntu/trusty64"
  
  def initialize(user, pass)
    @name = @@default_name
    @user = user
    @pass = pass
  end

end

class Link
  include Singleton
  attr_accessor :link_prefix
  
  def initialize
    seed=init_seed
    pwd=File.basename(Dir.getwd)
    @link_prefix="#{pwd}_#{seed}"
  end
  
  # link_prefix가 항상 unique하도록 하기 위해 현재 디렉토리 명에 추가로 random value를 할당
  # random value가 한 디렉토리 내에서는 항상 동일하도록 하기 위해 파일에 이 값을 저장
  # .seed 파일이 있으면 이를 이용하고, 아니면 새로 할당해 파일에 씀
  def init_seed
    tmp=""
    seed_file=".seed"    
    if File.exists?(seed_file)
      File.open(seed_file, 'rb') { 
        |file| tmp=file.read 
     }
    else
      tmp=rand(1000)
      File.open(seed_file, 'w') { |file| file.write("#{tmp}") }
    end
    
    return tmp
  end   
      
end

class Node
  attr_accessor :switch_type, :switch_ver, :box

  def initialize(hostname, internal_interfaces, cpu, memory, nat_map = nil, synced_folders = nil, bridged_interface = "", bridged_ip = "")
    @hostname=hostname
    @cpu=cpu
    @memory=memory
    @nat_map=nat_map
    @bridged_interface=bridged_interface
    @bridged_ip=bridged_ip
    @synced_folders=synced_folders
    @box = Box.new("vagrant", "vagrant")
    
    # if internal_innterfaces are type of Range, change it to Array
    if internal_interfaces.instance_of? Range
      @interfaces=internal_interfaces.to_a
    else
      @interfaces=internal_interfaces
    end    
  end
  
  def add_shared_folder
  end

  def set_box_name(name)
    @box.name = name
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

  def get_nat_map
    return @nat_map
  end
  
  def get_synced_folders
      return @synced_folders
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
    nat_map           = vm.get_nat_map
    
    # list of interfaces
    interfaces        = vm.get_interfaces
    bridged_interface = vm.get_bridged_interface
    
    # synced_folder
    synced_folders    = vm.get_synced_folders
          
    # box info
    box_name          = vm.box.name
    box_user          = vm.box.user
    box_pass          = vm.box.pass
    
    switch_type       = vm.switch_type
    switch_ver        = vm.switch_ver  
    
    link_prefix=Link.instance.link_prefix
        
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
      # VBoxManage list bridgedifs 로 확인 가능
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
        #v.gui = true
      end
       
      # nat_map = {1 => {"ssh" => 2222 }, 2 => {"web" => 2280}}
      # TODO: avoid port collision
      if (defined? nat_map)
        nat_map.each do |port_name, port_map|        
          port_map.each do |guest_port, host_port|
            cfg.vm.network :forwarded_port, guest: guest_port, host: "#{host_port}", id: "#{port_name}"          
          end
        end
      end
      
      if (defined? synced_folders)
        synced_folders.each do |host_folder, gst_folder|
          cfg.vm.synced_folder "#{host_folder}", "#{gst_folder}", disabled: false
        end
      end    
      
    end
  end
end

def create_switches(switches, config)
  create_vm(switches, "SWITCH", config)   
end

def create_nodes(nodes, config)
  create_vm(nodes, "NODE", config)    
end
