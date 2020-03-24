#!/bin/bash
export IMAGE_REGISTRY_PUBLISH=true
image_registry_login
if [ -f $build_dir/image_list ]
then
    declare -a stacks
    while read line
    do
        if [[ $line != "" ]] && [[ $line =~ ":" ]]
        then
        version="${line: -5}"
        regex='^[0-9]+\.[0-9]+\.[0-9]'
        stack=$(echo $line | awk -F"[/]" '{print $2}')
            if  [[ ! $line =~ "index" ]] && [[ $version =~ $regex ]] && [[ ! ${stacks[*]} =~ "$stack" ]]
            then
                newImage="$line-$TRAVIS_CPU_ARCH"
                image_tag $line $newImage
                docker rmi $line
                image_push $newImage
                stacks=( "${stacks[@]}" "$stack" )
            fi
        fi
    done < $build_dir/image_list
fi
{ [ "${#stacks[@]}" -eq 0 ] || printf '%s\n' "${stacks[@]}"; } > $build_dir/manifest_list
cat manifest_list