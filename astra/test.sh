# Получаем все блоки с типом lvm
mapfile -t lvm_parts < <(lsblk -rpno NAME,TYPE | awk '$2=="lvm" { print $1 }')

if [ ${#lvm_parts[@]} -eq 0 ]; then
    echo "❌ LVM тома не найдены."
    exit 1
fi

# Берем первый раздел с LVM
lvm_part="${lvm_parts[0]}"

# Узнаем родительский диск (например, /dev/sda)
source_disk=$(lsblk -no PKNAME "$lvm_part")

# Узнаем размер исходного диска
source_size=$(lsblk -bno SIZE "/dev/$source_disk")

echo "✅ Найден диск с LVM: /dev/$source_disk (${source_size} байт)"

# Теперь ищем другой диск такой же ёмкости (и с TYPE="disk")
target_disk=""
while read -r name size; do
    if [[ "$name" != "$source_disk" && "$size" == "$source_size" ]]; then
        target_disk="$name"
        break
    fi
done < <(lsblk -bno NAME,SIZE,TYPE | awk '$3=="disk" { print $1, $2 }')

if [[ -n "$target_disk" ]]; then
    echo "✅ Подходящий целевой диск найден: /dev/$target_disk"
else
    echo "❌ Целевой диск такого же размера не найден."
    exit 1
fi
