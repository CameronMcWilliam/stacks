#!/bin/bash
export IMAGE_REGISTRY_PUBLISH=true
image_registry_login
if [ -f $build_dir/image_list ]
then
    while read line
    do
        if [[ $line != "" ]] && [[ ! $line =~ "index" ]] && [[ line =~ ":" ]]
        then
            newImage="$line-$TRAVIS_CPU_ARCH"
            image_tag $line $newImage
            docker rmi $line
            image_push $newImage
            line=`echo $line | sed -e "s/$line/$newImage/"`
        fi
    done < $build_dir/image_list
    cat $build_dir/image_list
fi
