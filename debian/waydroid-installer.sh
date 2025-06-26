#!/bin/bash

install_waydroid() {
    echo -e "\033[94mПроверка доступности пакетов...\033[0m"
    if ! apt-get update >/dev/null 2>&1; then
        echo -e "\033[91mНевозможно обновить пакеты. Проверьте /etc/apt/sources.list и Ваше интернет-соединение.\033[0m"
        exit 1
    fi
    echo -e "\033[94mПакеты обновлены.\033[0m"

    echo -e "\033[94mУстановка необходимых пакетов...\033[0m"
    if ! apt install -y wget curl ca-certificates >/dev/null 2>&1; then
        echo -e "\033[91mНе удалось установить необходимые пакеты. Проверьте /etc/apt/sources.list и Ваше интернет-соединение.\033[0m"
        exit 1
    fi
    echo -e "\033[94mУстановлены необходимые пакеты: wget, curl, ca-certificates.\033[0m"

    echo -e "\033[94mДобавление официального репозитория Waydroid...\033[0m"
    
    # Скачиваем и выполняем скрипт добавления репозитория с обработкой ошибок
    temp_script=$(mktemp)
    if ! curl -s https://repo.waydro.id > "$temp_script"; then
        echo -e "\033[91mНе удалось загрузить скрипт добавления репозитория.\033[0m"
        rm -f "$temp_script"
        exit 1
    fi

    # Добавляем ручное определение дистрибутива, если автоматическое не сработало
    if ! bash "$temp_script"; then
        echo -e "\033[93mАвтоматическое определение дистрибутива не сработало. Пробуем ручной режим...\033[0m"
        echo "Доступные варианты: mantic, focal, jammy, kinetic, lunar, noble, oracular, plucky, questing, bookworm, bullseye, trixie, sid"
        read -p "Введите ваш дистрибутив: " distro
        
        if ! bash "$temp_script" -s "$distro"; then
            echo -e "\033[91mНе удалось добавить репозиторий для дистрибутива $distro\033[0m"
            rm -f "$temp_script"
            exit 1
        fi
    fi
    
    rm -f "$temp_script"
    echo -e "\033[94mРепозиторий Waydroid успешно добавлен.\033[0m"

    echo -e "\033[94mУстановка Waydroid...\033[0m"
    if ! apt install -y waydroid; then
        echo -e "\033[91mНе удалось установить Waydroid.\033[0m"
        exit 1
    fi
    echo -e "\033[94mWaydroid успешно установлен.\033[0m"
}

# Проверка прав суперпользователя
if [ "$(id -u)" != "0" ]; then
    echo -e "\033[1;37mСкрипт должен иметь права суперпользователя (root).\033[0m" 1>&2
    echo -e "\033[1;34mЗапустите скрипт через sudo или зайдите под суперпользователя и повторите попытку.\033[0m" 1>&2
    exit 1
fi

# Проверка поддержки виртуализации
if ! grep -q -E "vmx|svm" /proc/cpuinfo; then
    echo -e "\033[91mVT-x не поддерживается системой! Проверьте, включена ли виртуализация в BIOS.\033[0m"
    exit 1
fi
echo -e "\033[92mVT-x поддерживается и активен в текущей конфигурации машины.\033[0m"

# Информация о Waydroid
echo -e "\033[97mWaydroid - контейнизированная среда для запуска приложений на ОС Android внутри Linux. Используется контейнера LXC.\033[0m"
echo -e "\033[97mWaydroid взаимодействует с сессиями рабочего стола. Все приложения, запущенные внутри Waydroid, будут запущены внутри сессии рабочего стола.\033[0m"
echo -e "\033[97mПеред установкой, удостовертесь в поддержке Вашей операционной системы на сайте Waydroid: https://docs.waydro.id/usage/install-on-desktops\033[0m"

# Подтверждение установки
read -p "Вы уверены, что хотите установить Waydroid? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\033[97mУстановка Waydroid...\033[0m"
    echo -e "\033[97mПодождите, пожалуйста...\033[0m"
    install_waydroid
else
    exit 0
fi