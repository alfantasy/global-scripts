XUSER=$(loginctl list-sessions | awk '$1 ~ /^[0-9]+$/ { print $1 }' | while read session; do
    user=$(loginctl show-session $session -p User --value)
    active=$(loginctl show-session $session -p Active --value)
    if [[ "$active" == "yes" ]]; then
        echo "$user"
        break
    fi
done)

echo "Используется пользователь: $XUSER"