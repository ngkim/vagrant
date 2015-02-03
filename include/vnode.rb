class Node
  def initialize(hostname, internal_interfaces, cpu, memory, ssh_nat_port, http_nat_port = -1, bridged_interface = "")
    @hostname=hostname
    @interfaces=internal_interfaces
    @cpu=cpu
    @memory=memory
    @ssh_nat_port=ssh_nat_port
    @http_nat_port=http_nat_port
    @bridged_interface=bridged_interface
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

  def get_bridged_interface
    return @bridged_interface
  end
end

