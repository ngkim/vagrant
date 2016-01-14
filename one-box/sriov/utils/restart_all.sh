
# openstack message bus
service rabbitmq-server restart

# openstart mysql
restart mysql

# openstack component
# if keyston is provided by apache, no need to start keystone 
#service keystone restart
service glance-api restart
service glance-registry restart

#cd /etc/init.d/; for i in $( ls nova-* ); do service $i restart; cd /root/;done
#cd /etc/init.d/; for i in $( ls neutron-* ); do service $i restart; cd /root/; done
#cd /etc/init.d/; for i in $( ls cinder-* ); do service $i restart; cd /root/; done
# 위의 restart는 정상동작을 안하는 경우가 가끔 있슴, 특히 nova-compute

for process in $(ls /etc/init/nova* | cut -d'/' -f4 | cut -d'.' -f1)
do
	sudo stop ${process}
	sudo start ${process}
done

for process in $(ls /etc/init/neutron* | cut -d'/' -f4 | cut -d'.' -f1)
do
   if [ "$process" != "neutron-ovs-cleanup" ]; then
	sudo stop ${process}
	sudo start ${process}
   fi
done

for process in $(ls /etc/init/cinder* | cut -d'/' -f4 | cut -d'.' -f1)
do
	sudo stop ${process}
	sudo start ${process}
done

# neutron utils
service openvswitch-switch restart
service dnsmasq restart

# nova utils
service libvirt-bin restart
service dbus restart

# horizon utils
service apache2 restart
service memcached restart

