#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

cd "$SCRIPT_DIR"

# Define the loop_dir function
loop_dir() {
    all_files=()
    selected_files=()

    local exclude_list=("${@:2}")
    local directory="$2"

    if [ -n $irectory ]; then
        mkdir -p $directory
        cd "$1"
    else
        exit 0
    fi

    local i=1

    printf "\nCopying files to: %s\n\n" "${directory}"

    for file in * .*; do
        if [[ "$file" != "." && "$file" != ".." && ! " ${exclude_list[@]} " =~ " $file " ]]; then
            all_files+=($file)
            ((i++))
        fi
    done

    create_menu ${all_files[@]}

    local i_valid_files=0
    i=0

    for file in * .*; do
        # Check if the current entry is in the exclude list
        if [[ "$file" != "." && "$file" != ".." && ! "${exclude_list[@]}" =~ "$file" ]]; then
            if [[ "${selected_files[$i_valid_files]}" = "true" ]]; then
                if [ -e "${directory}/${file}" ]; then
                    printf "\e[0;31mReplacing\e[0m $file \n"
                else
                    printf "\e[0;32mCreating\e[0m $file \n"
                fi
                cp -r "$file" $directory
            fi
            ((i_valid_files++))
        fi
        
        ((i++))
    done

    cd "$SCRIPT_DIR" || exit 1
}

# Menu from https://unix.stackexchange.com/a/673436/580282
create_menu() {
    local my_options=("${all_files[@]}")


    local preselection=()

    multiselect result my_options preselection

    selected_files=("${result[@]}")
}

# Multichoice interactable menu
function multiselect() {
    # little helpers for terminal print control and key input
    ESC=$( printf "\033")
    cursor_blink_on()   { printf "$ESC[?25h"; }
    cursor_blink_off()  { printf "$ESC[?25l"; }
    cursor_to()         { printf "$ESC[$1;${2:-1}H"; }
    print_inactive()    { printf "$2   $1 "; }
    print_active()      { printf "$2  $ESC[7m $1 $ESC[27m"; }
    get_cursor_row()    { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }

    local return_value=$1
    local -n options=$2
    local -n defaults=$3

    local selected=()
    for ((i=0; i<${#options[@]}; i++)); do
        if [[ ${defaults[i]} = "true" ]]; then
            selected+=("true")
        else
            selected+=("false")
        fi
        printf "\n"
    done

    # determine current screen position for overwriting the options
    local lastrow=`get_cursor_row`
    local startrow=$(($lastrow - ${#options[@]}))

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    key_input() {
        local key
        IFS= read -rsn1 key 2>/dev/null >&2
        if [[ $key = ""      ]]; then echo enter; fi;
        if [[ $key = $'\x20' ]]; then echo space; fi;
        if [[ $key = "k" ]]; then echo up; fi;
        if [[ $key = "j" ]]; then echo down; fi;
        if [[ $key = $'\x1b' ]]; then
            read -rsn2 key
            if [[ $key = [A || $key = k ]]; then echo up;    fi;
            if [[ $key = [B || $key = j ]]; then echo down;  fi;
        fi 
    }

    toggle_option() {
        local option=$1
        if [[ ${selected[option]} == true ]]; then
            selected[option]=false
        else
            selected[option]=true
        fi
    }

    print_options() {
        # print options by overwriting the last lines
        local idx=0
        for option in "${options[@]}"; do
            local prefix="[ ]"
            if [[ ${selected[idx]} == true ]]; then
              prefix="[\e[0;32m*\e[0m]"
            fi

            cursor_to $(($startrow + $idx))
            if [ $idx -eq $1 ]; then
                print_active "$option" "$prefix"
            else
                print_inactive "$option" "$prefix"
            fi
            ((idx++))
        done
    }

    local active=0
    while true; do
        print_options $active

        # user key control
        case `key_input` in
            space)  toggle_option $active;;
            enter)  print_options -1; break;;
            up)     ((active--));
                    if [ $active -lt 0 ]; then active=$((${#options[@]} - 1)); fi;;
            down)   ((active++));
                    if [ $active -ge ${#options[@]} ]; then active=0; fi;;
        esac
    done

    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    eval $return_value='("${selected[@]}")'
}

# Find os pacakge manager
function get_pacakge_manager {
    declare -A osInfo;
    osInfo[/etc/redhat-release]=yum
    osInfo[/etc/arch-release]=pacman
    osInfo[/etc/gentoo-release]=emerge
    osInfo[/etc/SuSE-release]=zypp
    osInfo[/etc/debian_version]=apt-get
    osInfo[/etc/alpine-release]=apk
}

function install_packages {
    if [[pacakge_manager = "pacman"]]; then
        echo $pacakge_manager
    fi
}


printf " 
\e[0;32m██████╗  ██████╗ ████████╗███████╗
██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝
██║  ██║██║   ██║   ██║   ███████╗
██║  ██║██║   ██║   ██║   ╚════██║
██████╔╝╚██████╔╝   ██║   ███████║
╚═════╝  ╚═════╝    ╚═╝   ╚══════╝\e[0m
Made by \e[1;32mVid Furlan\e[0m
"

# Package list
package_list=("i3" "picom" "polybar" "rofi" "terminator")

# Array of filenames and directory names to exclude
exclude_list_root=("desktop" "terminal" "readme.md" "install.sh" ".git")
exclude_list_config=()

#           From:       To:                 Files to exclude:
printf "\n----------------------------\e[1;34m Desktop \e[0m----------------------------"
loop_dir    desktop     "$HOME/.config"     "${exclude_list_config[@]}"

printf "\n---------------------------\e[1;34m Terminal \e[0m----------------------------"
loop_dir    terminal    "$HOME/.config"     "${exclude_list_config[@]}"

printf "\n-----------------------------\e[1;34m Other \e[0m-----------------------------"
loop_dir    .           "$HOME/"            "${exclude_list_root[@]}"

printf "\n-----------------------------\e[1;34m Fonts \e[0m-----------------------------"
loop_dir    fonts       "/usr/share/fonts/" "${exclude_list_config[@]}"

get_pacakge_manager
install_packages