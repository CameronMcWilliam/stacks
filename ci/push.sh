#!/bin/bash
export IMAGE_REGISTRY_PUBLISH=true
image_registry_login
if [ -f $build_dir/image_list ]
then
    while read line
    do
        if [ "$line" != "" ] && ["$line" != *"index"*] && ["$line" != *"index"]
        then
            newImage="$line-$TRAVIS_CPU_ARCH"
            image_tag $line $newImage
            image_push $newImage
            docker rmi $line
        fi
    done < $build_dir/image_list
fi