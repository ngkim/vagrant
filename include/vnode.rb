class Node
  def initialize(hostname, internal_interfaces, cpu, memory, ssh_nat_port, http_nat_port = -1, novnc_nat_port = -1, bridged_interface = "", bridged_ip = "")
    @hostname=hostname
    @cpu=cpu
    @memory=memory
    @ssh_nat_port=ssh_nat_port
    @http_nat_port=http_nat_port
    @novnc_nat_port=novnc_nat_port
    @bridged_interface=bridged_interface
    @bridged_ip=bridged_ip
    
    # if internal_innterfaces are type of Range, change it to Array
    if internal_interfaces.instance_of? Range
      @interfaces=internal_interfaces.to_a
    else
      @interfaces=internal_interfaces
    end
    
  end

  attr_accessor :switch_type, :switch_ver

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

