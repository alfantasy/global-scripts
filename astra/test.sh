get_parent_disk_from_lvm() {
    local lv_path="$1"
    local vg_name
    local pv
    local disk

    # Получаем Volume Group
    vg_name=$(lvdisplay "$lv_path" 2>/dev/null | awk -F ': ' '/VG Name/ {print $2}')
    [[ -z "$vg_name" ]] && return 1

    # Получаем Physical Volume, на котором лежит этот VG
    pv=$(pvs --noheadings -o pv_name,vg_name | awk -v vg="$vg_name" '$2 == vg {print $1}' | head -n1)
    [[ -z "$pv" ]] && return 1

    # Получаем родительский диск
    disk=$(lsblk -no PKNAME "$pv" 2>/dev/null)

    if [[ -z "$disk" ]]; then
        # Альтернатива через sysfs
        disk=$(realpath "/sys/class/block/$(basename "$pv")/.." | xargs basename)
    fi

    echo "/dev/$disk"
}

# Получаем все блоки с типом lvm
mapfile -t lvm_parts < <(lsblk -rpno NAME,TYPE | awk '$2=="lvm" { print $1 }')

if [ ${#lvm_parts[@]} -eq 0 ]; then
    echo "❌ LVM тома не найдены."
    exit 1
fi

# Берем первый раздел с LVM
lvm_part="${lvm_parts[0]}"

# Получаем родительский диск
parent_disk=$(get_parent_disk_from_lvm "$lvm_part")

echo "Родительский диск: $parent_disk"