#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

export DEBIAN_FRONTEND=noninteractive

function upgrade_system()
{
    declare -r output_file="$(mktemp -t provision-system.XXXXXXXXXX)"
    printf "> Upgrade the system\n"

    printf "  + Update package list\n"
    apt-get update &>"$output_file" || \
        {
            >&2 printf "An error occurred while updating package list.\n\n"
            >&2 cat "$output_file"
            rm "$output_file"

            return 1
        }

    printf "  + Upgrade installed packages\n"
    apt-get --yes upgrade &>"$output_file" || \
        {
            >&2 printf "An error occurred while upgrading installed package.\n\n"
            >&2 cat "$output_file"
            rm "$output_file"

            return 1
        }

    printf "  + Purge unnecessary packages\n"

    apt-get purge --yes "apache2" &>"$output_file" || \
        {
            >&2 printf "An error occurred while purging package apache2.\n\n"
            >&2 cat "$output_file"
            rm "$output_file"

            return 1
        }

    [[ -d /var/www ]] && rm --recursive /var/www
    [[ -d /etc/php/7.1/apache2 ]] && rm --recursive /etc/php/7.1/apache2

    printf "  + Remove no longer used packages\n"
    apt-get --yes autoremove &>"$output_file" || \
        {
            >&2 printf "An error occurred while removing no longer used packages.\n\n"
            >&2 cat "$output_file"
            rm "$output_file"

            return 1
        }

    rm "$output_file"

    return 0
}
upgrade_system

