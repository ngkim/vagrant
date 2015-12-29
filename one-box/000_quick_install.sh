#!/bin/bash

cd install

nohup ./000_quick_install.sh auto > install.log 2>&1 &
	
cd -

