for process in $(ls /etc/init/nova* | cut -d'/' -f4 | cut -d'.' -f1)
do
	sudo stop ${process}
	sudo start ${process}
done

service libvirt-bin restart
