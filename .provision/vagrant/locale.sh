#!/usr/bin/env bash

function generate_locales
{
    declare is_regenerate_required=false
    declare file="/etc/locale.gen"

    for locale in 'de_DE' 'en_GB' 'en_US' 'es_ES' 'fr_FR' 'it_IT'
    do
        declare locale_string="$locale.UTF-8 UTF-8"
        if ! grep -q "^[^#]*$locale_string" "$file"
        then
            is_regenerate_required=true
            if grep -q "^.*#.*$locale_string" "$file"
            then
                # uncomment the locale
                sed -i "s/^.*#.*$locale_string/$locale_string/g" "$file"
	    else
                # add the locale to the end of the file (not sure if it will be able to be generate it)
                echo "$locale_string" >> "$file"
	    fi
        fi
    done

    if ${is_regenerate_required}
    then
        locale-gen
    else
        printf "locales are already installed\n"
    fi
}
generate_locales
