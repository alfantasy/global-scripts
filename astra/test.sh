get_parent_disk_from_lvm() {
    local lv_mapper_path="$1"
    local lv_path
    local vg_name
    local pv
    local disk

    echo "[i] Поиск VG для LVM тома: $lv_mapper_path">&2

    # Преобразуем /dev/mapper/VG235-lv_home → /dev/VG235/lv_home
    lv_path=$(echo "$lv_mapper_path" | sed 's|^/dev/mapper/|/dev/|' | sed 's|-|/|')

    vg_name=$(lvdisplay "$lv_path" 2>/dev/null | awk -F ' ' '/VG Name/ {print $3}')
    if [[ -z "$vg_name" ]]; then
        echo "❌ VG не найден для $lv_path">&2
        return 1
    fi

    echo "[i] Обнаружена VG: $vg_name">&2

    pv=$(pvs --noheadings -o pv_name,vg_name | awk -v vg="$vg_name" '$2 == vg {print $1}' | head -n1)
    if [[ -z "$pv" ]]; then
        echo "❌ Physical volume не найден для VG: $vg_name">&2
        return 1
    fi

    echo "[i] Физический раздел: $pv">&2

    disk=$(lsblk -no PKNAME "$pv" | head -n1 2>/dev/null)

    if [[ -z "$disk" ]]; then
        echo "❌ Не удалось определить родительский диск.">&2
        return 1
    fi

    echo "/dev/$disk"
}

# Поиск LVM-устройств
mapfile -t lvm_parts < <(lsblk -rpno NAME | grep '/dev/mapper/')

if [ ${#lvm_parts[@]} -eq 0 ]; then
    echo "❌ LVM тома не найдены через /dev/mapper/.">&2
    exit 1
fi

lvm_part="${lvm_parts[0]}"
echo "[i] Найден LVM: $lvm_part"

parent_disk=$(get_parent_disk_from_lvm "$lvm_part")

if [[ -n "$parent_disk" ]]; then
    echo "✅ Родительский диск: $parent_disk"
    echo "Идем дальше?"
else
    echo "❌ Не удалось определить диск."
fi

mapfile -t parent_parts < <(lsblk -ln -o PATH,TYPE "$parent_disk" | awk '$2 == "part" {print $1}')

for part in "${parent_parts[@]}"; do
    echo "🔹 Раздел: $part"
done