#!/bin/bash

# Получение всех устройств с размерами в мегабайтах
mapfile -t disks < <(lsblk -bno NAME,SIZE,TYPE | awk '$3=="disk" { print $1, $2 }')

# Ищем первый диск с LVM
for entry in "${disks[@]}"; do
    disk_name=$(echo "$entry" | awk '{print $1}')
    disk_size=$(echo "$entry" | awk '{print $2}')
    full_path="/dev/$disk_name"

    # Проверка, используется ли диск как физ. том LVM
    if pvs "$full_path" &>/dev/null; then
        LVM_DISK="$full_path"
        LVM_SIZE="$disk_size"
        break
    fi
done

# Проверка, что нашли диск с LVM
if [ -z "$LVM_DISK" ]; then
    echo "Ошибка: не найден диск с LVM."
    exit 1
fi

echo "Найден диск с LVM: $LVM_DISK (размер: $LVM_SIZE байт)"

# Поиск второго диска с тем же размером, но без LVM
for entry in "${disks[@]}"; do
    disk_name=$(echo "$entry" | awk '{print $1}')
    disk_size=$(echo "$entry" | awk '{print $2}')
    full_path="/dev/$disk_name"

    # Пропускаем LVM-диск
    if [ "$full_path" == "$LVM_DISK" ]; then
        continue
    fi

    # Пропускаем диск, если он участвует в LVM
    if pvs "$full_path" &>/dev/null; then
        continue
    fi

    # Сравниваем размер
    if [ "$disk_size" -eq "$LVM_SIZE" ]; then
        MATCHING_DISK="$full_path"
        break
    fi
done

# Проверка, что второй диск найден
if [ -z "$MATCHING_DISK" ]; then
    echo "Ошибка: не найден подходящий второй диск."
    exit 1
fi

echo "Найден второй диск с тем же размером: $MATCHING_DISK"

# Можно экспортировать переменные или использовать их дальше
export LVM_DISK
export MATCHING_DISK
