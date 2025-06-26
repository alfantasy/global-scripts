install_waydroid() {
    echo -e "\033[94mПроверка доступности пакетов...\033[0m"
    APT_UPDATE=$(apt-get update >/dev/null 2>&1 && echo "1" || echo "0")
    STEP_UPDATE_APT="0"
    STEP_INSTALL_REQUIRED="0"
    STEP_ADD_REP_WAYDROID="0"

    if [ "$APT_UPDATE" == "1" ]; then
        echo -e "\033[94mПакеты обновлены.\033[0m"
        STEP_UPDATE_APT="1"
    else
        echo -e "\033[94mПакеты не обновлены.\033[0m"
        echo -e "\033[91mНевозможно проверить доступность пакетов. Проверьте /etc/apt/sources.list и Ваше интернет-соединение.\033[0m"
        exit 1
    fi

    if [ "$STEP_UPDATE_APT" == "1" ]; then
        if $(apt install curl ca-certificates -y >/dev/null 2>&1); then
            echo -e "\033[94mУстановлены необходимые пакеты для продолжения: \033[97mcurl ca-certificates.\033[0m"
            STEP_INSTALL_REQUIRED="1"
        else
            echo -e "\033[91mПакеты не установлены. Проверьте /etc/apt/sources.list и Ваше интернет-соединение.\033[0m"
            exit 1
        fi
    fi

    if [ "$STEP_INSTALL_REQUIRED" == "1" ]; then
        echo -e "\033[94mДобавляется официальный репозиторий Waydroid...\033[0m"
        if $(curl -s https://repo.waydro.id); then
            echo -e "\033[94mРепозиторий Waydroid добавлен.\033[0m"
            STEP_ADD_REP_WAYDROID="1"
        else
            echo -e "\033[91mРепозиторий Waydroid не добавлен. Проверьте Ваше интернет-соединение.\033[0m"
            exit 1
        fi
    fi

    if [ "$STEP_ADD_REP_WAYDROID" == "1" ]; then
        echo -e "\033[94mУстановка Waydroid...\033[0m"
        if $(apt install waydroid -y); then
            echo -e "\033[94mWaydroid установлен.\033[0m"
        else
            echo -e "\033[91mWaydroid не установлен. Проверьте /etc/apt/sources.list и Ваше интернет-соединение.\033[0m"
            exit 1
        fi
    fi
}

if [ "$(id -u)" != "0" ]; then
    echo -e "\033[1;37mСкрипт должен иметь права суперпользователя (root).\033[0m" 1>&2
    echo -e "\033[1;34mЗапустите скрипт через sudo или зайдите под суперпользователя и повторите попытку.\033[0m" 1>&2
    exit 1
fi

if $(grep -q -E --color "vmx|svm" /proc/cpuinfo); then
    echo -e "\033[92mVT-x поддерживается и активен в текущей конфигурации машины.\033[0m"
else
    echo -e "\033[91mVT-x не поддерживается системой! Проверьте, включена ли виртуализация в BIOS.\033[0m"
    exit 1
fi

echo -e "\033[97mWaydroid - контейнизированная среда для запуска приложений на ОС Android внутри Linux. Используется контейнера LXC.\033[0m"
echo -e "\033[97mWaydroid взаимодействует с сессиями рабочего стола. Все приложения, запущенные внутри Waydroid, будут запущены внутри сессии рабочего стола.\033[0m"
echo -e "\033[97mПеред установкой, удостовертесь в поддержке Вашей операционной системы на сайте Waydroid: https://docs.waydro.id/usage/install-on-desktops\033[0m"
read -p "Вы уверены, что хотите установить Waydroid? (y/n): " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\033[97mУстановка Waydroid...\033[0m"
    echo -e "\033[97mПодождите, пожалуйста...\033[0m"
    install_waydroid
else
    exit 1
fi