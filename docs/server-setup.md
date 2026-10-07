# Конфигурация виртуальной машины

## 1. Параметры машины

- Объем памяти (оперативная): 2048 МБ
- Количество ядер: 2
- Объем диска: 25.00 ГБ

## 2. Сетевые интерфейсы

- Тип адаптера: intel PRO/1000 MT Desktop (82540EM)
- Полученный адрес: Адаптер 1 - 080027B5FCF7, Адаптер 2 - 080027322BA4
- Назначение: сетевой адаптер

## 3. Правило проброса портов

- Порт хостовой системы: 2222
- Порт гостевой системы: 2222

## 4. Учетные записи

- Имя: запись 1 - vboxuser, запись 2 - devops
- Принадлежность к группам: запись 2 - devops
- способ аутентификации: запись 1 - password, publickey; запись 2 - password, publickey

## 5. Служба SSH

- Порт: 2222
- Измененные директивы и их значения:
devops:<br>
```text
Port 2222

PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no
MaxAuthTries 3
LoginGraceTime 30

AllowUsers devops

X11Forwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
```

vboxuser:<br>
```text
Port 2222

PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no
MaxAuthTries 3
LoginGraceTime 30

AllowUsers devops vboxuser

X11Forwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
```
- Расположение файла конфигурации:<br>
devops: -rw-r--r-- 1 root root 230 Oct  7 21:32 99-hardening.conf<br>
vboxuser: -rw-r--r-- 1 root root 230 Oct  7 21:32 99-hardening.conf

## 6. Правила межсетевого экрана

- Политики по умолчанию:<br>
devops:<br>
```text
Status: active
Logging: on (medium)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
80/tcp                     ALLOW IN    Anywhere                   # HTTP
443/tcp                    ALLOW IN    Anywhere                   # HTTPS
2222/tcp                   LIMIT IN    Anywhere                   # SSH rate-limited
80/tcp (v6)                ALLOW IN    Anywhere (v6)              # HTTP
443/tcp (v6)               ALLOW IN    Anywhere (v6)              # HTTPS
2222/tcp (v6)              LIMIT IN    Anywhere (v6)              # SSH rate-limited
```

vboxuser:<br>
```text
Status: active
Logging: on (medium)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
80/tcp                     ALLOW IN    Anywhere                   # HTTP
443/tcp                    ALLOW IN    Anywhere                   # HTTPS
2222/tcp                   LIMIT IN    Anywhere                   # SSH rate-limited
80/tcp (v6)                ALLOW IN    Anywhere (v6)              # HTTP
443/tcp (v6)               ALLOW IN    Anywhere (v6)              # HTTPS
2222/tcp (v6)              LIMIT IN    Anywhere (v6)              # SSH rate-limited
```
- Перечень правил:<br>
devops:<br>
```text
Status: active

     To                         Action      From
     --                         ------      ----
[ 1] 80/tcp                     ALLOW IN    Anywhere                   # HTTP
[ 2] 443/tcp                    ALLOW IN    Anywhere                   # HTTPS
[ 3] 2222/tcp                   LIMIT IN    Anywhere                   # SSH rate-limited
[ 4] 80/tcp (v6)                ALLOW IN    Anywhere (v6)              # HTTP
[ 5] 443/tcp (v6)               ALLOW IN    Anywhere (v6)              # HTTPS
[ 6] 2222/tcp (v6)              LIMIT IN    Anywhere (v6)              # SSH rate-limited
```

vboxuser:<br>
```text
Status: active

     To                         Action      From
     --                         ------      ----
[ 1] 80/tcp                     ALLOW IN    Anywhere                   # HTTP
[ 2] 443/tcp                    ALLOW IN    Anywhere                   # HTTPS
[ 3] 2222/tcp                   LIMIT IN    Anywhere                   # SSH rate-limited
[ 4] 80/tcp (v6)                ALLOW IN    Anywhere (v6)              # HTTP
[ 5] 443/tcp (v6)               ALLOW IN    Anywhere (v6)              # HTTPS
[ 6] 2222/tcp (v6)              LIMIT IN    Anywhere (v6)              # SSH rate-limited
```

## 7. Снимки состояния

- Наименование:
1. 01-clean-install
2. 02-keys-configured
3. 03-ssh-hardened
- Момент создания:
1. 28.09.2026 21:04
2. 07.10.2026 21:11
3. 07.10.2026 21:52