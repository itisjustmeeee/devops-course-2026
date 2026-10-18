#!/usr/bin/env bash
# Доставка статического ресурса на devops-vm
# Использование scripts/deploy.sh [--dry-run]

set -euo pipefail

REMOTE="devops"
REMOTE_DIR="/var/www/devops-site"
SITE_URL="https://devops.local"
CA_CERT="${HOME}/devops.crt"

# Определение корня репозитория независимо от текущего каталога.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
LOCAL_DIR="${REPO_ROOT}/site/"

# 1. Разбор аргументов
DRY_RUN=0

if [[ $# -gt 1 ]]; then
    echo "Использование: scripts/deploy.sh [--dry-run]" >&2
    exit 2
fi


if [[ $# -eq 1 ]]; then
    if [[ "$1" == "--dry-run" ]]; then
        DRY_RUN=1
    else
        echo "Ошибка: неизвестный аргумент '$1'" >&2
        echo "Использование: scripts/deploy.sh [--dry-run]" >&2
        exit 2
    fi
fi

# 2. Проверка наличия главной страницы
if [[ ! -f "${LOCAL_DIR}index.html" ]]; then
    echo "Ошибка: ${LOCAL_DIR}index.html не найден" >&2
    exit 1
fi

# 3. Репозиторий должен быть полностью чистым
# Проверка изменений в рабочем дереве, индексе и создание новых файлов
if ! STATUS="$(git -C "$REPO_ROOT" status --porcelain --untracked-files=all)"; then
    echo "Ошибка: не удалось проверить состояние Git" >&2
    exit 1
fi

if [[ -n "$STATUS" ]]; then
    echo "Ошибка: в репозитории есть незафиксированные изменения:" >&2
    printf '%s\n' "$STATUS" >&2
    echo "Зафиксируйте изменения или уберите их перед доставкой." >&2
    exit 1
fi

COMMIT="$(git -C "$REPO_ROOT" rev-parse --short HEAD)"

# 4. Подготовка аргументов rsync.
RSYNC_OPTS=(-avz --delete --chmod=D755,F644)

if [[ "$DRY_RUN" -eq 1 ]]; then
    RSYNC_OPTS+=(--dry-run)
fi

# BatchMode запрещает интерактивные запросы пароля и парольной фразы.
# Подключение к серверу выполняется только через rsync
RSYNC_RSH='ssh -o BatchMode=yes -o ConnectTimeout=5'

# 5. Синхронизация сайта.
if ! rsync "${RSYNC_OPTS[@]}" \
    -e "$RSYNC_RSH" \
    "$LOCAL_DIR" \
    "${REMOTE}:${REMOTE_DIR}/"; then
    echo "Ошибка: доставка через rsync завершилась неудачно" >&2
    exit 1
fi

# 6. Для пробного запуска дальнейшие действия не выполняются
if [[ "$DRY_RUN" -eq 1 ]]; then
    printf 'Пробный запуск завершен. Коммит: %s. Изменения не применены' "$COMMIT"
    exit 0
fi

# 7. Проверка доступности сайта с обязательной проверкой TLS-сертификата
if ! curl \
    --fail \
    --silent \
    --show-error \
    --cacert "$CA_CERT" \
    --connect-timeout 5 \
    --max-time 15 \
    "$SITE_URL" >/dev/null; then
    echo "Ошибка: сайт $SITE_URL недоступен или проверка TLS не пройдена" >&2
    exit 1
fi

# 8. Успешное завершение.
printf 'Доставка успешна. Коммит: %s\n' "$COMMIT"
exit 0
