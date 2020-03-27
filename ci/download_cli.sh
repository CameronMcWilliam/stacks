#!/bin/bash
# invoked from .travis.yml

if [ "$TRAVIS" == "true" ]
then
    if [ -z "${APPSODY_CLI_RELEASE_URL}" ]
    then
        APPSODY_CLI_RELEASE_URL=https://api.github.com/repos/appsody/appsody/releases/latest
    fi
    if [ -z "${APPSODY_CLI_DOWNLOAD_URL}" ]
    then
        APPSODY_CLI_DOWNLOAD_URL=https://github.com/appsody/appsody/releases/download
    fi
    if [ -z "${APPSODY_CLI_FALLBACK}" ]
    then
        APPSODY_CLI_FALLBACK=0.5.9
    fi

    script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
    base_dir=$(cd "${script_dir}/.." && pwd)

    cli_dir=$base_dir/cli
    mkdir -p $cli_dir

    curl -H "Authorization: token ${GITHUB_READ_TOKEN}" -L -s -o $cli_dir/release.json "$APPSODY_CLI_RELEASE_URL"
    release_tag=$(cat $cli_dir/release.json | grep "tag_name" | cut -d'"' -f4)
    if ! [[ "$release_tag" =~ [0-9]+\.[0-9]+\.[0-9]+ ]]
    then
        echo "Falling back to ${APPSODY_CLI_FALLBACK}"
        cat $cli_dir/release.json
        release_tag=${APPSODY_CLI_FALLBACK}
    fi

    cli_deb="appsody-${release_tag}-linux-${TRAVIS_CPU_ARCH}.tar.gz"
    cli_dist=${APPSODY_CLI_DOWNLOAD_URL}/${release_tag}/${cli_deb}

    echo " release_tag=${release_tag}"
    echo " cli_deb=${cli_deb}"
    echo " cli_dist=${cli_dist}"

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=${TRAVIS_CPU_ARCH}] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update
    sudo apt-get -y -o Dpkg::Options::="--force-confnew" install docker-ce

    sudo snap install yq

    curl -LJO $cli_dist
    mkdir ./appsody-install
    tar zxvf "$cli_deb" --directory ./appsody-install
    sudo mv ./appsody-install/appsody /usr/local/bin
fi
