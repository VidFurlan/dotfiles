#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

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

    printf "Copiying files to: \e[1;34m%s\e[0m \n" "${directory}/${file}"

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

    printf "\n\nWould you like to pick specific items from the list (y/N): "
    read list
    if [ "$list" = "Y" ] || [ "$list" = "y" ]; then
        printf "\nEnter the item numbers (1 3 4 ...): "
        read list_input
        IFS=' ' read -ra list_items <<<"$list_input"
    fi
    printf "\n"

    count=1

    for file in * .*; do
        # Check if the current entry is in the exclude list
        if [[ "$file" != "." && "$file" != ".." && ! " ${exclude_list[@]} " =~ " $file " ]]; then
            if [ "$list" = "Y" ] || [ "$list" = "y" ]; then
                for item in "${list_items[@]}"; do
                    if [ "$item" = "$count" ]; then
                        if [ -e "${directory}/${file}" ]; then
                            printf "\e[0;31mReplacing\e[0m $file \n"
                        else
                            printf "\e[0;32mCreating\e[0m $file \n"
                        fi
                        #cp -r "$file" $directory
                    fi
                done
            else
                if [ "$overwrite_all" = "true" ]; then
                    printf "Overwriting '\e[0;33m%s\e[0m'\n" "$file"
                    cp -r "$file" $directory

                elif [ "$overwrite_all" = "noall" ]; then
                    cd "$SCRIPT_DIR" || exit 1
                    break

                else
                    if [ -e "${directory}/${file}" ]; then
                        printf "The file '\e[0;31m$file\e[0m' already exists! Would you like to overwrite it (y/N/all/noall): "
                        read overwrite

                        if [ "$overwrite" = "Y" ] || [ "$overwrite" = "y" ]; then
                            printf "Overwriting '\e[0;33m%s\e[0m'\n\n" "$file"
                            cp -r "$file" $directory

                        elif [ "$overwrite" = "ALL" ] || [ "$overwrite" = "all" ]; then
                            printf "\n\e[1;31mOverwriting\e[0m all files!\n"
                            printf "Overwriting '\e[0;33m%s\e[0m'\n" "$file"
                            cp -r "$file" $directory

                            overwrite_all="true"

                        elif [ "$overwrite" = "NOALL" ] || [ "$overwrite" = "noall" ]; then
                            printf "\n\e[1;32mOmittiting\e[0m all files!\n"

                            overwrite_all="noall"

                        else
                            printf "Skipping '%s'\n" "$file"
                        fi
                    else
                        printf "Creating '\e[0;32m%s\e[0m'\n" "$file"
                        cp -r "$file" $directory
                    fi
                fi
            fi
        fi
        
        ((count++))
    done

    echo

    cd "$SCRIPT_DIR" || exit 1
}

# Array of filenames and directory names to exclude
exclude_list_root=("config" "readme.md" "install.sh" ".git")
exclude_list_config=()

loop_dir config "$HOME/.config" "${exclude_list_config[@]}"
loop_dir . "$HOME/" "${exclude_list_root[@]}"
