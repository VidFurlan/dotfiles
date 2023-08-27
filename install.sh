#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd "$SCRIPT_DIR"

# Define the loop_dir function
loop_dir() {
    local exclude_list=("${@:2}")
    local directory="$2"
    local overwrite_all="false"


    if [ -n $irectory ]; then
        mkdir -p $directory
        cd "$1"
    else 
        exit 0
    fi

    count=1

    printf "Copiying files to: \e[0;34m%s\e[0m \n" "${directory}/${file}"

    for file in * .*; do
        if [[ "$file" != "." && "$file" != ".." && ! " ${exclude_list[@]} " =~ " $file " ]]; then
            if [ -e "${directory}/${file}" ]; then
                printf "%-2s)\e[0;31m %-15s \e[0m" "$count" "$file"
            else
                printf "%-2s)\e[0;32m %-15s \e[0m" "$count" "$file"
            fi
            ((count++))
        fi
    done

    printf "\n\n"

    for file in * .*; do
        # Check if the current entry is in the exclude list
        if [[ "$file" != "." && "$file" != ".." && ! " ${exclude_list[@]} " =~ " $file " ]]; then
            if [ "$overwrite_all" = "true" ]; then
                printf "Overwriting '\e[0;33m%s\e[0m'\n" "$file"
                cp -r "$file" $directory

            else
                if [ -e "${directory}/${file}" ]; then
                    printf "The file '\e[0;31m$file\e[0m' already exists! Would you like to overwrite it (y/N/all): "
                    read overwrite

                    if [ "$overwrite" = "Y" ] || [ "$overwrite" = "y" ]; then
                        printf "Overwriting '\e[0;33m%s\e[0m'\n\n" "$file"
                        cp -r "$file" $directory

                    elif [ "$overwrite" = "ALL" ] || [ "$overwrite" = "all" ]; then
                        printf "\n\e[1;31mOverwriting all files!\e[0m\n"
                        printf "Overwriting '\e[0;33m%s\e[0m'\n" "$file"
                        cp -r "$file" $directory

                        overwrite_all="true"
                    else
                        printf "Skipping '%s'\n" "$file"
                    fi
                else
                    printf "Creating '\e[0;32m%s\e[0m'\n" "$file"
                    cp -r "$file" $directory
                fi
            fi
        fi
    done

    echo

    cd "$SCRIPT_DIR" || exit 1
}

# Array of filenames and directory names to exclude
exclude_list_root=("config" "readme.md" "install.sh" ".git")
exclude_list_config=()

loop_dir config "$HOME/.config/" "${exclude_list_config[@]}"
loop_dir . "$HOME/" "${exclude_list_root[@]}"
