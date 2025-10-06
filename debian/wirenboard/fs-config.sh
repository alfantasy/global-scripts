#!/bin/bash

COLOR_RESET="\033[0m"
COLOR_WHITE="\033[1;37m"
COLOR_RED="\033[1;31m"
COLOR_GREEN="\033[1;32m"
COLOR_YELLOW="\033[1;33m"
ER="❌"
SC="✅"
IF="[i]"
WR="[!]"

declare -A dirs_map=(
    ["/usr/share"]="/mnt/data/usr-share"
    ["/var/cache/apt"]="/mnt/data/apt-cache"
    ["/var/log"]="/mnt/data/var-log"
    ["/var/tmp"]="/mnt/data/var-tmp"
    ["/tmp"]="/mnt/data/tmp"
)

# Первое предупреждение
echo -e "$COLOR_WHITE $WR WARNING! This script will move system directories to /mnt/data and create symlinks."
echo -e "$COLOR_WHITE $WR Make sure /mnt/data has enough space and that you understand the operation."
echo -e "$COLOR_WHITE $WR Continue? [y/n]$COLOR_RESET"
read -r proceed
if [ "$proceed" != "y" ]; then
    echo -e "$COLOR_RED $ER Aborted by user.$COLOR_RESET"
    exit 0
fi

# Проверка /mnt/data
if [ ! -d "/mnt/data" ]; then
    echo -e "$COLOR_RED $ER /mnt/data does not exist.$COLOR_RESET"
    exit 1
fi

# Вывод текущего состояния
echo -e "\n$COLOR_WHITE $IF Checking current status of system directories...$COLOR_RESET"
printf "%-20s %-30s %-10s %-10s\n" "System Dir" "Target Dir (/mnt/data)" "Exists" "Symlink"
for sys_dir in "${!dirs_map[@]}"; do
    data_dir="${dirs_map[$sys_dir]}"
    exists="No"
    symlink="No"
    [ -d "$sys_dir" ] && exists="Yes"
    [ -L "$sys_dir" ] && symlink="Yes"
    printf "%-20s %-30s %-10s %-10s\n" "$sys_dir" "$data_dir" "$exists" "$symlink"
done

echo -e "\n$COLOR_WHITE $IF Checking target directories on /mnt/data...$COLOR_RESET"
printf "%-30s %-10s\n" "Target Dir" "Exists"
for data_dir in "${dirs_map[@]}"; do
    exists="No"
    [ -d "$data_dir" ] && exists="Yes"
    printf "%-30s %-10s\n" "$data_dir" "$exists"
done

# Второе подтверждение
echo -e "\n$COLOR_WHITE $WR Above is the current directory mapping. Proceed with operations? [y/n]$COLOR_RESET"
read -r confirm
if [ "$confirm" != "y" ]; then
    echo -e "$COLOR_RED $ER Aborted by user.$COLOR_RESET"
    exit 0
fi

# Основная логика
for sys_dir in "${!dirs_map[@]}"; do
    data_dir="${dirs_map[$sys_dir]}"
    echo -e "\n$COLOR_YELLOW $IF Processing $sys_dir ...$COLOR_RESET"

    # Создание директории на /mnt/data
    if [ ! -d "$data_dir" ]; then
        echo -e "$COLOR_WHITE $IF Create target directory $data_dir? [y/n]$COLOR_RESET"
        read -r ans
        if [ "$ans" == "y" ]; then
            mkdir -p "$data_dir"
            echo -e "$COLOR_GREEN $SC Created $data_dir.$COLOR_RESET"
        else
            echo -e "$COLOR_YELLOW $IF Skipping creation of $data_dir.$COLOR_RESET"
        fi
    fi

    # Перенос содержимого
    if [ -d "$sys_dir" ] && [ "$(ls -A "$sys_dir" 2>/dev/null)" ]; then
        echo -e "$COLOR_WHITE $IF Move contents from $sys_dir to $data_dir? [y/n]$COLOR_RESET"
        read -r ans
        if [ "$ans" == "y" ]; then
            size_needed=$(du -s "$sys_dir" | awk '{print $1}')
            free_space=$(df /mnt/data | tail -1 | awk '{print $4}')
            if [ "$free_space" -lt "$size_needed" ]; then
                echo -e "$COLOR_RED $ER Not enough space for $sys_dir, skipping move.$COLOR_RESET"
            else
                mv "$sys_dir"/* "$data_dir"/ 2>/dev/null
                echo -e "$COLOR_GREEN $SC Contents moved.$COLOR_RESET"
            fi
        else
            echo -e "$COLOR_YELLOW $IF Skipping move for $sys_dir.$COLOR_RESET"
        fi
    fi

    # Удаление оригинальной директории
    if [ -d "$sys_dir" ]; then
        echo -e "$COLOR_WHITE $IF Remove original directory $sys_dir? [y/n]$COLOR_RESET"
        read -r ans
        if [ "$ans" == "y" ]; then
            rmdir "$sys_dir" 2>/dev/null
            echo -e "$COLOR_GREEN $SC Original directory removed.$COLOR_RESET"
        else
            echo -e "$COLOR_YELLOW $IF Skipping removal.$COLOR_RESET"
        fi
    fi

    # Создание симлинка
    if [ ! -L "$sys_dir" ]; then
        echo -e "$COLOR_WHITE $IF Create symlink $sys_dir -> $data_dir? [y/n]$COLOR_RESET"
        read -r ans
        if [ "$ans" == "y" ]; then
            ln -s "$data_dir" "$sys_dir"
            echo -e "$COLOR_GREEN $SC Symlink created.$COLOR_RESET"
        else
            echo -e "$COLOR_YELLOW $IF Skipping symlink.$COLOR_RESET"
        fi
    else
        echo -e "$COLOR_YELLOW $IF $sys_dir is already a symlink.$COLOR_RESET"
    fi
done

echo -e "\n$COLOR_WHITE $IF All done.$COLOR_RESET"