#!/usr/bin/ruby

hsh = colors = { "red" => 0xf00, "green" => 0x0f0, "blue" => 0x00f }
hsh.each do |key, value|
   print key, " is ", value, "\n"
end

#nodes = {
#    'CTRL'   => [2, 1, 11, 22201],
#    'C-NODE' => [2, 2, 12, 22202],
#    'USER'   => [2, 2, 12, 22203],   
#    'SERVER' => [2, 2, 12, 22204]    
#}

Class Node
  Characters hostname
  Number num_interfaces
  Number ssh_nat_port

  def initialize(hostname, num_interfaces, ssh_nat_port)
    @hostname=hostname
    @num_interfaces=num_interfaces
    @ssh_nat_port=ssh_nat_port
  end

end

ctrl = Node.new("CTRL", 2, 22201)

print "hostname= ", ctrl.hostname, "\n"
print "num_interfaces= ", ctrl.num_interfaces, "\n"
print "ssh_nat_port= ", ctrl.ssh_nat_port, "\n"

#nodes.each do |key, value|
#  print "HOSTNAME= ", key, "\n"
#  value.each do |key1, value1|
    #print key1, "= ", value1, "\n"
#    print key1, "\n"
#  end
#end
