### L2TP/IPSec manager - универсальный специальный скрипт-менеджер для установления клиентского соединения VPN.

Скрипт `l2tp-ipsec-manager` позволяет быстро настроить VPN-соединение L2TP/IPSec с средствами отладки и заготовками, автоматически поднимает и проверяет соединение.
Имеет свой файл конфигурации `/etc/l2tp-ipsec-manager.conf`, где прописываются следующие параметры:
```bash
IPSEC_SERVICE=ipsec # Базовый сервис запуска IPSec // StrongSwan
IPSEC_DAEMON=charon # Базовый демон запуска IPSec // Charon
L2TP_SERVICE=xl2tpd # Базовый сервис запуска L2TP // xl2tpd
LOG_FILE="/var/log/l2tp-ipsec-restart.log" # Файл логов
L2TP_TUNNEL=mytunnel # Имя туннеля L2TP
IPSEC_CONN=myconn # Имя соединения IPSec
IP_SERVER="127.0.0.1" # IP-адрес сервера для восстановления маршрута в PPP-соединении.
```

#### Для запуска скрипта используйте:
```bash
chmod +x l2tp-ipsec-manager.sh
./l2tp-ipsec-manager.sh
```

#### Важно!
Скрипт невыгружаемый и запускается единожды. Автозапуск настраивайте самостоятельно.