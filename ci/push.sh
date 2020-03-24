#!/bin/bash
export IMAGE_REGISTRY_PUBLISH=true
image_registry_login
if [ -f $build_dir/image_list ]
then
    while read line
    do
        version="${line: -5}"
        if [[ $line != "" ]] && [[ ! $line =~ "index" ]] && [[ $line =~ ":" ]] && [[ $version =~ "[0-9.]*$" ]] 
        then
            newImage="$line-$TRAVIS_CPU_ARCH"
            image_tag $line $newImage
            docker rmi $line
            image_push $newImage
        fi
    done < $build_dir/image_list
fi