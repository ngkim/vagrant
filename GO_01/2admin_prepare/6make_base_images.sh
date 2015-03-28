#!/bin/bash

echo "
################################################################################
#
#   Install Base Images
#
################################################################################
"

function install_base_images()
{
    echo '
    ----------------------------------------------------------------------------
        install_base_images !!!
    ----------------------------------------------------------------------------
    '
    base_dir="/root/images"
    
    if [[ ! -d $base_dir ]]; then
        echo "홈 디렉토리<$base_dir>에 필수 이미지 파일들이 없습니다"
        exit
    else
        ls -al $base_dir
    fi

#	~% FILE="example.tar.gz"
#	~% echo "${FILE%%.*}"
#	example
#	~% echo "${FILE%.*}"
#	example.tar
#	~% echo "${FILE#*.}"
#	tar.gz
#	~% echo "${FILE##*.}"
#	gz

	# ls $base_dir | cut -d'.' -f1
	for image_file in $( ls $base_dir)
    do
    	echo $image_file
    	image_name=$(basename $image_file .img)    	
        image_id=$(glance image-list | grep "$image_name " | awk '{print $2}')
	    if [ $image_id ]; then
	        echo "# ----------------------------------------------------------------"
	        echo " image[${image_name}] already exist !!!"    
	        echo "# ----------------------------------------------------------------"	        
	    else
	        image_file="${base_dir}/${image_name}.img"
	        if [ -f $image_file ]; then
			    cli="glance image-create --name=$image_name --disk-format=qcow2 --container-format=bare \
                    --is-public=true --file $image_file --progress"
                run_cli_as_admin $cli        
			else
			    echo "# ----------------------------------------------------------------"
			    echo " image_file[${image_file}] does not exist on this host !!!"    
			    echo "# ----------------------------------------------------------------"
			fi			
	        
	    fi            
        
    done
    
            
}
