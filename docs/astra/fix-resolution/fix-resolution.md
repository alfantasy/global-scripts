### 1. 🖥️ Fix Resolution — автоматическая установка разрешения экрана

Скрипт `fix-resolution` поддерживает фиксированное разрешение **1920x1080** (по умолчанию) на всех подключённых мониторах.  
Работает как systemd-сервис, отслеживает изменения конфигурации мониторов и применяет нужные параметры без участия пользователя.

#### 🔧 Возможности:
- Принудительно устанавливает 1920x1080 для всех экранов (можно поменять)
- Отслеживает hotplug (переподключения/переключения мониторов)
- Генерирует xorg-конфиг в `/etc/X11/xorg.conf.d/`
- Создаёт systemd-сервис `resolution-fix.service`
- Создаёт свой конфигурационный файл `/etc/fix-resolution.conf`
- Подмена фиксированных значений:
```bash
fix-resolution --config set RESOLUTION 1280x720 && \
fix-resolution --config set RATE 59
```
- Поддерживает Astra Linux, Fly-DM и headless сценарии

#### 📥 Установка:

```bash
wget -O /usr/local/bin/fix-resolution https://raw.githubusercontent.com/alfantasy/global-scripts/refs/heads/main/astra/fix-resolution && \
sudo chmod +x /usr/local/bin/fix-resolution && \
/usr/local/bin/fix-resolution --help
```

### Примеры использования:
1. Применение конфигурации:
```bash
fix-resolution --start
```
2. Запуск демона:
```bash
fix-resolution --daemon
```
3. Полная инсталляция:
```bash
fix-resolution --install
```
4. Изменение значений:
- Для изменения разрешения, используйте:
```bash
fix-resolution --config set RESOLUTION 1280x720
```
где 1280x720 - новое разрешение, подставьте свое
- Для изменения частоты обновления, используйте:
```bash
fix-resolution --config set RATE 59
```
где 59 - новая частота, подставьте свою
5. Показ текущей конфигурации:
```bash
fix-resolution --config show
```

### Удаление скрипта:
```bash
systemctl disable --now resolution-fix.service && \
rm -f /usr/local/bin/fix-resolution && \
rm -f /etc/X11/xorg.conf.d/10-fixed-resolution.conf && \
rm -f /etc/fix-resolution.conf
```
