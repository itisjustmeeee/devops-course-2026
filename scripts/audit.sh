#!/usr/bin/env bash

CHECK_FAILED=0

check() {
    local description="$1"
    shift

    if "$@"; then
        printf '[OK] %s\n' "$description"
    else
        printf '[FAIL] %s\n' "$description" >&2
        CHECK_FAILED=1
    fi
}

echo "[4] Веб-сервер"

# а) Служба nginx активна
check "Служба nginx активна" \
    systemctl is-active nginx

# б) Конфигурация nginx синтаксически корректна
check "Конфигурация nginx корректна" \
    sudo nginx -t

# в) Сертификат действует еще минимум 30 дней
check "Сертификат действует минимум 30 дней" \
    openssl x509 \
    -in /etc/ssl/certs/devops.crt \
    -checkend "${CERT_CHECK_SECONDS:-2592000}" \
    -noout

# г) Нет объектов с записью для others;
#    права закрытого ключа равны 600
check "Права файлов сайта и ключа корректны" \
    bash -c '
        set -eu

        writable=$(find /var/www/devops-site -perm -o+w -print)

        if [ -n "$writable" ]; then
            echo "Ошибка: объекты доступны для записи всем:" >&2
            printf "%s\n" "$writable" >&2
            exit 1
        fi

        key_mode=$(sudo stat -c "%a" /etc/ssl/private/devops.key)

        if [ "$key_mode" != "600" ]; then
            echo "Ошибка: права ключа должны быть 600, сейчас: $key_mode" >&2
            exit 1
        fi
    '

exit "$CHECK_FAILED"
