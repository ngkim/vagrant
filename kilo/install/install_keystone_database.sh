#!/bin/bash

mysql -u root -pohhberry3333 -h localhost -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'keystone1234' WITH GRANT OPTION;"
mysql -u root -pohhberry3333 -h localhost -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'keystone1234' WITH GRANT OPTION;"
