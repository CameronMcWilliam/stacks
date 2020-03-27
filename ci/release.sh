#!/bin/bash
export DOCKER_CLI_EXPERIMENTAL=enabled
# setup environment
. $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/env.sh

# directory to store assets for test or release
release_dir=$script_dir/release
mkdir -p $release_dir

# expose an extension point for running before main 'release' processing
exec_hooks $script_dir/ext/pre_release.d

if [[ $TRAVIS_CPU_ARCH != "amd64" ]]
then
    travis_terminate 0
fi

# iterate over each asset
for asset in $assets_dir/*
do
    if [[ $asset != *-local.yaml ]]
    then
        echo "Releasing: $asset"
        mv $asset $release_dir
    fi
done

image_registry_login

if [ -f $build_dir/image_list ]
then
    while read line
    do
        if [ "$line" != "" ]
        then
            image_push $line
        fi
    done < $build_dir/image_list
fi

cat $build_dir/manifest_list

if [ -f $build_dir/manifest_list ]
then
    while read line
    do
        prefix="${line:0:5}"
        if [ "${line}" != "" ] && [[ $prefix == "STACK"  ]]
        then   
            stack_full_version=${line#"STACK:"}
            stack_major_minor=${stack_full_version%??}
            stack_major=${stack_major_minor%??}
        elif [ "${line}" != "" ] && [[ $prefix == "ARCHS"  ]]
        then
            archs=${line#"$prefix:"}
            arch_array=($archs)
            if [[ "${#arch_array[@]}" == 3 ]]
            then
               docker manifest create ${IMAGE_REGISTRY_ORG}/$stack_full_version \
               ${TESTING_REGISTRY_ORG}/${stack_full_version}-${arch_array[0]} \
               ${TESTING_REGISTRY_ORG}/${stack_full_version}-${arch_array[1]} \
               ${TESTING_REGISTRY_ORG}/${stack_full_version}-${arch_array[2]} \
               docker manifest push ${IMAGE_REGISTRY_ORG}/$stack_full_version

               docker manifest create ${IMAGE_REGISTRY_ORG}/${stack_major_minor} \
               ${TESTING_REGISTRY_ORG}/${stack_full_version}-${arch_array[0]} \
               ${TESTING_REGISTRY_ORG}/${stack_full_version}-${arch_array[1]} \
               ${TESTING_REGISTRY_ORG}/${stack_full_version}-${arch_array[2]} \
               docker manifest push ${IMAGE_REGISTRY_ORG}/${stack_major_minor}

               docker manifest create ${IMAGE_REGISTRY_ORG}/${stack_major} \
               ${TESTING_REGISTRY_ORG}/${stack_full_version}-${arch_array[0]} \
               ${TESTING_REGISTRY_ORG}/${stack_full_version}-${arch_array[1]} \
               ${TESTING_REGISTRY_ORG}/${stack_full_version}-${arch_array[2]} \
               docker manifest push ${IMAGE_REGISTRY_ORG}/${stack_major}
            elif [[ "${#arch_array[@]}" == 2 ]]
            then
               docker manifest create ${IMAGE_REGISTRY_ORG}/$stack_full_version \
               ${TESTING_REGISTRY_ORG}/${stack_full_version}-${arch_array[0]} \
               ${TESTING_REGISTRY_ORG}/${stack_full_version}-${arch_array[1]}
               docker manifest push ${IMAGE_REGISTRY_ORG}/$stack_full_version

               docker manifest create ${IMAGE_REGISTRY_ORG}/${stack_major_minor} \
               ${TESTING_REGISTRY_ORG}/${stack_full_version}-${arch_array[0]} \
               ${TESTING_REGISTRY_ORG}/${stack_full_version}-${arch_array[1]} \
               docker manifest push ${IMAGE_REGISTRY_ORG}/${stack_major_minor}

               docker manifest create ${IMAGE_REGISTRY_ORG}/${stack_major} \
               ${TESTING_REGISTRY_ORG}/${stack_full_version}-${arch_array[0]} \
               ${TESTING_REGISTRY_ORG}/${stack_full_version}-${arch_array[1]} \
               docker manifest push ${IMAGE_REGISTRY_ORG}/${stack_major}
            elif [[ "${#arch_array[@]}" == 1 ]]
            then
               docker manifest create ${IMAGE_REGISTRY_ORG}/$stack_full_version \
               ${TESTING_REGISTRY_ORG}/${stack_full_version}-${arch_array[0]} \
               docker manifest push ${IMAGE_REGISTRY_ORG}/$stack_full_version

               docker manifest create ${IMAGE_REGISTRY_ORG}/${stack_major_minor} \
               ${TESTING_REGISTRY_ORG}/${stack_full_version}-${arch_array[0]} \
               docker manifest push ${IMAGE_REGISTRY_ORG}/${stack_major_minor}

               docker manifest create ${IMAGE_REGISTRY_ORG}/${stack_major} \
               ${TESTING_REGISTRY_ORG}/${stack_full_version}-${arch_array[0]} \
               docker manifest push ${IMAGE_REGISTRY_ORG}/${stack_major}
            fi
        fi
    done < $build_dir/manifest_list
fi

# expose an extension point for running after main 'release' processing
exec_hooks $script_dir/ext/post_release.d
