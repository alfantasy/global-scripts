#!/bin/bash

# Проверка прав
if [ "$EUID" -ne 0 ]; then
    echo "❌ Этот скрипт должен быть запущен от root." >&2
    exit 1
fi

LOGFILE="/var/log/your_script.log"

# Записываем в лог
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOGFILE"
}

log "🔁 Скрипт запущен от root."

# Ваши действия
log "Выполняется основной блок скрипта..."
# Здесь ваш код

# Добавление в автозагрузку
SERVICE_NAME="your_script"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}.service"

if [ ! -f "$SERVICE_PATH" ]; then
    log "Добавление сервиса в автозагрузку systemd..."

    cat <<EOF > "$SERVICE_PATH"
[Unit]
Description=Custom startup script
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/your_script.sh
User=root
Group=root
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    chmod 644 "$SERVICE_PATH"
    cp "$0" /usr/local/bin/your_script.sh
    chmod +x /usr/local/bin/your_script.sh

    systemctl daemon-reexec
    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME"

    log "✅ Сервис $SERVICE_NAME добавлен в автозагрузку и будет запускаться от root."
else
    log "Сервис уже существует: $SERVICE_NAME"
fi
