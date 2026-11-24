#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -P "$(dirname "$0")" && pwd)
jenkins_home="$script_dir/../../war/work"
force=0

while [ "$#" -gt 0 ]; do
    case "$1" in
        --jenkins-home)
            if [ "$#" -lt 2 ] || [ -z "$2" ]; then
                printf '%s\n' 'Error: --jenkins-home requires a directory.' >&2
                exit 2
            fi
            jenkins_home=$2
            shift 2
            ;;
        --force)
            force=1
            shift
            ;;
        --help|-h)
            printf '%s\n' 'Usage: sh initialize-jenkins-mirror.sh [--jenkins-home DIRECTORY] [--force]'
            exit 0
            ;;
        *)
            printf 'Error: unknown argument: %s\n' "$1" >&2
            exit 2
            ;;
    esac
done

case "$jenkins_home" in
    /*) ;;
    *) jenkins_home="$PWD/$jenkins_home" ;;
esac

config_source="$script_dir/hudson.model.UpdateCenter.xml"
cert_source="$script_dir/huawei-mirror-leops.crt"
for source_file in "$config_source" "$cert_source"; do
    if [ ! -f "$source_file" ]; then
        printf 'Error: missing source file: %s\n' "$source_file" >&2
        exit 1
    fi
done

mkdir -p "$jenkins_home/update-center-rootCAs"

install_file() {
    source_file=$1
    destination=$2

    if [ -e "$destination" ] || [ -L "$destination" ]; then
        if [ "$force" -eq 0 ]; then
            printf 'Preserved existing file: %s\n' "$destination"
            return
        fi
        if [ ! -f "$destination" ] || [ -L "$destination" ]; then
            printf 'Error: refusing to overwrite a non-regular file: %s\n' "$destination" >&2
            exit 1
        fi
    fi

    cp "$source_file" "$destination"
    printf 'Installed: %s\n' "$destination"
}

install_file "$config_source" "$jenkins_home/hudson.model.UpdateCenter.xml"
install_file "$cert_source" "$jenkins_home/update-center-rootCAs/huawei-mirror-leops.crt"
