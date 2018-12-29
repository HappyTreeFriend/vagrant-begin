#!/bin/bash

script_name=$0
min_vbox_ver="5.1.10"
min_vagrant_ver="1.9.0"
min_packer_ver="0.10.0"
min_vagrantreload_ver="0.0.1"
packer_bin="packer"
isOSX=0

function log_show {
    log_msg=$1
    echo $script_name" *** "$1
}

function compare_versions {
    actual_version=$1
    expected_version=$2
    exact_match=$3

    if $exact_match; then
        if [ "$actual_version" == "$expected_version" ]; then
            return 0
        else
            return 1
        fi
    fi

    IFS='.' read -ra actual_version <<< "$actual_version"
    IFS='.' read -ra expected_version <<< "$expected_version"

    for ((i=0; i < ${#expected_version[@]}; i++))
    do
        if [[ ${actual_version[$i]} -gt ${expected_version[$i]} ]]; then
            return 0
        fi

        if [[ ${actual_version[$i]} -lt ${expected_version[$i]} ]]; then
            return 1
        fi
    done
    return 0
}

# Conditional for platform specific version checks. Some of these might seem redundant since
# there might not be anything actively broken in the dependent software. Keeping it around as
# version upgrades could break things on specific platforms.
if [ $(uname) = "Darwin" ]; then
    vagrant_exact_match=false
    isOSX=1
elif [ $(uname) = "Linux" ]; then
    vagrant_exact_match=false
    if (cat /etc/*-release | grep -q 'DISTRIB_ID=Arch')|(cat /etc/os-release | grep -Pq 'ID=(arch|"antergos")'); then
        packer_bin="packer-io"
    fi
fi

if [ -x "$(which VBoxManage)" ] ; then
    current_vbox_ver=$(VBoxManage -v | sed -e 's/r.*//g' -e 's/_.*//g')
    if compare_versions $current_vbox_ver $min_vbox_ver false; then
        log_show "Compatible version of VirtualBox:"$current_vbox_ver" found."
    else
        log_show "A compatible version of VirtualBox was not found."
        log_show "Current Version=[$current_vbox_ver], Minimum Version=[$min_vbox_ver]"
        log_show "Please download and install it from https://www.virtualbox.org/"
        exit 1
    fi
else
    log_show "VirtualBox is not installed (or not added to the path)."
    log_show "Please download and install it from https://www.virtualbox.org/"
    exit 1
fi

if [ $isOSX -eq 1 ]; then
    if compare_versions $($packer_bin -v) "1.2.2" false; then
        log_show "Compatible version of ${packer_bin}:"$($packer_bin -v)"  was found on OSX."
    else
        packer_bin=packer
        if compare_versions $($packer_bin -v) $min_packer_ver false; then
            log_show "Compatible version of ${packer_bin}:"$($packer_bin -v)" was found."
        else
            log_show "The min packer version is 1.2.2"
            log_show "A compatible version of packer was not found. Please install from here: https://github.com/hashicorp/packer/files/1797824/packer.tar.gz"
            exit 1
        fi
    fi
else
    if compare_versions $($packer_bin -v) $min_packer_ver false; then
        log_show "Compatible version of ${packer_bin}:"$($packer_bin -v)" was found."
    else
        packer_bin=packer
        if compare_versions $($packer_bin -v) $min_packer_ver false; then
            log_show "Compatible version of ${packer_bin}:"$($packer_bin -v)" was found."
        else
            log_show "A compatible version of packer was not found. Please install from here: https://www.packer.io/downloads.html"
            exit 1
        fi
    fi
fi

if compare_versions $(vagrant -v | cut -d' ' -f2) $min_vagrant_ver $vagrant_exact_match; then
    log_show "Correct version of vagrant:"$(vagrant -v | cut -d' ' -f2)" was found."
else
    log_show "A compatible version of vagrant was not found. Please download and install it from https://www.vagrantup.com/downloads.html."
    exit 1
fi

if compare_versions $(vagrant plugin list | grep 'vagrant-reload' | cut -d' ' -f2 | tr -d '(' | tr -d ')') $min_vagrantreload_ver false; then
    log_show 'Compatible version of vagrant-reload plugin was found.'
else
    log_show "A compatible version of vagrant-reload plugin was not found."
    log_show "Attempting to install..."
    if vagrant plugin install vagrant-reload; then
        log_show "Successfully installed the vagrant-reload plugin."
    else
        log_show "There was an error installing the vagrant-reload plugin. Please see the above output for more information."
        exit 1
    fi
fi

log_show "All requirements found. Proceeding..."

if ls | grep -q 'autotestav_win2k8_r2_virtualbox.box'; then
    log_show "It looks like the vagrant box already exists. Skipping the Packer build."
else
    log_show "Building the Vagrant box..."
    if PACKER_LOG=1 $packer_bin build --only=virtualbox-iso windows_2008_r2.json; then   # -debug
        log_show "Box successfully built by Packer."
    else
        log_show "Error building the Vagrant box using Packer. Please check the output above for any error messages."
        exit 1
    fi
fi

