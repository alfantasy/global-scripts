🤖 Waydroid Installer - универсальный установщик Waydroid - контейнера Android на основе LXC.

Скрипт `waydroid-installer.sh` автоматически заносит все необходимые изменения для Waydroid в систему, добавляя их репозиторий в apt, полностью автоматизируя процесс установки ПО.
Скрипт выполняется единожды и не требует вмешательства пользователя.

#### 🔧 Возможности:
- Проверка наличия включенной вложенной/нативной виртуализации
- Добавление репозитория Waydroid
- Установка необходимых пакетов и их обновление
- Установка Waydroid
- Вспомогательная справка

#### 📥 Установка и автозапуск:
```bash
wget -O waydroid-installer.sh https://raw.githubusercontent.com/alfantasy/global-scripts/refs/heads/main/debian/waydroid-installer.sh && \
sudo chmod +x waydroid-installer.sh && \
./waydroid-installer.sh
```

#### 📥  Только скачивание:
```bash
wget -O waydroid-installer.sh https://raw.githubusercontent.com/alfantasy/global-scripts/refs/heads/main/debian/waydroid-installer.sh
```
