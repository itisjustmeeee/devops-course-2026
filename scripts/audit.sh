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

# Проверяет, что порты 5000 и 5432 не открыты
# на адресах, отличных от 127.0.0.1.
ports_5000_5432_loopback_only() {
    local sockets
    local bad_addresses

    sockets="$(ss -tln)" || return 1

    bad_addresses="$(awk '
        $4 ~ /:(5000|5432)$/ && $4 !~ /^127\.0\.0\.1:/ {
            print $4
        }
    ' <<< "$sockets")"

    if [[ -n "$bad_addresses" ]]; then
        printf 'Порты опубликованы вне 127.0.0.1:\n%s\n' \
            "$bad_addresses" >&2
        return 1
    fi

    return 0
}

echo "[5] Контейнеризация"

# а) Служба Docker активна
check "Служба Docker активна" \
    systemctl is-active docker

# б) Контейнер PostgreSQL находится в состоянии healthy
check "Контейнер СУБД app-db-1 имеет статус healthy" \
    test "$(docker inspect -f '{{.State.Health.Status}}' app-db-1 2>/dev/null)" = healthy

# в) Порты 5000 и 5432 не открыты на внешних интерфейсах
check "Порты 5000 и 5432 ограничены адресом 127.0.0.1" \
    ports_5000_5432_loopback_only

# г) Права файла .env равны 600
check "Права файла ~/app/.env равны 600" \
    test "$(stat -c '%a' "$HOME/app/.env" 2>/dev/null)" = 600

exit "$CHECK_FAILED"
