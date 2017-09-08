#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

export DEBIAN_FRONTEND=noninteractive

function php_version()
{
    if ! which php &>/dev/null
    then
        return 1
    fi

    printf "PHP version:"
    php --version | grep -E -o "PHP [0-9]+\.[0-9]+\.[0-9]+" | sed "s/PHP //"
}

function install_php()
{
    if php_version
    then
        return 0
    fi
    declare -r output_file="$(mktemp -t provision-php.XXXXXXXXXX)"
    printf "> Install PHP 7.1\n"

    for package in 'apt-transport-https' 'lsb-release' 'ca-certificates'
    do
        if ! dpkg --get-selections | grep -q "^$package\s*install$"
        then
            printf "  + Install $package\n"
            apt-get install --yes $package &>"$output_file" || \
                {
                    >&2 printf "An error occurred while installing $package.\n\n"
                    >&2 cat "$output_file"
                    rm "$output_file"

                    return 1
                }
        fi
    done

    declare -r gpg_file="/etc/apt/trusted.gpg.d/php.gpg"
    if ! [[ -f "$gpg_file" ]]
    then
        printf "  + Add PHP apt key\n"
        wget -qO "$gpg_file" https://packages.sury.org/php/apt.gpg &>"$output_file" || \
            {
                >&2 printf "An error occurred while adding PHP apt key.\n\n"
                >&2 cat "$output_file"
                rm "$output_file"

                return 1
            }
    fi

    declare -r apt_file="/etc/apt/sources.list.d/php.list"
    if ! [[ -f "$apt_file" ]]
    then
        printf "  + Add PHP apt source list\n"
        echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" >"$apt_file"
        apt-get update &>"$output_file" || \
            {
                >&2 printf "An error occurred while updating apt source file after adding PHP apt source list.\n\n"
                >&2 cat "$output_file"
                rm "$output_file"

                return 1
            }
    fi

    printf "  + Install PHP from apt\n"
    apt-get install --yes php7.1 &>"$output_file" || \
        {
            >&2 printf "An error occurred while installing PHP from apt source.\n\n"
            >&2 cat "$output_file"
            rm "$output_file"

            return 1
        }

    rm "$output_file"
    php_version
}
install_php

function install_php_extensions()
{
    declare -a extensions=(
        php-redis
        php7.1-bcmath
        php7.1-curl
        php7.1-mbstring
        php7.1-mysql
        php7.1-xdebug
        php7.1-xml
    )

    declare first=true
    declare -r output_file="$(mktemp -t provision-php.XXXXXXXXXX)"
    for extension in "${extensions[@]}"
    do
        if ! dpkg --get-selections | grep "^${extension}\s*install$" >/dev/null
        then
            ${first} && printf "> Install PHP extensions\n"
            first=false

            printf "  + Install $extension\n"
            apt-get install --yes "$extension" &>"$output_file" || \
                {
                    >&2 printf "An error occurred while installing PHP extension $extension.\n\n"
                    >&2 cat "$output_file"
                    rm "$output_file"

                    return 1
                }
        fi
    done

    rm "$output_file"

    return 0
}
install_php_extensions

function manage_xdebug()
{
    declare -r current_directory="$(pwd)"

    cd /usr/local/bin

    if ! [[ -f activate_xdebug ]]
    then
        printf "> Create /usr/local/bin/activate_xdebug"
        cat <<EOF > activate_xdebug
#!/usr/bin/env bash

if ! [[ -e /etc/php/7.1/cli/conf.d/20-xdebug.ini ]]
then
    printf "> Activate xdebug for cli\n"
    ln -s /etc/php/7.1/mods-available/xdebug.ini /etc/php/7.1/cli/conf.d/20-xdebug.ini
else
    >&2 printf "xdebug is already activated for cli.\n"

    exit 1
fi
EOF
        chmod u+x activate_xdebug
    fi

    if ! [[ -f deactivate_xdebug ]]
    then
        printf "> Create /usr/local/bin/deactivate_xdebug"
        cat <<EOF > deactivate_xdebug
#!/usr/bin/env bash

if [[ -e /etc/php/7.1/cli/conf.d/20-xdebug.ini ]]
then
    printf "> Disable xdebug for cli\n"
    rm /etc/php/7.1/cli/conf.d/20-xdebug.ini
else
    >&2 printf "xdebug is already disabled for cli.\n"

    exit 1
fi
EOF
        chmod u+x deactivate_xdebug
        # deactivate only on first provisioning. We don't know if the user activated it intentionally otherwise.
        ./deactivate_xdebug
    fi

    if ! [[ -f toggle_xdebug ]]
    then
        printf "> Create /usr/local/bin/toggle_xdebug"
        cat <<EOF > toggle_xdebug
#!/usr/bin/env bash

if [[ -e /etc/php/7.1/cli/conf.d/20-xdebug.ini ]]
then
    deactivate_xdebug
else
    activate_xdebug
fi
EOF
        chmod u+x toggle_xdebug
    fi
}
manage_xdebug

function install_composer()
{
    declare -r composer_file="/usr/local/bin/composer"
    # php-cs-fixer and phpunit latest versions are not compatible due to sebastian/diff dependency
    declare -a packages=(
        friendsofphp/php-cs-fixer
        phpunit/phpunit:^6.2
        phpstan/phpstan
        jakub-onderka/php-parallel-lint
    )

    if ! [[ -f "$composer_file" ]]
    then
        printf "> Install composer\n"
        php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" >/dev/null
        php composer-setup.php --install-dir=/usr/local/bin --filename=composer >/dev/null
        rm composer-setup.php >/dev/null
        chown vagrant:vagrant /usr/local/bin/composer >/dev/null
    else
        printf "> Upgrade composer\n"
        su vagrant -c "composer --quiet selfupdate"
    fi

    printf "Composer version:"
    su vagrant -c "composer --version | grep -o -E '[0-9]+\.[0-9]+\.[0-9]+'"

    printf "Install or upgrade global composer packages\n"
    for package in "${packages[@]}"
    do
        su vagrant -c "composer --no-ansi global require --no-progress --quiet ${package}" >/dev/null
    done

    if ! grep -q ".composer/vendor/bin" /home/vagrant/.zshrc
    then
        printf "> Add composer bin to zsh PATH\n"
        echo "export PATH=$HOME/.composer/vendor/bin:\$PATH" >> /home/vagrant/.zshrc
    fi

    if ! grep -q ".composer/vendor/bin" /home/vagrant/.bashrc
    then
        printf "> Add composer bin to bash PATH\n"
        echo "export PATH=/home/vagrant/.composer/vendor/bin:\$PATH" >> /home/vagrant/.bashrc
    fi
}
install_composer
