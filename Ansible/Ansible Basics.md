# Подробное руководство по Ansible: от основ до конфигурации

---

## Часть 1: Введение в Ansible

### Что такое Ansible и зачем он нужен?

Ansible — это инструмент для **автоматизации IT-инфраструктуры**. Он позволяет системным администраторам, DevOps-инженерам и всем IT-специалистам автоматизировать рутинные задачи, не прибегая к написанию сложных скриптов.

Типичные задачи, с которыми сталкивается любой администратор:

- **Provisioning** — развёртывание новых серверов и виртуальных машин
- **Конфигурирование систем** — настройка ОС, сервисов, пользователей
- **Патчинг** — обновление десятков и сотен серверов одновременно
- **Миграции** — перенос данных и приложений между окружениями
- **Деплой приложений** — автоматический выпуск новых версий
- **Аудит безопасности** — проверка и применение политик безопасности

Раньше всё это делалось с помощью самописных shell-скриптов. Проблема скриптов в том, что они:
- Требуют хорошего знания программирования
- Сложны в обслуживании (особенно чужой код)
- Хрупки — ломаются при изменении окружения
- Не читаемы для людей, которые их не писали

Ansible решает все эти проблемы с помощью **плейбуков** (playbooks) — простых текстовых файлов на языке YAML, которые читаются почти как обычный английский текст.

---

### Сравнение: Shell-скрипт vs Ansible Playbook

Рассмотрим конкретный пример — **добавление пользователя в систему Linux**.

#### Традиционный Shell-скрипт (базовый вариант):

```bash
#!/bin/bash
# Script to add a user to a Linux system
if [ "$(id -u)" -eq 0 ]; then
    username="johndoe"
    read -s -p "Enter password: " password
    useradd "$username" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "User has been added"
    else
        echo "Failed to add the user!"
    fi
else
    echo "This script must be run as root."
fi
```

Что здесь происходит:
1. Проверяем, запущен ли скрипт от root (id -u = 0)
2. Задаём имя пользователя
3. Запрашиваем пароль
4. Запускаем `useradd`
5. Проверяем код возврата (`$?`) и выводим результат
6. Подавляем вывод через `/dev/null 2>&1`

Это **14 строк** только для одной простой операции. И это ещё базовый вариант — без обработки ошибок и проверки существующего пользователя.

#### Эквивалентный Ansible Playbook:

```yaml
- hosts: localhost
  tasks:
    - name: Add the user johndoe
      user:
        name: johndoe
```

Всего **5 строк**. Читается как инструкция на человеческом языке:
- «На хосте localhost»
- «Выполни задачу: добавь пользователя johndoe»

При этом Ansible **автоматически**:
- Проверяет, нужно ли вообще что-то делать (если пользователь уже существует — пропустит)
- Обрабатывает ошибки
- Выводит понятный отчёт о результатах

---

### Улучшенный скрипт с проверкой существования пользователя

Допустим, нам нужно сначала проверить — а вдруг пользователь уже есть? Shell-скрипт усложняется:

```bash
#!/bin/bash
# Script to add a user to a Linux system with validation
if [ "$(id -u)" -eq 0 ]; then
    username="johndoe"
    read -s -p "Enter password: " password
    grep -q "^$username:" /etc/passwd
    if [ $? -ne 0 ]; then
        useradd "$username"
        echo "$password" | passwd --stdin "$username"
        echo "User has been added"
    else
        echo "User '$username' already exists!"
    fi
else
    echo "This script must be run as root."
fi
```

Мы добавили `grep -q` для проверки файла `/etc/passwd` — ещё несколько строк логики. А Ansible-плейбук **не изменился вообще** — он уже по умолчанию идемпотентен (не делает лишних действий, если цель уже достигнута).

---

### Гибкость: меняем цель выполнения одной строкой

Предположим, нужно выполнить ту же задачу не на локальной машине, а на **всех веб-серверах в DR-окружении** (Disaster Recovery). В shell-скрипте пришлось бы писать цикл, настраивать SSH, обрабатывать ошибки подключения. В Ansible — меняем одно слово:

```yaml
- hosts: all_my_web_servers_in_DR
  tasks:
    - name: Add the user johndoe
      user:
        name: johndoe
```

Вместо `localhost` написали `all_my_web_servers_in_DR` — и Ansible сам подключится ко всем серверам из этой группы параллельно.

---

### Реальные сценарии применения

**Сценарий 1: Перезапуск серверов в определённом порядке**

Представьте: нужно перезапустить веб-сервера, потом базы данных, а затем поднять их в обратном порядке. С Ansible такой плейбук пишется один раз и запускается в любой момент — например, после каждого обновления ядра.

**Сценарий 2: Провижининг сложной инфраструктуры**

Ansible умеет:
- Создавать виртуальные машины на **Amazon AWS** и **VMware** одновременно
- Устанавливать и настраивать приложения на них
- Обновлять конфигурационные файлы
- Устанавливать пакеты
- Настраивать правила firewall
- Интегрироваться с CMDB-системами
- Запускать workflow в **ServiceNow** через встроенные модули

Всё это — в одном плейбуке, который читается и понимается без специальной подготовки.

---

## Часть 2: Понимание YAML

### Что такое YAML и почему он важен для Ansible?

**YAML** (YAML Ain't Markup Language) — это формат текстовых файлов для хранения структурированных данных. Ansible-плейбуки пишутся именно на YAML.

По сравнению с XML и JSON YAML значительно читабельнее:

| Формат | Пример |
|--------|--------|
| XML | `<name>Server1</name>` |
| JSON | `{"name": "Server1"}` |
| YAML | `name: Server1` |

YAML — минималистичен: никаких лишних скобок, тегов, кавычек (в большинстве случаев).

---

### Базовые конструкции YAML

#### 1. Пары ключ-значение (Key-Value Pairs)

Самый простой элемент YAML — это пара «ключ: значение» через двоеточие и **пробел**:

```yaml
Fruit: Apple
Vegetable: Carrot
Liquid: Water
Meat: Chicken
```

⚠️ **Важно:** пробел после двоеточия обязателен. `Fruit:Apple` — это ошибка.

---

#### 2. Списки (Arrays / Lists)

Список создаётся с помощью дефиса (`-`) перед каждым элементом:

```yaml
Fruits:
  - Orange
  - Apple
  - Banana

Vegetables:
  - Carrot
  - Cauliflower
  - Tomato
```

Каждый элемент — отдельная строка с отступом и дефисом. Список **всегда упорядочен** — порядок элементов имеет значение.

---

#### 3. Словари (Dictionaries / Maps)

Словарь — это набор связанных пар ключ-значение под одним ключом:

```yaml
Banana:
  Calories: 105
  Fat: 0.4 g
  Carbs: 27 g

Grapes:
  Calories: 62
  Fat: 0.3 g
  Carbs: 16 g
```

Словарь — это **неупорядоченная** структура. Порядок ключей `Calories`, `Fat`, `Carbs` внутри `Banana` не важен — данные остаются теми же.

---

#### 4. Список словарей (List of Dictionaries)

Это самая частая структура в Ansible — список элементов, каждый из которых имеет несколько свойств:

```yaml
Fruits:
  - Banana:
      Calories: 105
      Fat: 0.4 g
      Carbs: 27 g
  - Grape:
      Calories: 62
      Fat: 0.3 g
      Carbs: 16 g
```

Здесь `Fruits` — список. Каждый элемент списка — словарь с питательной информацией.

---

#### 5. Вложенные словари

Словари могут содержать другие словари. Пример — описание автомобиля:

```yaml
Color: Blue
Model:
  Name: Corvette
  Year: 1995
Transmission: Manual
Price: "$20,000"
```

Здесь `Model` — это вложенный словарь с ключами `Name` и `Year`.

---

#### 6. Комментарии

Любая строка, начинающаяся с `#`, является комментарием и игнорируется:

```yaml
# List of Fruits
Fruits:
  - Orange
  - Apple
  - Banana
```

---

### Ключевые правила YAML

1. **Отступы через пробелы, не табуляцию.** Tab-символы в YAML запрещены — только пробелы.
2. **Одинаковый уровень = одинаковый отступ.** Элементы одного уровня должны иметь одинаковое количество пробелов.
3. **Регистр важен.** `Name` и `name` — это разные ключи.
4. **Пробел после двоеточия обязателен** для пар ключ-значение.

---

## Часть 3: Конфигурационные файлы Ansible

### Главный файл конфигурации

При установке Ansible создаётся файл конфигурации по умолчанию: `/etc/ansible/ansible.cfg`

Он разбит на секции:

```ini
/etc/ansible/ansible.cfg
[defaults]
[inventory]
[privilege_escalation]
[paramiko_connect]
[ssh]
```

#### Секция `[defaults]` — основные настройки:

```ini
[defaults]
inventory          = /etc/ansible/hosts   # путь к инвентарю
log_path           = /var/log/ansible.log # файл логов
library            = /usr/share/my_modules/  # путь к модулям
roles_path         = /etc/ansible/roles   # путь к ролям
action_plugins     = /usr/share/ansible/plugins/action
gathering          = implicit             # сбор фактов
timeout            = 10                   # SSH-таймаут в секундах
forks              = 5                    # параллельных подключений

[inventory]
enable_plugins = host_list, virtualbox, yaml, constructed
```

Важное правило: **переопределяй только то, что нужно изменить** — остальное берётся из значений по умолчанию.

---

### Несколько плейбуков — разные конфигурации

Типичная ситуация: у вас три набора плейбуков в разных директориях:

```
/opt/web-playbooks/
/opt/db-playbooks/
/opt/network-playbooks/
```

Для каждого нужны разные настройки:
- **Веб-плейбуки:** отключить сбор фактов (gathering = false)
- **БД-плейбуки:** включить сбор фактов, отключить цветной вывод
- **Сетевые плейбуки:** увеличить SSH-таймаут с 10 до 20 секунд

**Решение 1:** скопировать `ansible.cfg` в каждую директорию и изменить нужные параметры. Ansible автоматически подхватит конфиг из директории, где лежит плейбук.

**Решение 2:** хранить конфиги в отдельном месте и указывать путь через переменную окружения:

```bash
$ ANSIBLE_CONFIG=/opt/ansible-web.cfg ansible-playbook playbook.yml
```

---

### Порядок приоритетов конфигурационных файлов

Ansible ищет конфиг в следующем порядке (от высшего приоритета к низшему):

1. `ANSIBLE_CONFIG` — переменная окружения с явным путём к файлу
2. `./ansible.cfg` — файл в текущей директории (рядом с плейбуком)
3. `~/.ansible.cfg` — скрытый файл в домашней директории пользователя
4. `/etc/ansible/ansible.cfg` — системный файл по умолчанию

Как только Ansible находит файл — он использует его и дальше не ищет.

---

### Переопределение параметров через переменные окружения

Если нужно изменить всего один параметр — необязательно редактировать файл конфигурации. Ansible поддерживает переопределение через переменные окружения.

**Правило формирования имени переменной:** берём имя параметра, переводим в верхний регистр, добавляем префикс `ANSIBLE_`.

Пример: параметр `gathering` → переменная `ANSIBLE_GATHERING`

```bash
# Переопределить для одного запуска
$ ANSIBLE_GATHERING=explicit ansible-playbook playbook.yml

# Переопределить для всей сессии терминала
$ export ANSIBLE_GATHERING=explicit
$ ansible-playbook playbook.yml

# Проверить, что переменная применилась
$ ansible-config dump | grep GATHERING
DEFAULT_GATHERING: explicit
```

---

### Команды для работы с конфигурацией

Утилита `ansible-config` незаменима при отладке:

```bash
# Список всех доступных параметров конфигурации с описанием и значениями по умолчанию
$ ansible-config list

# Показать содержимое текущего активного конфигурационного файла
$ ansible-config view

# Дамп всей конфигурации: значения + источник (файл/переменная окружения/default)
$ ansible-config dump
```

`ansible-config dump` особенно полезен: он показывает не только значение каждого параметра, но и **откуда оно взялось** — из какого файла или переменной.

---

## Итоговые выводы

**Ansible:**
- Заменяет громоздкие shell-скрипты лаконичными плейбуками на YAML
- Идемпотентен — запускай сколько угодно раз, лишних изменений не будет
- Масштабируется от одного хоста до тысяч серверов изменением одной строки
- Интегрируется с AWS, VMware, ServiceNow и сотнями других систем через встроенные модули

**YAML:**
- Основа всех Ansible-плейбуков
- Поддерживает пары ключ-значение, списки, словари и их комбинации
- Критичен к отступам: всегда используй пробелы, никогда — табуляцию
- Списки упорядочены, словари — нет

**Конфигурация Ansible:**
- Главный файл: `/etc/ansible/ansible.cfg`
- Можно иметь разные конфиги для разных наборов плейбуков
- Приоритет: `ANSIBLE_CONFIG` > `./ansible.cfg` > `~/.ansible.cfg` > `/etc/ansible/ansible.cfg`
- Отдельные параметры переопределяются переменными окружения вида `ANSIBLE_ПАРАМЕТР`
- Для диагностики используй `ansible-config dump`

---

# Подробное руководство по Ansible Inventory: инвентарь, форматы, группировка

---

## Часть 1: Ansible Inventory — что это и зачем нужно

### Концепция инвентаря

Прежде чем Ansible сможет что-то сделать с серверами, он должен **знать, где они находятся**. Именно для этого существует инвентарный файл (inventory file) — список всех целевых машин, которыми управляет Ansible.

Ключевое архитектурное решение Ansible — **агентless-подход**. Это означает, что на целевых серверах не нужно ничего устанавливать. Ansible использует протоколы, которые уже встроены в современную инфраструктуру:

- **Linux/Unix-серверы** → подключение через **SSH**
- **Windows-серверы** → подключение через **PowerShell Remoting (WinRM)**

Это принципиальное отличие от других инструментов автоматизации (например, Puppet или Chef), которые требуют установки агента на каждый управляемый сервер. В Ansible достаточно иметь SSH-доступ — и всё готово к работе.

По умолчанию Ansible ищет инвентарный файл по пути `/etc/ansible/hosts`. Можно указать любой другой файл через параметр `-i` при запуске плейбука:

```bash
$ ansible-playbook -i /path/to/my/inventory playbook.yml
```

---

### Базовая структура инвентарного файла (INI-формат)

Самый простой инвентарный файл — это просто список серверов, по одному на строке. Серверы можно объединять в **группы**, указывая имя группы в квадратных скобках:

```ini
[inventory]
server1.company.com
server2.company.com

[mail]
server3.company.com
server4.company.com

[db]
server5.company.com
server6.company.com

[web]
server7.company.com
server8.company.com
```

Здесь определены четыре группы: `inventory`, `mail`, `db`, `web`. Когда вы запускаете плейбук с `hosts: web` — Ansible применит его только к `server7.company.com` и `server8.company.com`.

---

### Параметры инвентаря: псевдонимы и настройки подключения

В реальной жизни серверы часто имеют длинные DNS-имена или IP-адреса, неудобные для работы. Ansible позволяет задавать **псевдонимы (aliases)** и детально настраивать параметры подключения для каждого хоста.

#### Основные параметры инвентаря:

| Параметр | Описание | Пример |
|---|---|---|
| `ansible_host` | FQDN или IP-адрес сервера | `ansible_host=192.168.1.10` |
| `ansible_connection` | Протокол подключения | `ssh`, `winrm`, `localhost` |
| `ansible_port` | Порт подключения | `ansible_port=22` (SSH по умолчанию) |
| `ansible_user` | Имя пользователя для подключения | `ansible_user=root` |
| `ansible_ssh_pass` | Пароль SSH | `ansible_ssh_pass=P@ssword` |

#### Пример инвентаря с псевдонимами и параметрами:

```ini
# Sample Inventory File

web       ansible_host=server1.company.com  ansible_connection=ssh    ansible_user=root
db        ansible_host=server2.company.com  ansible_connection=winrm  ansible_user=admin
mail      ansible_host=server3.company.com  ansible_connection=ssh    ansible_ssh_pass=P@#
web2      ansible_host=server4.company.com  ansible_connection=winrm
localhost ansible_connection=localhost
```

Разберём каждую строку:

- **`web`** — псевдоним для `server1.company.com`. Linux-сервер, подключение по SSH от пользователя `root`.
- **`db`** — псевдоним для `server2.company.com`. Windows-сервер, подключение через WinRM от пользователя `admin`.
- **`mail`** — Linux-сервер с явно указанным SSH-паролем (для учебных целей — в продакшене так делать не стоит).
- **`web2`** — Windows-сервер без явно указанного пользователя (будет использоваться значение по умолчанию).
- **`localhost`** — специальный случай: `ansible_connection=localhost` означает, что Ansible будет работать прямо на той машине, где запущен, без удалённого подключения.

#### ⚠️ Важное замечание о паролях

Хранение паролей в открытом виде в инвентарном файле — это **плохая практика безопасности**, недопустимая в продакшене. Правильный подход — настройка **аутентификации по SSH-ключам**. Файл инвентаря с паролями допустим только в учебных целях или в изолированных тестовых окружениях.

---

## Часть 2: Форматы инвентаря — INI vs YAML

### Когда что использовать?

Ansible поддерживает два основных формата инвентарного файла. Выбор между ними зависит от масштаба и сложности инфраструктуры.

---

### INI-формат: для небольших окружений

INI-формат — простой, читаемый, минималистичный. Идеально подходит для небольшого стартапа или личных проектов, где серверов немного и их структура проста.

```ini
[webservers]
web1.example.com
web2.example.com

[dbservers]
db1.example.com
db2.example.com
```

**Плюсы INI:**
- Очень легко читается
- Минимум синтаксиса
- Быстро пишется вручную

**Минусы INI:**
- Сложно описывать иерархические структуры
- При росте инфраструктуры становится громоздким
- Ограниченные возможности для сложных вложенных группировок

---

### YAML-формат: для крупных и сложных окружений

Для больших организаций с сотнями серверов в разных регионах, выполняющих разные роли, YAML-формат даёт значительно больше гибкости и структурности.

```yaml
all:
  children:
    webservers:
      hosts:
        web1.example.com:
        web2.example.com:
    dbservers:
      hosts:
        db1.example.com:
        db2.example.com:
```

Структура YAML-инвентаря:
- **`all`** — корневой ключ, обязательный в YAML-инвентаре. Содержит все группы.
- **`children`** — обозначает дочерние группы внутри родительской.
- **`hosts`** — перечень серверов внутри группы.

**Плюсы YAML:**
- Поддерживает глубокую иерархию групп
- Легко читается при правильном форматировании
- Хорошо интегрируется с системами контроля версий
- Позволяет описывать сложные parent-child отношения

**Минусы YAML:**
- Строгий синтаксис (отступы, структура)
- Избыточен для простых случаев

---

### Сравнение форматов: одно и то же разными способами

Вот как одна и та же инфраструктура выглядит в обоих форматах:

**INI:**
```ini
[webservers]
web1.example.com
web2.example.com

[dbservers]
db1.example.com
db2.example.com
```

**YAML:**
```yaml
all:
  children:
    webservers:
      hosts:
        web1.example.com:
        web2.example.com:
    dbservers:
      hosts:
        db1.example.com:
        db2.example.com:
```

Результат одинаковый — две группы серверов. Но YAML масштабируется значительно лучше при добавлении новых уровней вложенности, переменных хостов и групп.

---

## Часть 3: Группировка и иерархия (Parent-Child Relationships)

### Зачем нужна группировка?

Представьте: вы администрируете инфраструктуру крупной компании. У вас есть:
- Веб-серверы в США — `server1_us.com`, `server2_us.com`
- Веб-серверы в Европе — `server1_eu.com`, `server2_eu.com`
- Серверы баз данных
- Серверы приложений

Каждый раз указывать все серверы по отдельности при каждой операции — это долго, ошибочно и неудобно. Группировка решает эту проблему: вы один раз описываете группу, а потом обращаетесь к ней по имени.

### Проблема без иерархии

Если создать просто две плоские группы — `webservers_us` и `webservers_eu` — возникает дублирование. Общие настройки для всех веб-серверов придётся прописывать в каждой группе отдельно. При изменении общего параметра нужно менять его в нескольких местах — это источник ошибок.

### Решение: Parent-Child отношения

Ansible позволяет создавать **иерархию групп**: родительская группа `webservers` содержит дочерние группы `webservers_us` и `webservers_eu`. Общие настройки определяются на уровне родителя, специфические — на уровне дочерних групп.

---

### Parent-Child в INI-формате

Для обозначения родительской группы используется суффикс `:children` после имени группы:

```ini
[webservers:children]
webservers_us
webservers_eu

[webservers_us]
server1_us.com ansible_host=192.168.8.101
server2_us.com ansible_host=192.168.8.102

[webservers_eu]
server1_eu.com ansible_host=10.12.0.101
server2_eu.com ansible_host=10.12.0.102
```

Разбор структуры:

- **`[webservers:children]`** — объявляет `webservers` как родительскую группу. Список под ней — это имена дочерних групп.
- **`[webservers_us]`** и **`[webservers_eu]`** — дочерние группы с конкретными серверами.

Теперь если в плейбуке написать `hosts: webservers` — Ansible применит его ко **всем четырём серверам** из обеих дочерних групп. А написав `hosts: webservers_us` — только к двум американским.

---

### Parent-Child в YAML-формате

В YAML иерархия выражается через вложенность ключей `children` и `hosts`:

```yaml
all:
  children:
    webservers:
      children:
        webservers_us:
          hosts:
            server1_us.com:
              ansible_host: 192.168.8.101
            server2_us.com:
              ansible_host: 192.168.8.102
        webservers_eu:
          hosts:
            server1_eu.com:
              ansible_host: 10.12.0.101
            server2_eu.com:
              ansible_host: 10.12.0.102
```

Структура читается сверху вниз:

1. `all` — корень, все группы
2. `children` — под `all` определяем дочерние группы
3. `webservers` — родительская группа для всех веб-серверов
4. `children` — под `webservers` определяем её дочерние группы
5. `webservers_us` и `webservers_eu` — дочерние группы с серверами через ключ `hosts`
6. Под каждым сервером — параметры, например `ansible_host`

---

### Практический пример: полный инвентарь с иерархией

Представим более реалистичный сценарий — компания с несколькими типами серверов в двух регионах:

**INI-формат:**
```ini
# Родительские группы
[webservers:children]
webservers_us
webservers_eu

[dbservers:children]
dbservers_us
dbservers_eu

# Веб-серверы США
[webservers_us]
web1_us ansible_host=192.168.1.10 ansible_user=deploy
web2_us ansible_host=192.168.1.11 ansible_user=deploy

# Веб-серверы Европа
[webservers_eu]
web1_eu ansible_host=10.0.1.10 ansible_user=deploy
web2_eu ansible_host=10.0.1.11 ansible_user=deploy

# БД США
[dbservers_us]
db1_us ansible_host=192.168.2.10 ansible_user=dbadmin

# БД Европа
[dbservers_eu]
db1_eu ansible_host=10.0.2.10 ansible_user=dbadmin
```

Теперь в плейбуках можно использовать:
- `hosts: webservers` — применить ко всем 4 веб-серверам
- `hosts: webservers_eu` — только к европейским веб-серверам
- `hosts: dbservers` — ко всем серверам баз данных
- `hosts: all` — ко всем серверам во всём инвентаре

**Эквивалент в YAML-формате:**
```yaml
all:
  children:
    webservers:
      children:
        webservers_us:
          hosts:
            web1_us:
              ansible_host: 192.168.1.10
              ansible_user: deploy
            web2_us:
              ansible_host: 192.168.1.11
              ansible_user: deploy
        webservers_eu:
          hosts:
            web1_eu:
              ansible_host: 10.0.1.10
              ansible_user: deploy
            web2_eu:
              ansible_host: 10.0.1.11
              ansible_user: deploy
    dbservers:
      children:
        dbservers_us:
          hosts:
            db1_us:
              ansible_host: 192.168.2.10
              ansible_user: dbadmin
        dbservers_eu:
          hosts:
            db1_eu:
              ansible_host: 10.0.2.10
              ansible_user: dbadmin
```

---

## Итоговые выводы

**Ansible Inventory (инвентарь):**
- Хранит информацию обо всех управляемых хостах
- По умолчанию находится в `/etc/ansible/hosts`
- Ansible agentless — не требует ничего устанавливать на серверах, только SSH/WinRM
- Поддерживает псевдонимы хостов и множество параметров подключения (`ansible_host`, `ansible_connection`, `ansible_user`, `ansible_port`, `ansible_ssh_pass`)
- Пароли в инвентаре в открытом виде допустимы только в учебных окружениях; в продакшене — SSH-ключи

**Форматы инвентаря:**
- **INI** — простой, читаемый, подходит для небольших инфраструктур
- **YAML** — гибкий, иерархический, для крупных и сложных окружений
- Оба формата поддерживают группировку и parent-child отношения

**Группировка и иерархия:**
- Группы позволяют применять действия к множеству серверов одной командой
- Parent-child отношения устраняют дублирование конфигурации: общее — в родителе, специфическое — в потомках
- В INI: `[groupname:children]`, затем список дочерних групп
- В YAML: вложенные ключи `children` и `hosts`
- Группировать серверы можно по роли (web/db/app), по географии (us/eu/asia) или по любому другому критерию

---

# Подробное руководство по переменным и фактам в Ansible

---

## Часть 1: Типы переменных в Ansible

### Что такое переменные и зачем они нужны?

Переменные в Ansible выполняют ту же роль, что и в любом языке программирования — они хранят значения, которые могут меняться в зависимости от контекста. Представьте: у вас есть плейбук, который устанавливает пакеты на 200 серверов. На каждом сервере своё имя хоста, свой пользователь, свой пароль. Без переменных пришлось бы писать 200 плейбуков. С переменными — один.

Ansible поддерживает пять базовых типов переменных.

---

### 1. Строковые переменные (String)

Строка — последовательность символов. Это самый распространённый тип.

```yaml
username: "admin"
```

Строки можно задавать с кавычками или без — в большинстве случаев YAML понимает их одинаково. Кавычки обязательны, если строка содержит специальные символы (двоеточие, решётку и т.д.):

```yaml
# Без кавычек — работает
city: Amsterdam

# С кавычками — работает
city: "Amsterdam"

# Обязательно с кавычками, иначе YAML сломается
message: "Hello: world"
```

Использование в плейбуке:

```yaml
- name: Greet user
  hosts: localhost
  vars:
    username: "admin"
  tasks:
    - debug:
        msg: "Hello, {{ username }}!"
```

Вывод: `Hello, admin!`

---

### 2. Числовые переменные (Number)

Числа используются в математических операциях, условиях, настройке лимитов и таймаутов.

```yaml
max_connections: 100
timeout_seconds: 30
memory_gb: 16
```

Пример применения — настройка количества воркеров для nginx на основе числовой переменной:

```yaml
- name: Configure nginx
  hosts: webservers
  vars:
    worker_processes: 4
    worker_connections: 1024
  tasks:
    - template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
```

В шаблоне (`nginx.conf.j2`) можно использовать `{{ worker_processes }}` и `{{ worker_connections }}`.

---

### 3. Булевы переменные (Boolean)

Булевы переменные хранят значения истина/ложь и активно используются в условиях `when`.

```yaml
debug_mode: true
enable_firewall: false
```

Ansible принимает множество форм булевых значений:

| Истина | Ложь |
|---|---|
| `true`, `True`, `TRUE` | `false`, `False`, `FALSE` |
| `yes`, `Yes`, `YES` | `no`, `No`, `NO` |
| `on`, `On`, `ON` | `off`, `Off`, `OFF` |
| `1` | `0` |

Пример использования в условии:

```yaml
- name: Enable debug logging
  hosts: all
  vars:
    debug_mode: true
  tasks:
    - name: Set verbose logging
      lineinfile:
        path: /etc/app/config.conf
        line: "log_level=DEBUG"
      when: debug_mode == true
```

Задача выполнится только если `debug_mode` равен `true`.

---

### 4. Списковые переменные (List)

Список — упорядоченная коллекция значений любого типа. Элементы доступны по индексу (начиная с 0).

```yaml
packages:
  - nginx
  - postgresql
  - git
```

Полный пример плейбука со списком:

```yaml
- name: Install Packages Playbook
  hosts: webservers
  vars:
    packages:
      - nginx
      - postgresql
      - git
  tasks:
    - name: Показать все пакеты
      debug:
        var: packages

    - name: Показать первый пакет
      debug:
        msg: "Первый пакет: {{ packages[0] }}"

    - name: Установить все пакеты
      become: true
      debug:
        msg: "Устанавливаю пакет {{ item }}"
      loop: "{{ packages }}"
```

Что здесь происходит:
- `packages[0]` — обращение к первому элементу (`nginx`)
- `packages[1]` — второй элемент (`postgresql`)
- `loop: "{{ packages }}"` — итерация по всем элементам списка: задача выполнится три раза, каждый раз с другим значением `{{ item }}`

Списки могут содержать любые типы данных, включая словари:

```yaml
users:
  - name: alice
    role: admin
  - name: bob
    role: developer
```

---

### 5. Словарные переменные (Dictionary)

Словарь — коллекция пар «ключ: значение». Используется для хранения связанных данных об одном объекте.

```yaml
user:
  name: "admin"
  password: "secret"
  email: "admin@example.com"
  role: "superuser"
```

Доступ к значениям — через точку или через квадратные скобки:

```yaml
- name: Print user info
  hosts: localhost
  vars:
    user:
      name: "admin"
      email: "admin@example.com"
  tasks:
    - debug:
        msg: "User: {{ user.name }}, Email: {{ user.email }}"

    # Альтернативная нотация — через скобки
    - debug:
        msg: "User: {{ user['name'] }}"
```

Словари можно вкладывать друг в друга:

```yaml
server:
  web:
    port: 80
    workers: 4
  database:
    host: db.example.com
    port: 5432
```

Обращение: `{{ server.web.port }}` вернёт `80`, `{{ server.database.host }}` вернёт `db.example.com`.

---

## Часть 2: Определение переменных — где и как

### Способ 1: Переменные в инвентарном файле

```ini
Web1 ansible_host=server1.company.com ansible_connection=ssh ansible_ssh_pass=P@ssW
db   ansible_host=server2.company.com ansible_connection=winrm ansible_ssh_pass=P@s
Web2 ansible_host=server3.company.com ansible_connection=ssh ansible_ssh_pass=P@ssW
```

Здесь `ansible_host`, `ansible_connection`, `ansible_ssh_pass` — это переменные, заданные прямо в строке инвентаря.

Можно задавать и пользовательские переменные:

```ini
Web http_port=8081 snmp_port=161-162 inter_ip_range=192.0.2.0
```

Или через секцию `[group:vars]` для группы:

```ini
[web_servers]
web1
web2
web3

[web_servers:vars]
dns_server=10.5.5.3
http_port=80
```

---

### Способ 2: Переменные в плейбуке через `vars`

```yaml
- name: Add DNS server to resolv.conf
  hosts: localhost
  vars:
    dns_server: 10.1.250.10
  tasks:
    - lineinfile:
        path: /etc/resolv.conf
        line: "nameserver {{ dns_server }}"
```

Директива `vars` определяется на уровне плея. Переменная `dns_server` используется в задаче через **Jinja2-шаблонизацию**: `{{ dns_server }}`.

Сравните версию без переменной и с переменной:

```yaml
# Жёстко закодировано — плохо
line: "nameserver 10.1.250.10"

# Через переменную — гибко и правильно
line: "nameserver {{ dns_server }}"
```

Теперь чтобы изменить DNS-сервер — достаточно поменять одно значение в `vars`, а не искать по всему плейбуку.

---

### Способ 3: Отдельный файл переменных

Для сложных конфигураций переменные выносятся в отдельный YAML-файл:

```yaml
# web.yml — файл переменных
http_port: 8081
snmp_port: 161-162
inter_ip_range: 192.0.2.0
```

Ansible автоматически подхватывает переменные из файлов в директориях `host_vars/` и `group_vars/`. Например:
- `group_vars/web_servers.yml` — переменные для группы `web_servers`
- `host_vars/web1.yml` — переменные конкретно для хоста `web1`

---

### Jinja2-шаблонизация: синтаксис и правила

Все переменные в Ansible используются через Jinja2-синтаксис: `{{ переменная }}`.

**Важное правило о кавычках:** если переменная стоит в начале значения — значение нужно взять в кавычки:

```yaml
# Переменная в начале — нужны кавычки
port: "{{ http_port }}/tcp"

# Переменная в середине строки — кавычки необязательны
line: nameserver {{ dns_server }} # работает
line: "nameserver {{ dns_server }}" # тоже работает, более явно
```

Пример плейбука для настройки firewall с переменными:

```yaml
- name: Set Firewall Configurations
  hosts: web
  tasks:
    - firewalld:
        service: https
        permanent: true
        state: enabled

    - firewalld:
        port: "{{ http_port }}/tcp"
        permanent: true
        state: disabled

    - firewalld:
        port: "{{ snmp_port }}/udp"
        permanent: true
        state: disabled

    - firewalld:
        source: "{{ inter_ip_range }}/24"
        zone: internal
        state: enabled
```

Значения `http_port`, `snmp_port`, `inter_ip_range` берутся из инвентаря или файла переменных — плейбук не содержит ни одного жёстко закодированного значения, кроме самой логики.

---

## Часть 3: Приоритет переменных (Variable Precedence)

### Проблема конфликта переменных

Когда одна и та же переменная определена в нескольких местах — Ansible должен решить, какое значение использовать. Для этого существует **иерархия приоритетов**.

Рассмотрим пример с тремя хостами и групповой переменной:

```ini
/etc/ansible/hosts
web1 ansible_host=172.20.1.100
web2 ansible_host=172.20.1.101
web3 ansible_host=172.20.1.102

[web_servers]
web1
web2
web3

[web_servers:vars]
dns_server=10.5.5.3
```

Все три хоста получат `dns_server=10.5.5.3` из групповой переменной.

Теперь переопределим переменную для одного хоста:

```ini
web1 ansible_host=172.20.1.100
web2 ansible_host=172.20.1.101 dns_server=10.5.5.4
web3 ansible_host=172.20.1.102

[web_servers:vars]
dns_server=10.5.5.3
```

Теперь:
- `web1` → `dns_server=10.5.5.3` (из группы)
- `web2` → `dns_server=10.5.5.4` (хостовая переменная перекрывает групповую)
- `web3` → `dns_server=10.5.5.3` (из группы)

### Уровни приоритета от низшего к высшему:

1. **Групповые переменные** (`[group:vars]` в инвентаре) — самый низкий приоритет
2. **Хостовые переменные** в инвентаре (заданные в строке хоста)
3. **Переменные в плейбуке** (секция `vars:`)
4. **`--extra-vars`** в командной строке — **самый высокий приоритет**

```yaml
# Переменная в плейбуке перекроет групповую и хостовую
- name: Configure DNS Server
  hosts: all
  vars:
    dns_server: 10.5.5.5
  tasks:
    - nsupdate:
        server: '{{ dns_server }}'
```

```bash
# --extra-vars перекроет всё, включая vars в плейбуке
$ ansible-playbook playbook.yml --extra-vars "dns_server=10.5.5.6"
```

При запуске с `--extra-vars` значение `10.5.5.6` будет использоваться везде, независимо от того, что написано в инвентаре или плейбуке.

---

## Часть 4: Область видимости переменных (Variable Scoping)

### 1. Host Scope — переменные уровня хоста

Переменные, определённые для конкретного хоста в инвентаре, доступны **только при выполнении задач на этом хосте**.

```ini
web1 ansible_host=172.20.1.100
web2 ansible_host=172.20.1.101 dns_server=10.5.5.4
web3 ansible_host=172.20.1.102
```

Плейбук пытается вывести `dns_server` для всех хостов:

```yaml
- name: Print DNS server
  hosts: all
  tasks:
    - debug:
        msg: '{{ dns_server }}'
```

Результат:
```
ok: [web1] => { "dns_server": "VARIABLE IS NOT DEFINED!" }
ok: [web2] => { "dns_server": "10.5.5.4" }
ok: [web3] => { "dns_server": "VARIABLE IS NOT DEFINED!" }
```

`web1` и `web3` не знают про эту переменную — она была определена только для `web2`.

---

### 2. Play Scope — переменные уровня плея

Переменные, объявленные в `vars:` внутри плея, **существуют только в пределах этого плея**. В следующем плее того же плейбука они недоступны.

```yaml
---
- name: Play1
  hosts: web1
  vars:
    ntp_server: 10.1.1.1
  tasks:
    - debug:
        var: ntp_server    # Выведет: 10.1.1.1

- name: Play2
  hosts: web1
  tasks:
    - debug:
        var: ntp_server    # Выведет: VARIABLE IS NOT DEFINED!
```

Play2 не видит `ntp_server`, определённую в Play1. Переменная «умерла» вместе с первым плеем.

---

### 3. Global Scope — глобальные переменные

Глобальные переменные доступны во **всех плеях и всех задачах** плейбука. Стандартный способ их задать — через `--extra-vars` в командной строке:

```bash
$ ansible-playbook playbook.yml --extra-vars "ntp_server=10.1.1.1"
```

```yaml
---
- name: Play1
  hosts: web1
  tasks:
    - debug:
        var: ntp_server    # Выведет: 10.1.1.1

- name: Play2
  hosts: web1
  tasks:
    - debug:
        var: ntp_server    # Тоже выведет: 10.1.1.1
```

### Сводная таблица областей видимости:

| Тип | Где определяется | Где доступна |
|---|---|---|
| Host Scope | Инвентарь (строка хоста) | Только при выполнении на этом хосте |
| Play Scope | `vars:` внутри плея | Только в пределах этого плея |
| Global | `--extra-vars` в командной строке | Во всех плеях и задачах |

---

## Часть 5: Регистрация вывода задач (register)

### Зачем нужна регистрация?

Иногда результат выполнения одной задачи нужен в следующей. Например: запустили команду — сохранили её вывод — используем в следующей задаче для принятия решения.

Для этого используется директива `register`:

```yaml
---
- name: Check /etc/hosts file
  hosts: all
  tasks:
    - shell: cat /etc/hosts
      register: result

    - debug:
        var: result
```

Переменная `result` теперь содержит всю информацию о выполнении команды — её структура выглядит примерно так:

```json
{
    "changed": true,
    "cmd": "cat /etc/hosts",
    "rc": 0,
    "stdout": "127.0.0.1\tlocalhost\n...",
    "stdout_lines": ["127.0.0.1\tlocalhost", "..."],
    "stderr": "",
    "stderr_lines": [],
    "start": "2019-09-24 07:37:26.158046",
    "end": "2019-09-24 07:37:26.404478",
    "delta": "0:00:00.282432"
}
```

Основные поля:
- **`rc`** — return code (код возврата). `0` = успех, любое другое = ошибка
- **`stdout`** — стандартный вывод команды (одной строкой)
- **`stdout_lines`** — тот же вывод, разбитый на список строк
- **`stderr`** — вывод ошибок
- **`changed`** — изменилось ли что-то на хосте

### Доступ к конкретным полям:

```yaml
# Вывести только stdout
- debug:
    var: result.stdout

# Вывести только код возврата
- debug:
    var: result.rc

# Вывести stdout построчно
- debug:
    var: result.stdout_lines
```

### Практический пример: условное выполнение на основе результата команды

```yaml
---
- name: Check if service is running
  hosts: all
  tasks:
    - shell: systemctl is-active nginx
      register: nginx_status
      ignore_errors: true

    - name: Start nginx if it's not running
      service:
        name: nginx
        state: started
      when: nginx_status.rc != 0
```

Логика: запустили команду, проверили код возврата — если nginx не активен (rc != 0), запустили его.

### Просмотр вывода через флаг `-v`

Если не хочется добавлять `debug` в плейбук, можно запустить его с флагом `-v` для подробного вывода:

```bash
$ ansible-playbook -i inventory playbook.yml -v
```

Вывод покажет всю информацию о каждой задаче, включая `stdout`, `rc`, временные метки и т.д.

⚠️ **Важно:** зарегистрированные переменные имеют **хостовую область видимости** — они живут только во время выполнения плейбука на конкретном хосте.

---

## Часть 6: Магические переменные (Magic Variables)

### Что такое магические переменные?

Магические переменные — это специальные переменные, которые Ansible создаёт автоматически. Они дают доступ к информации о хостах, группах, и контексте выполнения — даже к данным **других хостов**.

Обычно каждый хост «видит» только свои переменные. Магические переменные снимают это ограничение.

---

### `hostvars` — доступ к переменным других хостов

Инвентарь:
```ini
web1 ansible_host=172.20.1.100
web2 ansible_host=172.20.1.101 dns_server=10.5.5.4
web3 ansible_host=172.20.1.102
```

`dns_server` определён только для `web2`. Но с помощью `hostvars` любой хост может получить это значение:

```yaml
---
- name: Print DNS server from web2
  hosts: all
  tasks:
    - debug:
        msg: '{{ hostvars["web2"].dns_server }}'
```

Вывод на всех трёх хостах:
```
ok: [web1] => { "msg": "10.5.5.4" }
ok: [web2] => { "msg": "10.5.5.4" }
ok: [web3] => { "msg": "10.5.5.4" }
```

Все три хоста получили значение, хотя оно было определено только для `web2`.

Через `hostvars` доступны и Ansible Facts других хостов (если они были собраны):

```yaml
- debug:
    msg: '{{ hostvars["web2"].ansible_host }}'

- debug:
    msg: '{{ hostvars["web2"].ansible_facts.architecture }}'

- debug:
    msg: '{{ hostvars["web2"].ansible_facts.devices }}'

- debug:
    msg: '{{ hostvars["web2"].ansible_facts.mounts }}'

- debug:
    msg: '{{ hostvars["web2"].ansible_facts.processor }}'
```

Можно использовать как точечную нотацию (`hostvars["web2"].ansible_host`), так и скобочную (`hostvars["web2"]["ansible_host"]`).

---

### `groups` — список хостов в группе

Инвентарь:
```ini
web1 ansible_host=172.20.1.100
web2 ansible_host=172.20.1.101
web3 ansible_host=172.20.1.102

[web_servers]
web1
web2
web3

[americas]
web1
web2

[asia]
web3
```

```yaml
- debug:
    msg: '{{ groups["americas"] }}'
```

Вывод: `["web1", "web2"]` — список имён хостов в группе `americas`.

Практическое применение — например, сгенерировать конфигурационный файл, перечислив все серверы из группы:

```yaml
- name: Generate load balancer config
  hosts: loadbalancer
  tasks:
    - template:
        src: haproxy.cfg.j2
        dest: /etc/haproxy/haproxy.cfg
```

В шаблоне `haproxy.cfg.j2` можно использовать:
```
{% for host in groups['webservers'] %}
    server {{ host }} {{ hostvars[host]['ansible_host'] }}:80
{% endfor %}
```

---

### `group_names` — группы, в которых состоит текущий хост

```yaml
- debug:
    msg: "{{ group_names }}"
```

Если запустить на `web1`, вывод будет: `["web_servers", "americas"]` — потому что `web1` состоит в обеих этих группах.

Используется для условного выполнения:

```yaml
- name: Apply webserver config
  template:
    src: webserver.conf.j2
    dest: /etc/app/config.conf
  when: "'webservers' in group_names"
```

---

### `inventory_hostname` — имя хоста так, как оно записано в инвентаре

```yaml
- name: Show inventory hostname
  hosts: web1
  tasks:
    - debug:
        msg: "{{ inventory_hostname }}"
```

Выведет: `web1` — именно так, как хост записан в инвентарном файле. Это может отличаться от FQDN или реального имени машины.

---

### Другие полезные магические переменные:

- **`ansible_play_hosts`** — список всех хостов, которые ещё активны в текущем плее (не упавших и не пропущенных)
- **`ansible_play_batch`** — список хостов в текущей «партии» выполнения (актуально при использовании `serial`)
- **`ansible_playbook_python`** — путь к интерпретатору Python, который использует Ansible

---

## Часть 7: Ansible Facts — автоматически собираемая информация о хостах

### Что такое Facts?

**Ansible Facts** — это информация, которую Ansible автоматически собирает о каждом целевом хосте в начале выполнения плейбука. Сбор происходит через встроенный модуль `setup`, который запускается **до выполнения любых задач**.

Собираемая информация:
- Архитектура (x86_64, ARM и т.д.)
- Версия и дистрибутив ОС
- Процессор, количество ядер
- Объём памяти (свободная/занятая)
- Сетевые интерфейсы, IP-адреса, MAC-адреса, FQDN
- Дисковые устройства и точки монтирования
- Дата и время

Все эти данные хранятся в переменной `ansible_facts` и доступны в любой задаче плейбука.

---

### Как это выглядит в реальности?

Возьмём простейший плейбук:

```yaml
---
- name: Print hello message
  hosts: all
  tasks:
    - debug:
        msg: Hello from Ansible!
```

При запуске Ansible автоматически добавляет шаг сбора фактов **до** наших задач:

```
TASK [Gathering Facts] ***********************************
ok: [web2]
ok: [web1]

TASK [debug] *********************************************
ok: [web1] => { "msg": "Hello from Ansible!" }
ok: [web2] => { "msg": "Hello from Ansible!" }
```

Мы не просили собирать факты — Ansible сделал это сам.

---

### Просмотр всех фактов хоста:

```yaml
---
- name: Print Ansible Facts
  hosts: all
  tasks:
    - debug:
        var: ansible_facts
```

Вывод будет огромным. Вот его сокращённая структура:

```json
{
  "all_ipv4_addresses": ["172.20.1.100"],
  "architecture": "x86_64",
  "date_time": {
    "date": "2019-09-07"
  },
  "distribution": "Ubuntu",
  "distribution_major_version": "16",
  "distribution_release": "xenial",
  "distribution_version": "16.04",
  "dns": {
    "nameservers": ["127.0.0.11"]
  },
  "fqdn": "web1",
  "hostname": "web1",
  "interfaces": ["lo", "eth0"],
  "machine": "x86_64",
  "memfree_mb": 72,
  "memory_mb": {
    "real": { "free": 72, "total": 985, "used": 913 }
  }
}
```

### Использование фактов в задачах:

```yaml
- name: Configure swap based on available memory
  hosts: all
  tasks:
    - name: Create swap only if RAM < 2GB
      command: mkswap /swapfile
      when: ansible_facts['memory_mb']['real']['total'] < 2048

    - name: Print OS info
      debug:
        msg: "Running {{ ansible_facts['distribution'] }} {{ ansible_facts['distribution_version'] }}"
```

---

### Отключение сбора фактов

Сбор фактов занимает время, особенно на большом количестве хостов. Если факты не нужны — отключите:

```yaml
---
- name: Quick task without facts
  hosts: all
  gather_facts: no
  tasks:
    - debug:
        msg: "Выполняю без сбора фактов — быстрее!"
```

Поведение сбора фактов управляется также через `ansible.cfg`:

```ini
# /etc/ansible/ansible.cfg
# smart    — собирать, но не повторно если уже собрано
# implicit — собирать по умолчанию (отключить через gather_facts: False)
# explicit — не собирать по умолчанию (включить через gather_facts: True)
gathering = implicit
```

Настройка `gather_facts` в плейбуке имеет приоритет над значением в `ansible.cfg`.

---

### Целевой сбор фактов

Факты собираются **только для хостов, указанных в плейбуке**. Если в инвентаре есть `web1` и `web2`, но плейбук нацелен только на `web1`:

```yaml
- name: Gather facts for web1 only
  hosts: web1
  tasks:
    - debug:
        var: ansible_facts
```

Факты для `web2` собраны не будут. Это важно помнить при использовании `hostvars` — если факты не были собраны для хоста, обращение к `hostvars["web2"].ansible_facts` вернёт пустой объект или ошибку.

---

## Итоговые выводы

**Типы переменных:**
- **String** — текст, самый частый тип
- **Number** — числа для математики и настроек
- **Boolean** — истина/ложь для условий
- **List** — упорядоченный набор, доступ по индексу, итерация через `loop`
- **Dictionary** — объект с именованными полями, доступ через точку или скобки

**Определение переменных:**
- В инвентаре (хостовые и групповые переменные)
- В плейбуке через `vars:`
- В отдельных файлах (`host_vars/`, `group_vars/`)
- Через `--extra-vars` в командной строке

**Приоритет (от низшего к высшему):** группа → хост → плейбук → `--extra-vars`

**Области видимости:** Host Scope (только этот хост) → Play Scope (только этот плей) → Global (весь плейбук)

**`register`:** сохраняет вывод задачи в переменную. Поля: `rc`, `stdout`, `stdout_lines`, `stderr`, `changed`

**Магические переменные:**
- `hostvars["hostname"].variable` — переменные другого хоста
- `groups["groupname"]` — список хостов группы
- `group_names` — список групп текущего хоста
- `inventory_hostname` — имя хоста из инвентаря

**Ansible Facts:**
- Автоматически собираются модулем `setup` перед выполнением задач
- Хранятся в `ansible_facts`
- Содержат архитектуру, ОС, память, сеть, диски
- Отключаются через `gather_facts: no`
- Собираются только для хостов, указанных в плейбуке

---

# Подробное руководство по Ansible Playbooks: структура, проверка, условия и циклы

---

## Часть 1: Анатомия Ansible Playbook

### Что такое плейбук?

Ansible Playbook — это **основной инструмент автоматизации** в Ansible. Это YAML-файл, в котором описана последовательность действий (задач), выполняемых на одном или нескольких серверах. Плейбук — это не просто набор команд, это полноценный язык оркестрации инфраструктуры.

Масштаб задач, которые решают плейбуки, варьируется от совсем простых до монументально сложных.

**Простой плейбук** может:
- Выполнить команду на сервере
- Запустить скрипт
- Перезапустить несколько машин

**Сложный плейбук** может:
- Развернуть 50 виртуальных машин в публичном облаке
- Развернуть ещё 50 в приватном
- Настроить хранилище для всех VM
- Сконфигурировать сетевые настройки
- Настроить кластер
- Развернуть веб-серверы на 20 публичных VM
- Развернуть БД на 20 приватных VM
- Настроить балансировщик нагрузки
- Установить мониторинг
- Настроить резервное копирование
- Обновить CMDB-базу данными о новых VM

Всё это — в одном файле, который читается как инструкция на человеческом языке.

---

### Структура плейбука: Play, Task, Module

Плейбук состоит из **плеёв (plays)**. Каждый плей содержит **задачи (tasks)**. Каждая задача использует **модуль (module)** для выполнения конкретного действия.

Вот полная анатомия плейбука с одним плеем:

```yaml
- name: Play 1
  hosts: localhost
  tasks:
    - name: Execute command 'date'
      command: date

    - name: Execute script on server
      script: test_script.sh

    - name: Install httpd service
      yum:
        name: httpd
        state: present

    - name: Start web server
      service:
        name: httpd
        state: started
```

Разберём каждый уровень:

**Уровень плея:**
- `name:` — человекочитаемое название плея (необязательно, но настоятельно рекомендуется)
- `hosts:` — на каких хостах/группах выполнять этот плей
- `tasks:` — список задач плея

**Уровень задачи:**
- `name:` — описание задачи (отображается в выводе при запуске)
- Далее — название модуля (`command`, `script`, `yum`, `service`) и его параметры

**Уровень модуля:**
- `command: date` — запустить команду `date`
- `script: test_script.sh` — выполнить локальный скрипт на удалённом сервере
- `yum: name: httpd state: present` — установить пакет через yum
- `service: name: httpd state: started` — запустить сервис

---

### Ключевое правило: задачи выполняются последовательно

Порядок задач в плее **критически важен**. Ansible выполняет их строго сверху вниз. Если попытаться запустить сервис до его установки — задача упадёт с ошибкой.

Правильный порядок:
```yaml
tasks:
  - name: Install httpd service     # Сначала установить
    yum:
      name: httpd
      state: present

  - name: Start web server          # Потом запустить
    service:
      name: httpd
      state: started
```

Неправильный порядок:
```yaml
tasks:
  - name: Start web server          # ❌ httpd ещё не установлен!
    service:
      name: httpd
      state: started

  - name: Install httpd service
    yum:
      name: httpd
      state: present
```

---

### Несколько плеёв в одном плейбуке

Плейбук может содержать несколько плеёв. Каждый плей — отдельный словарь в списке:

```yaml
- name: Play 1
  hosts: localhost
  tasks:
    - name: Execute command 'date'
      command: date

    - name: Execute script on server
      script: test_script.sh

- name: Play 2
  hosts: localhost
  tasks:
    - name: Install web service
      yum:
        name: httpd
        state: present

    - name: Start web server
      service:
        name: httpd
        state: started
```

Обратите внимание: оба плея начинаются с дефиса (`-`) на нулевом уровне отступа. Это список плеёв — каждый дефис означает новый элемент списка (новый плей).

Зачем разбивать на несколько плеёв? Например:
- Play 1 настраивает базы данных
- Play 2 настраивает веб-серверы (которые зависят от баз данных из Play 1)
- Play 3 настраивает балансировщик (который зависит от веб-серверов из Play 2)

---

### Параметр `hosts` и параллельное выполнение

Параметр `hosts` принимает:
- Имя конкретного хоста: `hosts: web1`
- Имя группы из инвентаря: `hosts: webservers`
- Несколько групп: `hosts: webservers:dbservers`
- Все хосты: `hosts: all`
- `hosts: localhost` — выполнить на машине, где запущен Ansible

Когда указана **группа**, Ansible выполняет задачи **одновременно на всех хостах группы** (параллельно, в пределах значения `forks` из конфига, по умолчанию 5).

---

### Запуск плейбука

```bash
# Базовый запуск
$ ansible-playbook playbook.yml

# С указанием инвентарного файла
$ ansible-playbook -i inventory playbook.yml

# Помощь по всем доступным опциям
$ ansible-playbook --help
```

---

### Модули — строительные блоки Ansible

Каждая задача использует модуль. Модули — это готовые «инструменты» для выполнения конкретных операций. Базовые модули:

| Модуль | Назначение | Пример |
|---|---|---|
| `command` | Выполнить команду | `command: date` |
| `shell` | Выполнить команду через shell (поддерживает пайпы, редиректы) | `shell: cat /etc/hosts` |
| `script` | Запустить локальный скрипт на удалённом хосте | `script: deploy.sh` |
| `yum` | Управление пакетами (Red Hat) | `yum: name: nginx state: present` |
| `apt` | Управление пакетами (Debian/Ubuntu) | `apt: name: nginx state: present` |
| `service` | Управление сервисами | `service: name: nginx state: started` |
| `copy` | Копировать файл на хост | `copy: src: app.conf dest: /etc/app/` |
| `template` | Развернуть Jinja2-шаблон | `template: src: nginx.j2 dest: /etc/nginx/nginx.conf` |
| `lineinfile` | Добавить/изменить строку в файле | `lineinfile: path: /etc/hosts line: "..."` |
| `file` | Создать/удалить файл или директорию | `file: path: /opt/app state: directory` |
| `user` | Управление пользователями | `user: name: johndoe state: present` |
| `debug` | Вывести отладочную информацию | `debug: msg: "Hello!"` |

Полный список — более 3000 модулей. Посмотреть все:
```bash
$ ansible-doc -l
```

Документация по конкретному модулю:
```bash
$ ansible-doc yum
```

---

## Часть 2: Проверка плейбуков перед запуском

### Зачем проверять перед запуском?

Представьте: вы написали плейбук для обновления критического ПО на 500 серверах. Запустили без проверки в продакшн. На 200-м сервере обнаружилась ошибка — и сервис упал на половине инфраструктуры. Восстановление займёт часы.

Проверка плейбука — это **репетиция перед спектаклем**. Ansible предоставляет три инструмента для этого.

---

### Инструмент 1: Check Mode (`--check`) — «сухой прогон»

Check Mode симулирует выполнение плейбука **не внося никаких изменений** в систему. Ansible покажет, что изменилось бы, если бы плейбук выполнился по-настоящему.

```bash
$ ansible-playbook install_nginx.yml --check
```

Вывод:
```
PLAY [webservers] ****************************************************
TASK [Gathering Facts] ***********************************************
ok: [webserver1]

TASK [Ensure nginx is installed] *************************************
changed: [webserver1]

PLAY RECAP ***********************************************************
webserver1 : ok=2  changed=1  unreachable=0  failed=0  skipped=0
```

Слово `changed` в строке `TASK [Ensure nginx is installed]` означает: «если бы это выполнилось по-настоящему, nginx был бы установлен». Но реально ничего не произошло.

**Важное ограничение:** не все модули поддерживают check mode. Задачи с неподдерживаемыми модулями будут **пропущены** при проверке, а не симулированы. Всегда проверяйте документацию модуля.

---

### Инструмент 2: Diff Mode (`--diff`) — показать что именно изменится

Diff Mode показывает **конкретные изменения** в файлах — как утилита `diff` в Linux. Особенно полезен при работе с модулями `template`, `copy`, `lineinfile`.

Обычно используется совместно с `--check`:

```bash
$ ansible-playbook configure_nginx.yml --check --diff
```

Вывод:
```
TASK [Ensure the configuration line is present] **********************
---- before: /etc/nginx/nginx.conf (content)
+++ after: /etc/nginx/nginx.conf (content)
@@ -20,3 +20,4 @@
 # some existing configuration lines
 # more existing configuration lines
 #
+client_max_body_size 100M;
changed: [webserver1]
```

Формат вывода — стандартный unified diff:
- Строки без знака — контекст (не меняются)
- Строки с `+` — будут добавлены
- Строки с `-` — будут удалены

В примере видно: в `/etc/nginx/nginx.conf` будет добавлена строка `client_max_body_size 100M;`. Ни одна существующая строка не удаляется.

Можно запустить diff mode без check mode — тогда изменения применятся, но будут показаны подробности:

```bash
$ ansible-playbook configure_nginx.yml --diff
```

---

### Инструмент 3: Syntax Check (`--syntax-check`) — проверка синтаксиса YAML

Перед запуском любого плейбука разумно убедиться в корректности его синтаксиса. `--syntax-check` делает именно это — быстро, без подключения к хостам.

```bash
$ ansible-playbook configure_nginx.yml --syntax-check
```

Если синтаксис в порядке:
```
playbook: configure_nginx.yml
```

Если есть ошибка — допустим, забыли двоеточие после `lineinfile`:

```
ERROR! Syntax Error while loading YAML.
  did not find expected key

The error appears to be in '/path/to/configure_nginx.yml': line 5, column 9
The offending line appears to be:
lineinfile
  path: /etc/nginx/nginx.conf
         ^ here
```

Сообщение об ошибке указывает: файл, строку, столбец и даже стрелку `^` на конкретное проблемное место.

---

### Рекомендуемый порядок проверки перед запуском в продакшн:

```bash
# Шаг 1: Проверить синтаксис
$ ansible-playbook playbook.yml --syntax-check

# Шаг 2: Проверить с lint (подробнее ниже)
$ ansible-lint playbook.yml

# Шаг 3: Сухой прогон с детальными изменениями
$ ansible-playbook playbook.yml --check --diff

# Шаг 4: Запуск в продакшн
$ ansible-playbook playbook.yml
```

---

## Часть 3: Ansible Lint — анализ качества кода

### Что такое Ansible Lint?

`ansible-lint` — это инструмент статического анализа, который проверяет плейбуки, роли и коллекции на:
- Синтаксические ошибки
- Потенциальные баги
- Нарушения стилевых соглашений
- Подозрительные конструкции
- Устаревшие практики

Если `--syntax-check` проверяет только корректность YAML, то `ansible-lint` — это «опытный наставник», который указывает на проблемы качества кода.

---

### Пример: плейбук со стилевыми проблемами

```yaml
- name: Style Example Playbook
  hosts: localhost
  tasks:
    - name: Ensure nginx is installed and started
      apt:
        name: nginx
        state: latest
        update_cache: yes

    - name: Enable nginx service at boot
      service:
        name: nginx
        enabled: yes
        state: started

    - name: Copy nginx configuration file
      copy:
        src: /path/to/nginx.conf
        dest: /etc/nginx/nginx.conf
        notify:
          - Restart nginx service

handlers:
  - name: Restart nginx service
    service:
      name: nginx
      state: restarted
```

Запускаем lint:

```bash
$ ansible-lint style_example.yml
```

Получаем предупреждения:
```
[WARNING]: incorrect indentation: expected 2 but found 4 (syntax/indentation)
[WARNING]: command should not contain whitespace (blacklisted: ['apt']) (commands)
[WARNING]: Use shell only when shell functionality is required (commands)
[WARNING]: command should not contain whitespace (blacklisted: ['service']) (commands)
[WARNING]: 'name' should be present for all tasks (task-name-missing) (tasks)
```

Каждое предупреждение содержит:
- Описание проблемы
- Категорию (`syntax/indentation`, `commands`, `tasks`)
- Номер строки в файле

Если `ansible-lint` завершился **без какого-либо вывода** — ваш плейбук не содержит ошибок.

---

### Почему `state: latest` — плохая практика?

Lint часто предупреждает об использовании `state: latest` в модулях `yum`/`apt`. Причина: `latest` устанавливает **самую свежую версию** пакета на момент запуска. Это нарушает **идемпотентность** — каждый запуск плейбука потенциально меняет версию. Лучше использовать `state: present` (установить если не установлено) или явно указывать версию: `name: nginx=1.18.0`.

---

### Интеграция Lint в CI/CD

Ansible Lint идеально встраивается в пайплайны непрерывной интеграции:

```yaml
# .github/workflows/ansible.yml (пример для GitHub Actions)
- name: Run ansible-lint
  run: ansible-lint playbooks/
```

Это предотвращает попадание некачественного кода в основную ветку репозитория.

---

## Часть 4: Условия в Ansible (Conditionals)

### Зачем нужны условия?

Реальная инфраструктура неоднородна. У вас могут быть серверы с Ubuntu, CentOS, Windows. Одна и та же задача (установить nginx) выполняется по-разному в зависимости от ОС. Без условий пришлось бы писать отдельный плейбук для каждой ОС.

Условие `when` позволяет выполнять задачу **только если условие истинно**.

---

### Сценарий 1: Разные ОС — один плейбук

Без условий — два отдельных плейбука:

```yaml
# Для Debian/Ubuntu
- name: Install NGINX on Debian
  apt:
    name: nginx
    state: present

# Для Red Hat/CentOS
- name: Install NGINX on Red Hat
  yum:
    name: nginx
    state: present
```

С условиями — один унифицированный плейбук:

```yaml
---
- name: Install NGINX on multiple OS families
  hosts: all
  tasks:
    - name: Install NGINX on Debian
      apt:
        name: nginx
        state: present
      when: ansible_os_family == "Debian" and ansible_distribution_version == "16.04"

    - name: Install NGINX on Red Hat or SUSE
      yum:
        name: nginx
        state: present
      when: ansible_os_family == "RedHat" or ansible_os_family == "SUSE"
```

Здесь используются **Ansible Facts** — переменные, автоматически собираемые о каждом хосте:
- `ansible_os_family` — семейство ОС: `Debian`, `RedHat`, `Windows`, `SUSE`
- `ansible_distribution` — конкретный дистрибутив: `Ubuntu`, `CentOS`, `Debian`
- `ansible_distribution_version` — версия: `16.04`, `7`, `2019`
- `ansible_distribution_major_version` — только мажорная версия: `16`, `7`

Логические операторы в условиях:
- `and` — оба условия должны быть истинны
- `or` — хотя бы одно условие должно быть истинно
- `not` — отрицание

---

### Сценарий 2: Точное targeting через факты

```yaml
- name: Install Nginx only on Ubuntu 18.04
  apt:
    name: nginx=1.18.0
    state: present
  when:
    - ansible_facts['distribution'] == 'Ubuntu'
    - ansible_facts['distribution_major_version'] == '18'
```

Когда `when` содержит **список** (несколько условий под дефисами) — это эквивалентно `and`: все условия должны быть истинны.

Рекомендация: для широкой совместимости используйте `ansible_facts['os_family']`. Для точного контроля — `ansible_facts['distribution']` + `ansible_facts['distribution_major_version']`.

---

### Сценарий 3: Условия в циклах

Есть список пакетов, часть из которых обязательна, часть нет. Нужно установить только обязательные:

```yaml
---
- name: Install required packages
  hosts: all
  vars:
    packages:
      - name: nginx
        required: true
      - name: mysql
        required: true
      - name: apache
        required: false
  tasks:
    - name: Install package if required
      apt:
        name: "{{ item.name }}"
        state: present
      loop: "{{ packages }}"
      when: item.required
```

Как это работает:
1. Цикл `loop` итерируется по списку `packages`
2. На каждой итерации: `item` = текущий словарь (`{name: nginx, required: true}`)
3. `when: item.required` — проверяем поле `required` текущего элемента
4. Если `required: true` — задача выполняется, если `required: false` — пропускается

Результат: `nginx` и `mysql` будут установлены, `apache` — нет.

---

### Сценарий 4: Условие на основе результата предыдущей задачи

Мониторинг сервиса и отправка алерта если он упал:

```yaml
- name: Check service and alert if down
  hosts: localhost
  tasks:
    - name: Check status of httpd service
      command: service httpd status
      register: result

    - name: Send email alert if httpd is down
      mail:
        to: admin@company.com
        subject: "Service Alert"
        body: "Httpd Service is down"
      when: result.stdout.find('down') != -1
```

Логика:
1. Выполняем `service httpd status`, сохраняем вывод в `result`
2. В `result.stdout` — текстовый вывод команды
3. `.find('down')` — ищем слово 'down' в тексте. Возвращает индекс (-1 если не найдено)
4. `!= -1` — слово найдено → условие истинно → отправляем email

---

### Сценарий 5: Применение конфигурации только в продакшн

```yaml
- name: Deploy myapp
  hosts: all
  become: yes
  vars:
    app_env: production
  tasks:
    - name: Install packages (Debian)
      apt:
        name:
          - package1
          - package2
        state: present
      when: ansible_facts['os_family'] == 'Debian'

    - name: Create directories
      file:
        path: /opt/myapp
        state: directory
        owner: myapp
        mode: '0755'

    - name: Deploy config
      template:
        src: "{{ app_env }}_config.j2"
        dest: /etc/myapp/config.conf
      notify: Restart myapp

    - name: Start service (only in production)
      service:
        name: myapp
        state: started
      when: app_env == 'production'

  handlers:
    - name: Restart myapp
      service:
        name: myapp
        state: restarted
```

Здесь:
- Установка пакетов — только на Debian-хостах
- Создание директорий — на всех хостах (без условия)
- Деплой конфига — на всех, но шаблон зависит от `app_env`
- Запуск сервиса — только когда `app_env == 'production'`
- `notify: Restart myapp` — вызывает handler при изменении конфига

**Handlers** — это специальные задачи, которые выполняются только если их вызвали через `notify`, и только один раз в конце плея, независимо от того, сколько раз их вызвали.

---

### Лучшие практики работы с условиями:

- Предпочитайте список условий (`when: [cond1, cond2]`) вместо `and` — читабельнее
- Проверяйте фактические значения переменных через `debug: var: ansible_facts` перед написанием условий
- Для совместимости между дистрибутивами используйте `os_family`, для точного таргетинга — `distribution` + `distribution_major_version`
- Выносите `app_env` и подобные переменные в `group_vars`/`host_vars`, а не в плейбук

---

## Часть 5: Циклы в Ansible (Loops)

### Зачем нужны циклы?

Очень часто одну и ту же задачу нужно выполнить для нескольких объектов. Без цикла это выглядит так:

```yaml
tasks:
  - user: name: joe state: present
  - user: name: george state: present
  - user: name: ravi state: present
  - user: name: mani state: present
  - user: name: kiran state: present
  - user: name: jazlan state: present
  - user: name: emaan state: present
  - user: name: mazin state: present
  - user: name: izaan state: present
  - user: name: mike state: present
  - user: name: menaal state: present
  - user: name: shoeb state: present
  - user: name: rani state: present
```

13 почти идентичных задач. Если список пользователей изменится — придётся редактировать каждую строку. Это и есть та проблема, которую решают циклы.

---

### Базовый цикл с `loop`

```yaml
- name: Create users using a loop
  hosts: localhost
  tasks:
    - user:
        name: "{{ item }}"
        state: present
      loop:
        - joe
        - george
        - ravi
        - mani
        - kiran
        - jazlan
        - emaan
        - mazin
        - izaan
        - mike
        - menaal
        - shoeb
        - rani
```

Как это работает:
- `loop:` — список значений для итерации
- `{{ item }}` — специальная переменная, содержащая текущий элемент цикла
- Задача выполнится 13 раз, каждый раз с другим значением `item`

Это **функционально эквивалентно** 13 отдельным задачам, но в 10 раз короче и несравнимо легче в обслуживании.

---

### Цикл по списку словарей

Когда нужно передать несколько параметров для каждого элемента — используем список словарей:

```yaml
- name: Create users with UID
  hosts: localhost
  tasks:
    - user:
        name: "{{ item.name }}"
        state: present
        uid: "{{ item.uid }}"
      loop:
        - name: joe
          uid: 1010
        - name: george
          uid: 1011
        - name: ravi
          uid: 1012
        - name: mani
          uid: 1013
        - name: kiran
          uid: 1014
```

Теперь `item` — это словарь. Доступ к его полям через точку: `item.name`, `item.uid`.

Расширенный пример — создание пользователей с разными группами и shell:

```yaml
- name: Create users with full configuration
  hosts: all
  tasks:
    - user:
        name: "{{ item.name }}"
        uid: "{{ item.uid }}"
        groups: "{{ item.groups }}"
        shell: "{{ item.shell }}"
        state: present
      loop:
        - name: alice
          uid: 1001
          groups: sudo,docker
          shell: /bin/bash
        - name: bob
          uid: 1002
          groups: developers
          shell: /bin/zsh
        - name: carol
          uid: 1003
          groups: readonly
          shell: /bin/sh
```

---

### Совместное использование цикла и условия

Цикл и `when` отлично работают вместе:

```yaml
- name: Install only required packages
  apt:
    name: "{{ item.name }}"
    state: present
  loop:
    - name: nginx
      required: true
    - name: mysql
      required: true
    - name: apache
      required: false
  when: item.required
```

Условие `when` проверяется **на каждой итерации** цикла отдельно.

---

### `with_items` — устаревший, но встречающийся синтаксис

До появления `loop` в Ansible использовался `with_items`:

```yaml
- user:
    name: "{{ item }}"
    state: present
  with_items:
    - joe
    - george
    - ravi
```

`with_items` и `loop` дают одинаковый результат для простых случаев. Разница появляется при сложных сценариях: `loop` + фильтр `flatten` — явный и прозрачный, а `with_items` автоматически «разворачивает» вложенные списки, что может быть неожиданным.

**Рекомендация:** используйте `loop` в новых плейбуках. `with_items` оставляйте только в унаследованном коде.

---

### Специализированные директивы цикла (lookup plugins)

Для итерации по нестандартным источникам данных Ansible предоставляет lookup plugins — специальные «переводчики», которые позволяют получать данные из файлов, URL, баз данных и других источников.

**`with_file` — читать содержимое файлов:**
```yaml
- name: Show config files content
  debug:
    var: item
  with_file:
    - "/etc/hosts"
    - "/etc/resolv.conf"
    - "/etc/ntp.conf"
```

На каждой итерации `item` содержит **содержимое файла** (не имя!).

**`with_url` — получать данные с URL:**
```yaml
- name: Fetch server lists from API
  debug:
    var: item
  with_url:
    - "https://api.site1.com/servers"
    - "https://api.site2.com/servers"
    - "https://api.site3.com/servers"
```

**`with_mongodb` — запросы к MongoDB:**
```yaml
- name: Check MongoDB instances
  debug:
    msg: "DB={{ item.database }} PID={{ item.pid }}"
  with_mongodb:
    - database: dev
      connection_string: "mongodb://dev.mongo/"
    - database: prod
      connection_string: "mongodb://prod.mongo/"
```

**`with_sequence` — числовые последовательности:**
```yaml
- name: Create numbered directories
  file:
    path: "/opt/app/instance_{{ item }}"
    state: directory
  with_sequence: start=1 end=10
```

Создаст 10 директорий: `instance_1` ... `instance_10`.

---

### Полная таблица lookup plugins:

| Директива | Источник данных |
|---|---|
| `with_items` | Простой список (устаревшее) |
| `loop` | Список (рекомендуемое) |
| `with_dict` | Словарь (ключ-значение) |
| `with_file` | Содержимое файлов |
| `with_url` | Данные с HTTP URL |
| `with_mongodb` | MongoDB |
| `with_etcd` | etcd datastore |
| `with_env` | Переменные окружения |
| `with_filetree` | Дерево директорий |
| `with_ini` | INI-файлы |
| `with_inventory_hostnames` | Имена хостов из инвентаря |
| `with_k8s` | Kubernetes objects |
| `with_openshift` | OpenShift |
| `with_password` | Генерация паролей |
| `with_sequence` | Числовая последовательность |
| `with_subelements` | Вложенные списки |

---

## Итоговые выводы

**Анатомия плейбука:**
- Плейбук = список плеёв (plays)
- Плей = hosts + tasks
- Задача = название + модуль + параметры
- Задачи выполняются строго последовательно — порядок критичен
- При указании группы в `hosts` задачи выполняются параллельно на всех хостах группы

**Проверка перед запуском:**
- `--syntax-check` — проверяет корректность YAML синтаксиса
- `--check` — dry-run: показывает что изменилось бы без реальных изменений
- `--diff` — показывает точные изменения в файлах в формате diff
- `ansible-lint` — глубокий анализ качества кода, стиля и потенциальных ошибок
- Рекомендуемый порядок: syntax-check → lint → check+diff → запуск

**Условия (`when`):**
- Позволяют выполнять задачи только при соблюдении условия
- Используют факты (`ansible_os_family`, `ansible_distribution`), переменные, результаты задач
- Список под `when` работает как логическое `and`
- Позволяют писать единый плейбук для разнородной инфраструктуры

**Циклы (`loop`):**
- Заменяют дублированные задачи
- `item` — текущий элемент итерации
- Список строк → `{{ item }}`
- Список словарей → `{{ item.field }}`
- `when` внутри цикла проверяется на каждой итерации отдельно
- Предпочитайте `loop` устаревшему `with_items`
- Специализированные `with_*` плагины дают доступ к файлам, URL, БД и другим источникам

---

# Подробное руководство по модулям и плагинам Ansible

---

## Часть 1: Категории модулей Ansible

### Что такое модуль?

Модуль — это **атомарная единица работы** в Ansible. Каждая задача в плейбуке вызывает ровно один модуль. Модуль — это готовая программа (обычно на Python), которая выполняет конкретное действие: установить пакет, скопировать файл, запустить сервис, создать пользователя. Ansible поставляется с тысячами встроенных модулей, покрывающих практически любую задачу системного администрирования и DevOps.

Модули разбиты на категории по функциональности. Рассмотрим каждую подробно.

---

### Категория 1: System — системные модули

Системные модули выполняют операции на уровне операционной системы. Это самый широкий класс модулей.

**Что умеют:**
- Управление пользователями и группами
- Настройка iptables и firewall
- Управление логическими томами (LVM)
- Монтирование файловых систем
- Управление сервисами (запуск, остановка, перезапуск)
- Настройка hostname
- Управление cron-заданиями
- Настройка SELinux/AppArmor

**Примеры модулей:** `user`, `group`, `hostname`, `service`, `firewalld`, `iptables`, `lvol`, `mount`, `cron`, `timezone`

Пример: создание пользователя с заданными параметрами:

```yaml
- name: Manage system users
  hosts: all
  tasks:
    - name: Create deploy user
      user:
        name: deploy
        uid: 1500
        groups: sudo,docker
        shell: /bin/bash
        home: /home/deploy
        create_home: yes
        state: present

    - name: Remove old test user
      user:
        name: testuser
        state: absent
        remove: yes   # удалить домашнюю директорию

    - name: Set timezone to Amsterdam
      timezone:
        name: Europe/Amsterdam

    - name: Add cron job for cleanup
      cron:
        name: "Daily cleanup"
        minute: "0"
        hour: "2"
        job: "/opt/scripts/cleanup.sh"
        user: deploy
```

---

### Категория 2: Command — модули выполнения команд

Эта категория позволяет выполнять произвольные команды и скрипты на удалённых хостах.

**Модули категории:**
- `command` — выполнить команду (без shell-интерпретации)
- `shell` — выполнить команду через `/bin/sh` (поддерживает пайпы, переменные, редиректы)
- `script` — запустить локальный скрипт на удалённом хосте
- `expect` — интерактивные команды (автоматически отвечать на запросы)
- `raw` — выполнить команду без предварительной установки Python (для минимальных систем)

---

#### Модуль `command` — детальный разбор

`command` — самый базовый модуль. Он принимает команду в **свободной форме** (free form) — то есть не требует явного указания имён параметров для самой команды.

```yaml
- name: Play 1
  hosts: localhost
  tasks:
    - name: Execute command 'date'
      command: date

    - name: Display resolv.conf
      command: cat /etc/resolv.conf

    - name: Display resolv.conf using chdir
      command: cat resolv.conf
      args:
        chdir: /etc

    - name: Create folder only if not exists
      command: mkdir /folder
      args:
        creates: /folder
```

**Параметры `command`:**

`chdir` — изменить рабочую директорию перед выполнением команды:
```yaml
- command: cat resolv.conf
  args:
    chdir: /etc
# Эквивалентно: cd /etc && cat resolv.conf
```

`creates` — не выполнять команду, если указанный файл/директория уже существует:
```yaml
- command: mkdir /folder
  args:
    creates: /folder
# Если /folder уже есть — команда пропускается
```

`removes` — не выполнять команду, если указанный файл/директория НЕ существует:
```yaml
- command: rm -rf /tmp/old_data
  args:
    removes: /tmp/old_data
# Если /tmp/old_data нет — команда пропускается
```

**Важное отличие `command` от `shell`:**

`command` не запускает shell-интерпретатор. Это означает:
- `&&`, `||`, `|`, `>`, `>>`, `$VAR` — **не работают** в `command`
- Для пайпов и переменных окружения используйте `shell`

```yaml
# Это НЕ РАБОТАЕТ с command:
- command: echo "hello" | grep "hell"

# Это работает с shell:
- shell: echo "hello" | grep "hell"

# А это работает с command:
- command: grep "hello" /etc/hosts
```

**Концепция "free form" (свободная форма):**

В `command` и `shell` сама команда передаётся без имени параметра — просто как строка после двоеточия. Это называется free form. Сравните с модулем `copy`, где все параметры именованные:

```yaml
# Free form — команда как строка:
- command: cat /etc/hosts

# Именованные параметры — каждое значение с ключом:
- copy:
    src: /source_file
    dest: /destination
```

---

#### Модуль `script` — запуск локальных скриптов на удалённых хостах

`script` — это уникальный модуль, который:
1. Берёт скрипт с **управляющей машины** (Ansible controller)
2. Автоматически копирует его на **целевой хост**
3. Выполняет его там
4. Удаляет временный файл после выполнения

```yaml
- name: Deploy application
  hosts: webservers
  tasks:
    - name: Run deployment script
      script: /local/scripts/deploy.sh

    - name: Run script with arguments
      script: /local/scripts/setup.sh arg1 arg2

    - name: Run script only if marker file doesn't exist
      script: /local/scripts/init.sh
      args:
        creates: /opt/app/.initialized
```

Это избавляет от необходимости предварительно копировать скрипты на все серверы — Ansible делает это автоматически.

---

### Категория 3: Files — модули для работы с файлами

Файловые модули управляют содержимым, правами доступа и структурой файловой системы.

**Примеры модулей:** `copy`, `fetch`, `file`, `find`, `lineinfile`, `replace`, `template`, `archive`, `unarchive`, `acl`, `stat`

---

#### Модуль `copy` — копирование файлов

```yaml
- name: Copy configuration files
  hosts: all
  tasks:
    - name: Copy app config
      copy:
        src: /local/app.conf
        dest: /etc/app/app.conf
        owner: appuser
        group: appgroup
        mode: '0644'
        backup: yes    # создать backup если файл уже существует
```

---

#### Модуль `file` — создание файлов, директорий, симлинков

```yaml
- name: Manage files and directories
  hosts: all
  tasks:
    - name: Create directory
      file:
        path: /opt/myapp/logs
        state: directory
        owner: deploy
        mode: '0755'

    - name: Create empty file
      file:
        path: /opt/myapp/.initialized
        state: touch

    - name: Create symlink
      file:
        src: /opt/myapp/current
        dest: /opt/myapp/stable
        state: link

    - name: Remove file
      file:
        path: /tmp/old_file.txt
        state: absent
```

---

#### Модуль `template` — Jinja2-шаблоны

`template` работает как `copy`, но перед копированием **обрабатывает файл как Jinja2-шаблон** — подставляет переменные, выполняет условия и циклы.

Шаблон `nginx.conf.j2`:
```nginx
worker_processes {{ worker_processes }};

http {
    server {
        listen {{ http_port }};
        server_name {{ server_name }};
    }
}
```

Плейбук:
```yaml
- name: Configure nginx
  hosts: webservers
  vars:
    worker_processes: 4
    http_port: 80
    server_name: myapp.example.com
  tasks:
    - template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
```

Результат: в `/etc/nginx/nginx.conf` будут подставлены реальные значения переменных.

---

#### Модуль `find` — поиск файлов

```yaml
- name: Find and process old log files
  hosts: all
  tasks:
    - name: Find log files older than 30 days
      find:
        paths: /var/log/app
        patterns: "*.log"
        age: 30d
        recurse: yes
      register: old_logs

    - name: Remove old log files
      file:
        path: "{{ item.path }}"
        state: absent
      loop: "{{ old_logs.files }}"
```

---

#### Модуль `archive` / `unarchive` — сжатие и распаковка

```yaml
- name: Archive and extract files
  hosts: all
  tasks:
    - name: Create archive of logs
      archive:
        path: /var/log/app/
        dest: /backup/app_logs.tar.gz
        format: gz

    - name: Extract application package
      unarchive:
        src: /local/packages/app-v2.tar.gz
        dest: /opt/app/
        remote_src: no   # src находится на controller, не на хосте
```

---

#### Модуль `acl` — управление правами доступа

```yaml
- name: Set ACL permissions
  hosts: all
  tasks:
    - name: Give deploy user read access to config
      acl:
        path: /etc/sensitive/config.conf
        entity: deploy
        etype: user
        permissions: r
        state: present
```

---

### Категория 4: Database — модули для баз данных

Ansible умеет управлять базами данных: создавать и удалять БД, управлять пользователями, настраивать права.

**Поддерживаемые СУБД:** MySQL/MariaDB, PostgreSQL, MongoDB, MS SQL Server

**Примеры:**

```yaml
- name: Configure MySQL
  hosts: dbservers
  tasks:
    - name: Create application database
      mysql_db:
        name: myapp_production
        state: present
        encoding: utf8mb4

    - name: Create DB user
      mysql_user:
        name: appuser
        password: "{{ db_password }}"
        priv: "myapp_production.*:ALL"
        host: "%"
        state: present

    - name: Create PostgreSQL database
      postgresql_db:
        name: analytics
        encoding: UTF-8
        state: present

    - name: Create PostgreSQL user
      postgresql_user:
        name: analyst
        password: "{{ analyst_password }}"
        db: analytics
        priv: CONNECT
        state: present
```

---

### Категория 5: Cloud — модули для облачных платформ

Облачные модули — одна из сильнейших сторон Ansible. Они позволяют управлять виртуальной инфраструктурой через API облачных провайдеров.

**Поддерживаемые платформы:**
- Amazon AWS (EC2, S3, RDS, VPC, ELB, Route53, IAM и сотни других)
- Microsoft Azure (VM, Storage, Networking, AKS)
- Google Cloud Platform (Compute Engine, GKE, Cloud SQL)
- VMware (vSphere, vCenter)
- OpenStack
- Docker

**Пример: управление AWS EC2:**

```yaml
- name: Provision AWS infrastructure
  hosts: localhost
  tasks:
    - name: Create EC2 instance
      amazon.aws.ec2_instance:
        name: "web-server-01"
        key_name: my-ssh-key
        instance_type: t3.medium
        image_id: ami-0c55b159cbfafe1f0
        region: eu-west-1
        security_groups:
          - web-sg
          - monitoring-sg
        vpc_subnet_id: subnet-12345abc
        tags:
          Environment: production
          Role: webserver
        state: running
      register: ec2_instance

    - name: Create S3 bucket for assets
      amazon.aws.s3_bucket:
        name: myapp-assets-bucket
        region: eu-west-1
        versioning: yes
        state: present
```

**Пример: управление Docker-контейнерами:**

```yaml
- name: Manage Docker containers
  hosts: docker_hosts
  tasks:
    - name: Pull nginx image
      community.docker.docker_image:
        name: nginx
        tag: "1.24"
        source: pull

    - name: Run nginx container
      community.docker.docker_container:
        name: nginx-web
        image: nginx:1.24
        ports:
          - "80:80"
        volumes:
          - /opt/web:/usr/share/nginx/html
        restart_policy: always
        state: started
```

---

### Категория 6: Windows — модули для Windows

Ansible управляет Windows-серверами через PowerShell Remoting (WinRM). Для Windows созданы специальные модули с префиксом `win_`.

**Примеры модулей:** `win_copy`, `win_command`, `win_service`, `win_package`, `win_feature`, `win_user`, `win_file`, `win_regedit`

```yaml
- name: Configure Windows servers
  hosts: windows_servers
  tasks:
    - name: Copy file to Windows
      win_copy:
        src: /local/config.xml
        dest: C:\App\config.xml

    - name: Run PowerShell command
      win_command: Get-Process

    - name: Manage Windows service
      win_service:
        name: W3SVC
        state: started
        start_mode: auto

    - name: Install Windows Feature (IIS)
      win_feature:
        name: Web-Server
        state: present
        include_management_tools: yes

    - name: Create Windows user
      win_user:
        name: appuser
        password: "{{ win_password }}"
        groups:
          - IIS_IUSRS
        state: present

    - name: Set registry key
      win_regedit:
        path: HKCU:\Software\MyApp
        name: Version
        data: "2.0"
        type: String
```

---

## Часть 2: Детальный разбор ключевых модулей

### Модуль `service` — управление сервисами и идемпотентность

```yaml
- name: Start Services in order
  hosts: localhost
  tasks:
    - name: Start database (key=value syntax)
      service: name=postgresql state=started

    - name: Start database (map syntax — recommended)
      service:
        name: postgresql
        state: started
```

Оба варианта синтаксиса идентичны по результату. Map-синтаксис (с отступами) предпочтителен — он читабельнее.

**Критически важная концепция — идемпотентность:**

Параметр `state` принимает значения в «конечном состоянии», а не в виде команды:

| Значение | Смысл |
|---|---|
| `started` | Убедиться, что сервис **запущен** (если уже запущен — ничего не делать) |
| `stopped` | Убедиться, что сервис **остановлен** |
| `restarted` | **Перезапустить** сервис (всегда) |
| `reloaded` | **Перезагрузить** конфигурацию (без полного перезапуска) |

Сравните:
- `state: start` — это команда: «запусти». Каждый раз пытается запустить.
- `state: started` — это состояние: «должен быть запущен». Проверяет текущее состояние и действует только если нужно.

Именно использование состояний (не команд) обеспечивает **идемпотентность** — одинаковый результат при многократном запуске плейбука.

```yaml
# Полный пример: установить, включить в автозапуск, запустить
- name: Full service lifecycle
  hosts: webservers
  tasks:
    - name: Install nginx
      yum:
        name: nginx
        state: present

    - name: Enable nginx at boot
      service:
        name: nginx
        enabled: yes

    - name: Ensure nginx is running
      service:
        name: nginx
        state: started
```

---

### Модуль `lineinfile` — управление содержимым файлов

`lineinfile` — один из самых полезных модулей для конфигурационных файлов. Он гарантирует присутствие (или отсутствие) конкретной строки в файле.

**Проблема с shell-скриптом:**

```bash
# Этот скрипт создаёт дубликаты при повторном запуске!
echo "nameserver 10.1.250.10" >> /etc/resolv.conf
```

Каждый запуск добавляет строку. Запустил 5 раз — 5 одинаковых строк в файле.

**Решение с `lineinfile`:**

```yaml
- name: Add DNS server
  hosts: localhost
  tasks:
    - name: Ensure DNS entry is present (once and only once)
      lineinfile:
        path: /etc/resolv.conf
        line: 'nameserver 10.1.250.10'
```

Сколько бы раз ты ни запустил — строка будет ровно одна. Это идемпотентное поведение.

**Расширенные возможности `lineinfile`:**

```yaml
- name: Advanced lineinfile examples
  hosts: all
  tasks:
    # Заменить строку по регулярному выражению
    - name: Update SSH port
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^#?Port '
        line: 'Port 2222'

    # Вставить строку после определённой строки
    - name: Add option after section header
      lineinfile:
        path: /etc/app/config.conf
        insertafter: '^\[database\]'
        line: 'max_connections = 100'

    # Вставить строку перед определённой строкой
    - name: Add line before specific content
      lineinfile:
        path: /etc/hosts
        insertbefore: '^127.0.0.1'
        line: '# Custom hosts entries'

    # Удалить строку
    - name: Remove deprecated setting
      lineinfile:
        path: /etc/app/config.conf
        regexp: '^old_setting='
        state: absent

    # Создать файл если не существует
    - name: Add entry to new file
      lineinfile:
        path: /etc/app/custom.conf
        line: 'custom_option=true'
        create: yes
```

---

## Часть 3: Введение в плагины Ansible

### Зачем нужны плагины?

Модули отвечают на вопрос «что делать» (установить пакет, создать файл). Плагины отвечают на вопрос «как Ansible работает внутри» — они расширяют и модифицируют **поведение самого Ansible**, а не целевых систем.

Представьте ситуацию: у вас сотни виртуальных машин в AWS, которые постоянно создаются и удаляются. Хранить их IP-адреса в статическом инвентарном файле бессмысленно — файл устареет через несколько часов. Нужно **динамически** запрашивать список серверов у AWS API. Это задача плагина.

---

### Типы плагинов и их назначение

#### 1. Inventory Plugins — динамический инвентарь

Динамические инвентарные плагины запрашивают список хостов **в реальном времени** из внешних источников: AWS, Azure, GCP, VMware, Kubernetes и других.

Вместо статического файла с IP-адресами:
```ini
web1 ansible_host=192.168.1.10
web2 ansible_host=192.168.1.11
```

Используется YAML-файл настройки плагина:
```yaml
# aws_ec2.yml
plugin: amazon.aws.aws_ec2
regions:
  - eu-west-1
  - us-east-1
filters:
  instance-state-name: running
  tag:Environment: production
keyed_groups:
  - key: tags.Role
    prefix: role
```

Теперь Ansible сам запросит у AWS все запущенные EC2-инстансы с тегом `Environment=production` и автоматически сгруппирует их по тегу `Role`. При добавлении нового сервера в AWS — он автоматически появится в инвентаре без каких-либо правок файлов.

---

#### 2. Module Plugins — пользовательские модули

Когда встроенных модулей недостаточно, можно написать собственный. Например, модуль для работы с корпоративным API, которого нет в стандартной поставке. Написанный на Python модуль помещается в директорию `library/` рядом с плейбуком — Ansible подхватывает его автоматически.

```python
# library/my_module.py
from ansible.module_utils.basic import AnsibleModule

def main():
    module = AnsibleModule(
        argument_spec=dict(
            name=dict(type='str', required=True),
            state=dict(type='str', default='present',
                      choices=['present', 'absent'])
        )
    )
    # логика модуля
    module.exit_json(changed=True, msg="Done")

if __name__ == '__main__':
    main()
```

---

#### 3. Action Plugins — плагины действий

Action plugins выполняются на **управляющей машине** (controller), а не на целевом хосте. Они могут подготавливать данные, обрабатывать файлы шаблонов или организовывать сложные операции перед передачей управления модулю.

Фактически каждый модуль `template` и `copy` реализован через action plugin — именно поэтому они могут обрабатывать файлы на контроллере перед отправкой на хост.

Action plugins позволяют абстрагировать сложные операции (например, настройку load balancer с SSL и health checks) в удобный высокоуровневый интерфейс в плейбуке.

---

#### 4. Callback Plugins — хуки на события выполнения

Callback plugins подключаются к жизненному циклу выполнения плейбука и реагируют на события:
- Начало/конец плея
- Начало/конец задачи
- Успешное выполнение задачи
- Ошибка задачи
- Конец плейбука

**Встроенные callback plugins:**
- `json` — вывод результатов в JSON-формате (для CI/CD)
- `yaml` — более читаемый вывод
- `minimal` — минимальный вывод
- `profile_tasks` — показывает время выполнения каждой задачи

Пример включения callback плагина в `ansible.cfg`:
```ini
[defaults]
callback_whitelist = profile_tasks, mail
stdout_callback = yaml
```

**Пользовательский callback plugin** может, например:
- Отправлять уведомления в Slack при ошибке
- Записывать результаты в базу данных
- Создавать тикеты в Jira при падении задачи
- Отправлять метрики в Prometheus

---

#### 5. Lookup Plugins — получение внешних данных

Lookup plugins позволяют получать данные из внешних источников **прямо в плейбуке**: из файлов, переменных окружения, баз данных, HashiCorp Vault, AWS Secrets Manager и т.д.

```yaml
- name: Use lookup plugins
  hosts: localhost
  tasks:
    # Прочитать содержимое файла
    - debug:
        msg: "{{ lookup('file', '/etc/hostname') }}"

    # Получить переменную окружения
    - debug:
        msg: "PATH is {{ lookup('env', 'PATH') }}"

    # Получить секрет из HashiCorp Vault
    - name: Deploy with vault secret
      template:
        src: app.conf.j2
        dest: /etc/app/app.conf
      vars:
        db_password: "{{ lookup('hashi_vault', 'secret=secret/myapp/db:password') }}"

    # Получить параметр из AWS SSM Parameter Store
    - debug:
        msg: "{{ lookup('aws_ssm', '/myapp/production/db_password') }}"

    # Прочитать CSV-файл
    - debug:
        msg: "{{ lookup('csvfile', 'user1 file=users.csv col=2') }}"
```

---

#### 6. Filter Plugins — трансформация данных

Filter plugins позволяют обрабатывать и преобразовывать данные внутри плейбука. Они работают через синтаксис Jinja2: `{{ variable | filter }}`.

**Встроенные фильтры Ansible:**

```yaml
- name: Filter plugin examples
  hosts: localhost
  vars:
    my_list: [3, 1, 4, 1, 5, 9, 2, 6]
    my_string: "Hello World"
    my_path: "/etc/nginx/nginx.conf"
    ip_list:
      - "192.168.1.1"
      - "10.0.0.1"
      - "172.16.0.1"
  tasks:
    # Работа со строками
    - debug:
        msg: "{{ my_string | upper }}"       # HELLO WORLD
    - debug:
        msg: "{{ my_string | lower }}"       # hello world
    - debug:
        msg: "{{ my_string | replace('World', 'Ansible') }}"  # Hello Ansible

    # Работа с числами и списками
    - debug:
        msg: "{{ my_list | min }}"           # 1
    - debug:
        msg: "{{ my_list | max }}"           # 9
    - debug:
        msg: "{{ my_list | sort }}"          # [1,1,2,3,4,5,6,9]
    - debug:
        msg: "{{ my_list | unique }}"        # [3,1,4,5,9,2,6]
    - debug:
        msg: "{{ my_list | sum }}"           # 31

    # Работа с путями файловой системы
    - debug:
        msg: "{{ my_path | basename }}"      # nginx.conf
    - debug:
        msg: "{{ my_path | dirname }}"       # /etc/nginx

    # Работа с переменными
    - debug:
        msg: "{{ undefined_var | default('fallback_value') }}"

    # Работа с JSON
    - debug:
        msg: "{{ my_list | to_json }}"
    - debug:
        msg: "{{ my_list | to_yaml }}"

    # Сетевые фильтры
    - debug:
        msg: "{{ '192.168.1.100/24' | ipaddr('network') }}"  # 192.168.1.0
```

Пользовательские filter plugins пишутся на Python и помещаются в директорию `filter_plugins/`:

```python
# filter_plugins/custom_filters.py
def to_uppercase_list(value):
    return [item.upper() for item in value]

class FilterModule(object):
    def filters(self):
        return {'to_uppercase_list': to_uppercase_list}
```

Использование в плейбуке:
```yaml
- debug:
    msg: "{{ ['nginx', 'mysql', 'redis'] | to_uppercase_list }}"
# Вывод: ['NGINX', 'MYSQL', 'REDIS']
```

---

#### 7. Connection Plugins — управление протоколами подключения

Connection plugins определяют, **как** Ansible подключается к целевым системам.

| Плагин | Протокол | Назначение |
|---|---|---|
| `ssh` | SSH | Linux/Unix (по умолчанию) |
| `winrm` | WinRM | Windows |
| `local` | Нет | Локальное выполнение |
| `docker` | Docker API | Контейнеры |
| `kubectl` | Kubernetes API | Поды в Kubernetes |
| `network_cli` | SSH + CLI | Сетевые устройства (Cisco, Juniper) |
| `httpapi` | HTTP/HTTPS API | REST API устройств |
| `paramiko` | SSH (Python) | Альтернативный SSH |

Пример указания connection plugin для конкретной задачи:
```yaml
- name: Run task in Docker container
  hosts: localhost
  tasks:
    - name: Execute in container
      command: ls /app
      vars:
        ansible_connection: docker
        ansible_docker_extra_args: "--name my_container"
```

---

## Часть 4: Индекс модулей и плагинов

### Зачем нужен индекс?

Ansible содержит тысячи модулей и плагинов. Чтобы найти нужный и понять как его использовать, существует **Modules and Plugins Index** — централизованный каталог на docs.ansible.com.

### Возможности индекса:

**Поиск и фильтрация** — поиск по ключевым словам, категориям, провайдерам. Например, запрос "cisco" выдаст все модули для управления Cisco-оборудованием. Запрос "network" — всё для сетевой автоматизации.

**Детальная документация** для каждого модуля включает:
- Описание назначения
- Все параметры с типами и значениями по умолчанию
- Примеры использования
- Возвращаемые значения (для использования с `register`)
- Требования (версия Python, зависимости)
- Примечания об идемпотентности

**Совместимость версий** — каждый модуль указывает с какой версии Ansible он доступен. Это предотвращает ошибки типа «модуль не найден» при использовании функциональности, появившейся позже вашей версии Ansible.

**Вклад сообщества** — большинство модулей поддерживаются сообществом, что обеспечивает быстрое обновление и поддержку новых сервисов.

### Использование командной строки для работы с документацией:

```bash
# Список всех доступных модулей
$ ansible-doc -l

# Документация по конкретному модулю
$ ansible-doc service

# Краткое описание модуля (одна строка)
$ ansible-doc -s lineinfile

# Список доступных плагинов определённого типа
$ ansible-doc -t lookup -l
$ ansible-doc -t filter -l
$ ansible-doc -t connection -l
$ ansible-doc -t callback -l

# Документация по конкретному lookup-плагину
$ ansible-doc -t lookup file
```

Пример вывода `ansible-doc service`:
```
> SERVICE    (/usr/lib/python3/site-packages/ansible/modules/service.py)

  Controls services on remote hosts. Supported init systems
  include BSD init, OpenRC, SysV, Solaris SMF, systemd, upstart.

OPTIONS (= is mandatory):
= name
        Name of the service.
        type: str

- enabled
        Whether the service should start on boot.
        type: bool

- state
        `started`/`stopped` are idempotent actions that will not run
        commands unless necessary. `restarted` will always bounce
        the service. `reloaded` will always reload.
        choices: [reloaded, restarted, started, stopped]
```

---

## Итоговые выводы

**Категории модулей:**
- **System** — пользователи, группы, сервисы, firewall, cron, hostname
- **Command** — `command` (без shell), `shell` (с пайпами), `script` (локальный скрипт на удалённом хосте), `expect`
- **Files** — `copy`, `template`, `file`, `lineinfile`, `find`, `archive`, `acl`
- **Database** — MySQL, PostgreSQL, MongoDB, MSSQL
- **Cloud** — AWS, Azure, GCP, VMware, Docker (сотни модулей)
- **Windows** — `win_*` модули через WinRM/PowerShell

**Ключевые модули:**
- `command` vs `shell`: command без интерпретатора (нет пайпов), shell через `/bin/sh`
- `service`: используй `state: started/stopped` (состояние), а не `state: start/stop` (команда) — это обеспечивает идемпотентность
- `lineinfile`: идемпотентная замена `echo >> file` — гарантирует ровно одну копию строки
- `template`: `copy` + Jinja2-шаблонизация переменных

**Типы плагинов:**
- **Inventory** — динамический инвентарь из облаков, APIs
- **Module** — пользовательские модули на Python
- **Action** — выполняются на controller, а не на хосте
- **Callback** — хуки на события (уведомления, логирование, метрики)
- **Lookup** — получение внешних данных (файлы, Vault, AWS SSM, env)
- **Filter** — трансформация данных через `| filter` в Jinja2
- **Connection** — протоколы подключения (SSH, WinRM, Docker, kubectl)

**Индекс модулей и плагинов:**
- Основной ресурс: docs.ansible.com
- CLI: `ansible-doc module_name`
- Проверяй версию совместимости перед использованием нового модуля

---

# Подробное руководство по Roles, Collections и Handlers в Ansible

---

## Часть 1: Ansible Roles — роли

### Концепция ролей: аналогия с профессиями

Чтобы понять, что такое роль в Ansible, полезна аналогия с профессиями. В обществе у каждого человека есть роль — врач, инженер, полицейский, повар. Эта роль подразумевает определённый набор знаний, навыков и действий, которые человек освоил в процессе подготовки.

Точно так же серверы в инфраструктуре могут иметь роли:
- **Database server** — сервер базы данных
- **Web server** — веб-сервер
- **Redis messaging server** — сервер очередей сообщений
- **Backup server** — сервер резервного копирования

Назначить серверу роль — значит выполнить **все необходимые шаги** для его конфигурирования под эту роль.

Как стать врачом: медицинская школа → ординатура → лицензия.
Как сделать сервер MySQL: установить зависимости → установить пакеты MySQL → настроить сервис → создать базы и пользователей.

Это и есть роль — пакет задач, объединённых общей целью.

---

### Проблема без ролей: дублирование кода

Представьте: вы написали плейбук для установки MySQL:

```yaml
- name: Install and Configure MySQL
  hosts: db-server
  tasks:
    - name: Install Pre-Requisites
      yum:
        name: pre-req-packages
        state: present

    - name: Install MySQL Packages
      yum:
        name: mysql
        state: present

    - name: Start MySQL Service
      service:
        name: mysql
        state: started

    - name: Configure Database
      mysql_db:
        name: db1
        state: present
```

Плейбук работает. Через месяц коллега из другой команды хочет настроить MySQL на своих серверах. Он пишет точно такой же плейбук заново. Ещё через месяц — третий человек. В итоге один и тот же код существует в десятках мест, и когда нужно что-то исправить — приходится искать все копии.

Роли решают эту проблему кардинально.

---

### Роль вместо дублированного кода

С ролями плейбук превращается в:

```yaml
- name: Install and Configure MySQL
  hosts: db-server1,...,db-server100
  roles:
    - mysql
```

Пять строк вместо двадцати. Вся логика вынесена в роль `mysql`, которую можно переиспользовать в любом проекте, передать коллеге одним файлом или опубликовать в сообществе.

---

### Структура роли: что внутри?

Роль — это директория с фиксированной структурой поддиректорий. Каждая поддиректория отвечает за свой тип контента:

```
mysql/
├── tasks/
│   └── main.yml          # Основные задачи роли
├── vars/
│   └── main.yml          # Переменные (высокий приоритет)
├── defaults/
│   └── main.yml          # Переменные по умолчанию (низкий приоритет)
├── handlers/
│   └── main.yml          # Handlers (обработчики событий)
├── templates/
│   └── my.cnf.j2         # Jinja2-шаблоны конфигурационных файлов
├── files/
│   └── init.sql          # Статические файлы
├── meta/
│   └── main.yml          # Метаданные роли (зависимости)
└── README.md             # Документация роли
```

Содержимое каждой директории:

**`tasks/main.yml`** — список задач, которые выполняются при использовании роли:
```yaml
# tasks/main.yml
- name: Install Pre-Requisites
  yum:
    name: "{{ mysql_prereq_packages }}"
    state: present

- name: Install MySQL Packages
  yum:
    name: "{{ mysql_packages }}"
    state: present

- name: Start MySQL Service
  service:
    name: mysql
    state: started

- name: Configure Database
  mysql_db:
    name: "{{ db_config.db_name }}"
    state: present
```

**`vars/main.yml`** — переменные с высоким приоритетом (перекрывают defaults):
```yaml
# vars/main.yml
mysql_packages:
  - mysql
  - mysql-server
db_config:
  db_name: db1
```

**`defaults/main.yml`** — значения по умолчанию (самый низкий приоритет — легко переопределить):
```yaml
# defaults/main.yml
mysql_user_name: root
mysql_user_password: root
mysql_port: 3306
```

**`handlers/main.yml`** — handlers для роли:
```yaml
# handlers/main.yml
- name: Restart MySQL
  service:
    name: mysql
    state: restarted
```

**`templates/my.cnf.j2`** — шаблон конфигурационного файла MySQL:
```ini
[mysqld]
port = {{ mysql_port }}
user = {{ mysql_user_name }}
datadir = /var/lib/mysql
```

**`meta/main.yml`** — метаданные и зависимости от других ролей:
```yaml
# meta/main.yml
galaxy_info:
  author: your_name
  description: MySQL installation and configuration
  min_ansible_version: "2.9"
dependencies:
  - role: common   # Эта роль зависит от роли common
```

---

### Создание структуры роли через `ansible-galaxy init`

Ansible Galaxy предоставляет команду для автоматической генерации структуры роли:

```bash
$ ansible-galaxy init mysql
```

Вывод:
```
- Role mysql was created successfully
```

Команда создаёт всю структуру директорий автоматически:
```bash
$ tree mysql
mysql/
├── README.md
├── defaults/
│   └── main.yml
├── files/
├── handlers/
│   └── main.yml
├── meta/
│   └── main.yml
├── tasks/
│   └── main.yml
├── templates/
├── tests/
│   ├── inventory
│   └── test.yml
└── vars/
    └── main.yml
```

После создания структуры — наполняем содержимым нужные директории.

---

### Размещение ролей: где Ansible их ищет?

Ansible ищет роли в следующих местах (по порядку):

1. Директория `roles/` рядом с плейбуком
2. Пути, указанные в `roles_path` в `ansible.cfg`
3. Стандартные пути по умолчанию

```ini
# /etc/ansible/ansible.cfg
roles_path = /etc/ansible/roles
```

Проверить все пути поиска ролей:
```bash
$ ansible-config dump | grep ROLE
DEFAULT_ROLES_PATH = ['/root/.ansible/roles', '/usr/share/ansible/roles', '/etc/ansible/roles']
```

**Рекомендуемая структура проекта:**
```
project/
├── playbook.yml
├── inventory/
│   └── hosts.ini
└── roles/
    ├── mysql/
    │   ├── tasks/
    │   ├── vars/
    │   └── defaults/
    ├── nginx/
    │   └── tasks/
    └── common/
        └── tasks/
```

---

### Ansible Galaxy — репозиторий готовых ролей

**Ansible Galaxy** (galaxy.ansible.com) — это публичный репозиторий ролей, созданных сообществом. Тысячи готовых ролей для любых задач: установка веб-серверов, баз данных, инструментов мониторинга, систем безопасности.

**Перед написанием своей роли — проверьте Galaxy.** Высока вероятность, что кто-то уже создал именно то, что вам нужно, и поддерживает это в актуальном состоянии.

#### Установка роли из Galaxy:

```bash
$ ansible-galaxy install geerlingguy.mysql
```

Вывод при установке:
```
- downloading role 'mysql', owned by geerlingguy
- downloading role from https://github.com/geerlingguy/ansible-role-mysql/archive/2.9.5.tar.gz
- extracting geerlingguy.mysql to /etc/ansible/roles/geerlingguy.mysql
- geerlingguy.mysql (2.9.5) was installed successfully
```

Роль загружается в директорию ролей по умолчанию. Использование в плейбуке:

```yaml
- name: Install and Configure MySQL
  hosts: db-server
  roles:
    - geerlingguy.mysql
```

#### Установка в конкретную директорию:

```bash
$ ansible-galaxy install geerlingguy.mysql -p ./roles
```

Роль будет установлена в `./roles/geerlingguy.mysql` — рядом с вашим плейбуком.

#### Просмотр установленных ролей:

```bash
$ ansible-galaxy list
- geerlingguy.mysql, 2.9.5
- geerlingguy.nginx, 3.1.0
- kodekloud1.mysql, 1.0.0
```

---

### Использование нескольких ролей в одном плейбуке

```yaml
- name: Configure database and web servers
  hosts: db-and-webserver
  roles:
    - geerlingguy.mysql
    - nginx
```

Роли применяются **последовательно** в порядке их перечисления.

Можно передавать параметры роли через словарь:

```yaml
- name: Configure servers with role parameters
  hosts: all
  roles:
    - role: geerlingguy.mysql
      vars:
        mysql_root_password: "{{ vault_mysql_password }}"
        mysql_databases:
          - name: myapp_db
            encoding: utf8mb4
      become: yes

    - role: nginx
      vars:
        nginx_port: 8080
```

---

### Передача переопределённых переменных при использовании роли

Роль предоставляет значения по умолчанию в `defaults/main.yml`. Вы можете их переопределить:

```yaml
# В плейбуке:
- name: Setup MySQL with custom config
  hosts: db-server
  vars:
    mysql_user_name: appuser       # Переопределяем default
    mysql_user_password: secureP@ss
    mysql_port: 3307               # Нестандартный порт
  roles:
    - mysql
```

Или в инвентаре:
```ini
[db-server:vars]
mysql_user_name=produser
mysql_user_password=prodpass
```

---

## Часть 2: Ansible Collections — коллекции

### Что такое коллекция и чем она отличается от роли?

Если **роль** — это набор задач для конфигурирования сервера под конкретную цель, то **коллекция** — это более широкий контейнер, который может включать:

- Модули
- Роли
- Плагины
- Плейбуки
- Документацию

Коллекция — это **самодостаточная единица распространения контента** для Ansible. Она позволяет вендорам и сообществу упаковывать всё необходимое для работы с конкретной технологией или платформой в один пакет.

---

### Проблема без коллекций: фрагментация

Представьте: вы сетевой инженер, управляющий устройствами Cisco, Juniper и Arista. Для каждого вендора нужны специфические модули. В Ansible есть базовые модули, но они не покрывают все возможности оборудования. Раньше приходилось искать модули по разным источникам, устанавливать их вручную, следить за обновлениями каждого отдельно.

Коллекции решают это одной командой.

---

### Установка и использование коллекции

#### Установка из Ansible Galaxy:

```bash
# Коллекция для Cisco IOS
$ ansible-galaxy collection install network.cisco

# Коллекция для AWS
$ ansible-galaxy collection install amazon.aws

# Коллекция для Juniper
$ ansible-galaxy collection install network.juniper

# Коллекция для работы с MySQL
$ ansible-galaxy collection install community.mysql
```

#### Использование модулей коллекции в плейбуке:

**Способ 1: указать коллекцию в секции `collections`:**
```yaml
---
- hosts: localhost
  collections:
    - amazon.aws
  tasks:
    - name: Create an S3 bucket
      aws_s3_bucket:
        name: my-app-assets
        region: eu-west-1
        state: present
```

**Способ 2: использовать полное имя модуля (FQCN — Fully Qualified Collection Name):**
```yaml
---
- hosts: localhost
  tasks:
    - name: Create an S3 bucket
      amazon.aws.aws_s3_bucket:
        name: my-app-assets
        region: eu-west-1
        state: present
```

Формат FQCN: `namespace.collection_name.module_name`

FQCN — более явный и предпочтительный способ. Он устраняет неоднозначность, когда в разных коллекциях есть модули с одинаковыми именами.

---

### Структура коллекции

```
my_namespace/
└── my_collection/
    ├── galaxy.yml            # Метаданные коллекции
    ├── README.md
    ├── docs/
    ├── plugins/
    │   ├── modules/          # Пользовательские модули
    │   ├── lookup/           # Lookup plugins
    │   ├── filter/           # Filter plugins
    │   └── inventory/        # Inventory plugins
    ├── roles/
    │   └── my_role/          # Роли внутри коллекции
    └── playbooks/            # Плейбуки
```

---

### Использование пользовательской коллекции

```yaml
---
- hosts: localhost
  collections:
    - my_namespace.my_collection
  roles:
    - my_custom_role
  tasks:
    - name: Use custom module from collection
      my_namespace.my_collection.my_custom_module:
        param: value

    - name: Use lookup plugin from collection
      debug:
        msg: "{{ lookup('my_namespace.my_collection.my_lookup', 'key') }}"
```

---

### Управление зависимостями через `requirements.yml`

Для проектов с несколькими коллекциями создаётся файл `requirements.yml`:

```yaml
# requirements.yml
---
collections:
  - name: amazon.aws
    version: "1.5.0"

  - name: community.mysql
    version: "1.2.1"

  - name: network.cisco
    version: ">=2.0.0"

  - name: my_namespace.my_collection
    source: https://github.com/my-org/my-collection
    type: git
    version: main

  - name: community.general
    # без version — устанавливает последнюю
```

Установка всех зависимостей одной командой:
```bash
$ ansible-galaxy collection install -r requirements.yml
```

Это особенно ценно в CI/CD пайплайнах — одна команда разворачивает всё окружение.

---

### Пример: автоматизация сетевых устройств разных вендоров

```yaml
---
- name: Configure Cisco devices
  hosts: cisco_routers
  collections:
    - cisco.ios
  tasks:
    - name: Set hostname
      cisco.ios.ios_hostname:
        config:
          hostname: "{{ inventory_hostname }}"

    - name: Configure interfaces
      cisco.ios.ios_interfaces:
        config:
          - name: GigabitEthernet0/1
            description: "Uplink to core"
            enabled: true

- name: Configure Juniper devices
  hosts: juniper_switches
  collections:
    - junipernetworks.junos
  tasks:
    - name: Get device facts
      junipernetworks.junos.junos_facts:

    - name: Configure VLANs
      junipernetworks.junos.junos_vlans:
        config:
          - name: "VLAN_100"
            vlan_id: 100

- name: Configure Arista devices
  hosts: arista_switches
  collections:
    - arista.eos
  tasks:
    - name: Configure BGP
      arista.eos.eos_bgp_global:
        config:
          as_number: "65001"
```

Три вендора, три коллекции — всё в одном плейбуке, единый стиль, единое управление.

---

### Преимущества коллекций

**1. Расширенная функциональность** — вендоры публикуют официальные коллекции с поддержкой всех возможностей своих продуктов. AWS Collection содержит сотни модулей для управления каждым сервисом AWS.

**2. Модульность и переиспользование** — коллекция инкапсулирует всё необходимое. Установил одну коллекцию — получил модули, плагины и роли для целой платформы.

**3. Управление версиями** — можно зафиксировать конкретную версию коллекции в `requirements.yml`. Это обеспечивает воспроизводимость окружения — у всех разработчиков и в CI/CD будут одни и те же версии.

**4. Независимость от релизов Ansible** — раньше все модули поставлялись вместе с Ansible, и новые функции появлялись только при выходе новой версии. Коллекции обновляются независимо от основного Ansible — вендор может выпустить поддержку нового функционала без ожидания следующего релиза.

---

### Роли vs Коллекции: в чём разница?

| | Роли | Коллекции |
|---|---|---|
| Содержимое | Только задачи, переменные, шаблоны | Модули, роли, плагины, плейбуки |
| Назначение | Конфигурация сервера под роль | Платформа/вендор-специфичный функционал |
| Установка | `ansible-galaxy install` | `ansible-galaxy collection install` |
| Пространство имён | Простое имя (`mysql`) | Namespace.Collection (`amazon.aws`) |
| Масштаб | Один сервер/сервис | Вся платформа (AWS, Cisco, Docker) |
| Переиспользование | Внутри проекта/компании | Сообщество, вендоры |

Важно: **коллекции могут содержать роли**. Это не взаимоисключающие концепции.

---

## Часть 3: Ansible Handlers — обработчики событий

### Проблема без handlers

Представьте: вы управляете несколькими веб-серверами. Вы обновляете конфигурационный файл nginx через плейбук. Изменение конфигурации само по себе не имеет эффекта — nginx читает конфигурацию только при старте или перезагрузке. Значит, после изменения конфига нужно перезапустить сервис.

Наивный подход — добавить задачу перезапуска после каждого изменения конфигурации:

```yaml
tasks:
  - name: Update nginx config
    template:
      src: nginx.conf.j2
      dest: /etc/nginx/nginx.conf

  - name: Restart nginx
    service:
      name: nginx
      state: restarted
```

Проблемы этого подхода:

**Проблема 1: nginx перезапускается всегда**, даже если конфигурация не изменилась (файл уже актуальный). Каждый запуск плейбука — ненужный перезапуск сервиса, кратковременная недоступность.

**Проблема 2: дублирование при нескольких источниках изменений.** Если конфиг меняется в трёх задачах — нужно ставить перезапуск после каждой. И если все три задачи выполнились — nginx перезапустится три раза вместо одного.

```yaml
tasks:
  - template: ...    # меняет конфиг
  - service: restart # перезапуск 1
  - copy: ...        # меняет ещё файл
  - service: restart # перезапуск 2
  - lineinfile: ...  # меняет ещё строку
  - service: restart # перезапуск 3
```

**Проблема 3: невозможно условно пропустить перезапуск.** Задача перезапуска выполнится независимо от того, были ли реальные изменения.

---

### Решение: Handlers

Handler — это **специальная задача**, которая:
1. Выполняется только если была **явно вызвана** через `notify`
2. Вызывается только если вызывающая задача **реально внесла изменения** (статус `changed`)
3. Выполняется **один раз в конце плея**, независимо от того, сколько задач его вызвали

```yaml
- name: Deploy Application
  hosts: application_servers
  tasks:
    - name: Copy Application Code
      copy:
        src: app_code/
        dest: /opt/application/
      notify: Restart Application Service

  handlers:
    - name: Restart Application Service
      service:
        name: application_service
        state: restarted
```

Разбор примера:
- Задача `Copy Application Code` копирует файлы приложения
- Параметр `notify: Restart Application Service` — «если эта задача что-то изменила, вызови handler с таким именем»
- В секции `handlers:` определён handler `Restart Application Service`
- Если файлы уже актуальны — `copy` вернёт статус `ok`, а не `changed`, и handler **не вызовется**
- Если файлы изменились — `copy` вернёт `changed`, handler вызовется

---

### Ключевые свойства handlers

#### Свойство 1: Выполняются только при `changed`

```yaml
tasks:
  - name: Update nginx.conf
    template:
      src: nginx.conf.j2
      dest: /etc/nginx/nginx.conf
    notify: Reload nginx

handlers:
  - name: Reload nginx
    service:
      name: nginx
      state: reloaded
```

Сценарий А: конфиг уже актуален → `template` возвращает `ok` → handler не вызывается → nginx не перезагружается ✅

Сценарий Б: конфиг изменился → `template` возвращает `changed` → handler вызывается → nginx перезагружается ✅

---

#### Свойство 2: Выполняются один раз в конце плея

```yaml
tasks:
  - name: Update main config
    template:
      src: nginx.conf.j2
      dest: /etc/nginx/nginx.conf
    notify: Reload nginx

  - name: Update SSL config
    copy:
      src: ssl.conf
      dest: /etc/nginx/conf.d/ssl.conf
    notify: Reload nginx

  - name: Update virtual host
    template:
      src: vhost.conf.j2
      dest: /etc/nginx/conf.d/myapp.conf
    notify: Reload nginx

handlers:
  - name: Reload nginx
    service:
      name: nginx
      state: reloaded
```

Все три задачи вызывают один и тот же handler. Но nginx перезагрузится **только один раз** — в конце плея, после выполнения всех задач. Это оптимально: сначала применяются все изменения, затем один перезапуск.

---

#### Свойство 3: Один handler может вызывать другой через `notify`

```yaml
tasks:
  - name: Update app config
    template:
      src: app.conf.j2
      dest: /etc/app/app.conf
    notify: Restart app service

handlers:
  - name: Restart app service
    service:
      name: myapp
      state: restarted
    notify: Verify app is running   # Handler вызывает другой handler

  - name: Verify app is running
    uri:
      url: http://localhost:8080/health
      status_code: 200
```

---

### Реальный практический пример

Полный плейбук деплоя веб-приложения с handlers:

```yaml
- name: Deploy Web Application
  hosts: webservers
  become: yes
  vars:
    app_version: "2.1.0"
    nginx_port: 80
    app_port: 8080

  tasks:
    - name: Install nginx
      yum:
        name: nginx
        state: present

    - name: Deploy nginx configuration
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
        validate: nginx -t -c %s   # Проверить конфиг перед применением
      notify:
        - Reload nginx
        - Check nginx status

    - name: Deploy virtual host config
      template:
        src: vhost.conf.j2
        dest: /etc/nginx/conf.d/myapp.conf
      notify: Reload nginx

    - name: Deploy application code
      copy:
        src: "app-{{ app_version }}.tar.gz"
        dest: /opt/app/
      notify: Restart application

    - name: Extract application
      unarchive:
        src: "/opt/app/app-{{ app_version }}.tar.gz"
        dest: /opt/app/
        remote_src: yes
      notify: Restart application

    - name: Update application config
      template:
        src: app.conf.j2
        dest: /opt/app/config/app.conf
      notify: Restart application

    - name: Ensure nginx is running
      service:
        name: nginx
        state: started
        enabled: yes

    - name: Ensure application is running
      service:
        name: myapp
        state: started
        enabled: yes

  handlers:
    - name: Reload nginx
      service:
        name: nginx
        state: reloaded

    - name: Check nginx status
      command: nginx -t
      register: nginx_check
      failed_when: nginx_check.rc != 0

    - name: Restart application
      service:
        name: myapp
        state: restarted
```

Что здесь происходит:
- Три задачи (`Deploy application code`, `Extract application`, `Update application config`) могут вызвать `Restart application`
- Если все три изменились — приложение перезапустится только **один раз**, в конце плея
- `Reload nginx` вызывается из двух задач — nginx перезагрузится один раз
- Если ни один из конфигурационных файлов не изменился — ни nginx, ни приложение не перезапустятся

---

### Принудительный запуск handlers: `meta: flush_handlers`

По умолчанию handlers выполняются в конце плея. Иногда нужно, чтобы handler выполнился **прямо сейчас**, не дожидаясь конца. Для этого используется специальная задача:

```yaml
tasks:
  - name: Update database config
    template:
      src: db.conf.j2
      dest: /etc/myapp/db.conf
    notify: Restart database

  - name: Flush handlers immediately
    meta: flush_handlers   # Запустить все накопившиеся handlers прямо сейчас

  - name: Run database migrations
    command: python manage.py migrate
    # Эта задача выполнится ПОСЛЕ перезапуска БД, а не в конце плея
```

---

### Handlers при использовании в ролях

В ролях handlers определяются в `handlers/main.yml`:

```yaml
# roles/nginx/handlers/main.yml
- name: Restart nginx
  service:
    name: nginx
    state: restarted

- name: Reload nginx
  service:
    name: nginx
    state: reloaded

- name: Test nginx config
  command: nginx -t
```

Handlers из роли автоматически доступны во всём плейбуке, который эту роль использует.

---

### Handlers с `listen` — группировка под общим именем

Можно дать handler псевдоним через `listen`, и несколько handlers будут срабатывать при одном `notify`:

```yaml
handlers:
  - name: Restart nginx
    service:
      name: nginx
      state: restarted
    listen: "web service changed"

  - name: Clear cache
    command: redis-cli FLUSHDB
    listen: "web service changed"

  - name: Notify monitoring
    uri:
      url: https://monitoring.example.com/api/deploy
      method: POST
    listen: "web service changed"

tasks:
  - name: Update app code
    copy:
      src: app/
      dest: /opt/app/
    notify: "web service changed"  # Вызовет все три handler'а
```

Один `notify: "web service changed"` вызовет все три handler'а, подписанных на это имя.

---

## Итоговые выводы

**Ansible Roles:**
- Роль = пакет задач + переменные + шаблоны + handlers для достижения одной цели
- Структура: `tasks/`, `vars/`, `defaults/`, `handlers/`, `templates/`, `files/`, `meta/`
- Создание скелета: `ansible-galaxy init role_name`
- Использование: `roles: - role_name` в плейбуке
- `defaults/main.yml` — легко переопределяемые значения по умолчанию
- `vars/main.yml` — значения с высоким приоритетом
- Ansible Galaxy — тысячи готовых ролей от сообщества
- Установка: `ansible-galaxy install author.role_name`

**Ansible Collections:**
- Коллекция = модули + роли + плагины + плейбуки в одном пакете
- Решают проблему распространения вендор-специфичного контента
- Формат: `namespace.collection` (например, `amazon.aws`, `cisco.ios`)
- Установка: `ansible-galaxy collection install namespace.collection`
- FQCN для модулей: `namespace.collection.module_name`
- `requirements.yml` — декларативное управление зависимостями
- Обновляются независимо от Ansible — вендоры могут выпускать обновления когда угодно

**Ansible Handlers:**
- Handler = специальная задача, выполняемая только при уведомлении
- Вызываются через `notify: Handler Name` в задаче
- Выполняются только если вызывающая задача вернула статус `changed`
- Выполняются **один раз в конце плея** независимо от количества вызовов
- Предотвращают лишние перезапуски и обеспечивают идемпотентность
- `meta: flush_handlers` — принудительный запуск прямо сейчас
- `listen:` — псевдоним для группировки нескольких handlers под одним именем
- В ролях располагаются в `handlers/main.yml`

---

# Подробное руководство по Jinja2 и шаблонизации в Ansible

---

## Часть 1: Что такое Jinja2 и зачем нужна шаблонизация

### Концепция шаблонизации

Шаблонизация — это подход, при котором вы создаёте **базовую структуру документа** (шаблон), а затем подставляете в неё конкретные значения переменных, получая готовый результат.

Классическая аналогия: генеральный директор хочет разослать приглашения на корпоратив всем сотрудникам. Письмо одно и то же, меняются только имя получателя и список членов его семьи. Вместо того чтобы писать каждое письмо вручную, берётся шаблон:

```
Уважаемый(ая) {{ имя_сотрудника }},

Приглашаем Вас и Вашу семью ({{ список_семьи }}) на наш ежегодный корпоратив!

С уважением,
Генеральный директор
```

Подставили данные — получили 500 персонализированных писем.

В IT это применяется повсеместно:
- **HTML-страницы** — один шаблон, разные данные для каждого пользователя
- **Конфигурационные файлы** — один шаблон nginx.conf, разные параметры для продакшн/стейджинг/dev окружений
- **Ansible playbooks** — одна задача, разные значения для каждого хоста

**Jinja2** — это шаблонизатор для Python, который Ansible использует как родной. Всё, что вы пишете в фигурных скобках `{{ }}` в Ansible — это Jinja2.

---

### Связь Jinja2 с Ansible

Jinja2 встроен в Ansible на самом глубоком уровне. Каждый раз, когда вы пишете `{{ переменная }}` в плейбуке, инвентаре или шаблоне — это Jinja2. Но Ansible идёт дальше и **расширяет** стандартный Jinja2 дополнительными фильтрами для задач инфраструктуры: работа с путями файлов, конвертация форматов, управление паролями, регулярные выражения.

---

## Часть 2: Базовый синтаксис Jinja2

### Подстановка переменных `{{ }}`

Двойные фигурные скобки — основной синтаксис Jinja2. Всё внутри них вычисляется и подставляется как значение.

```jinja2
The name is {{ my_name }}
```

Если `my_name = "Bond"`, результат:
```
The name is Bond
```

В контексте Ansible:
```yaml
- name: Print greeting
  hosts: localhost
  vars:
    user_name: "Alice"
    server_ip: "192.168.1.10"
  tasks:
    - debug:
        msg: "Hello, {{ user_name }}! Your server IP is {{ server_ip }}"
```

Вывод: `Hello, Alice! Your server IP is 192.168.1.10`

---

### Директивы `{% %}` — управляющие конструкции

Двойные фигурные скобки с процентами — это управляющие конструкции: циклы, условия, блоки. Они не выводят текст, а управляют логикой шаблона.

```jinja2
{% for item in list %}
    {{ item }}
{% endfor %}

{% if condition %}
    текст если условие истинно
{% endif %}
```

---

### Комментарии `{# #}`

```jinja2
{# Это комментарий — не попадёт в итоговый файл #}
{{ variable }}
```

---

## Часть 3: Фильтры — трансформация данных

### Что такое фильтр?

Фильтр преобразует значение переменной. Синтаксис: `{{ переменная | фильтр }}`. Фильтры можно **цепочить**: `{{ переменная | фильтр1 | фильтр2 }}`.

---

### Строковые фильтры

```jinja2
{{ my_name }}                                    => Bond
{{ my_name | upper }}                            => BOND
{{ my_name | lower }}                            => bond
{{ my_name | title }}                            => Bond
{{ my_name | replace("Bond", "Bourne") }}        => Bourne
{{ my_name | reverse }}                          => dnoB
{{ my_name | length }}                           => 4
{{ "  hello  " | trim }}                         => hello
{{ my_name | capitalize }}                       => Bond
```

Пример в плейбуке:
```yaml
- name: String manipulation
  hosts: localhost
  vars:
    environment: "production"
    app_name: "mywebapp"
  tasks:
    - debug:
        msg: "ENV: {{ environment | upper }}, App: {{ app_name | title }}"
    # Вывод: ENV: PRODUCTION, App: Mywebapp
```

---

### Фильтр `default` — значение по умолчанию

Если переменная не определена — вместо ошибки используется значение по умолчанию:

```jinja2
{{ first_name | default("James") }} {{ my_name }}
```

Если `first_name` не определена — подставится "James":
```
James Bond
```

Это критически важно при работе с конфигурационными файлами — защищает от ошибок при отсутствии переменной.

```jinja2
# redis.conf.j2
port {{ redis_port | default('6379') }}
tcp-keepalive {{ tcp_keepalive | default('300') }}
bind {{ ip_address | default('127.0.0.1') }}
```

Если `redis_port` не задан — используется порт 6379. Шаблон работает даже без явного определения всех переменных.

---

### Числовые фильтры

```jinja2
{{ 3.14159 | round }}          => 3.0
{{ 3.14159 | round(2) }}       => 3.14
{{ -5 | abs }}                 => 5
{{ 42 | float }}               => 42.0
{{ 3.7 | int }}                => 3
```

---

### Фильтры для списков

```jinja2
{{ [1, 2, 3] | min }}                          => 1
{{ [1, 2, 3] | max }}                          => 3
{{ [1, 2, 3, 2] | unique }}                    => [1, 2, 3]
{{ [1, 2, 3, 4] | union([4, 5]) }}             => [1, 2, 3, 4, 5]
{{ [1, 2, 3, 4] | intersect([4, 5]) }}         => [4]
{{ [3, 1, 2] | sort }}                         => [1, 2, 3]
{{ [1, 2, 3] | reverse | list }}               => [3, 2, 1]
{{ [1, 2, 3] | sum }}                          => 6
{{ [1, 2, 3] | length }}                       => 3
{{ ["a", "b", "c"] | join(", ") }}             => a, b, c
{{ [1, 2, 3] | random }}                       => случайный элемент
{{ [1, 2, 3] | shuffle }}                      => [2, 1, 3] (перемешанный)
```

Практический пример — выбрать случайный сервер из группы для балансировки:

```yaml
- name: Select random server
  hosts: localhost
  vars:
    servers:
      - web1.example.com
      - web2.example.com
      - web3.example.com
  tasks:
    - debug:
        msg: "Use server: {{ servers | random }}"
```

---

### Фильтры для работы с файловыми путями

#### Linux/Unix пути:

```jinja2
{{ "/etc/nginx/nginx.conf" | basename }}      => nginx.conf
{{ "/etc/nginx/nginx.conf" | dirname }}       => /etc/nginx
{{ "/etc/nginx/nginx.conf" | splitext }}      => ['/etc/nginx/nginx', '.conf']
{{ "/etc/nginx/nginx.conf" | expanduser }}    => (раскрывает ~/ в полный путь)
```

#### Windows пути (специальные фильтры Ansible):

```jinja2
{{ "c:\\windows\\system32\\hosts" | win_basename }}    => hosts
{{ "c:\\windows\\system32\\hosts" | win_dirname }}     => c:\windows\system32
{{ "c:\\windows\\system32\\hosts" | win_splitdrive }}  => ['c:', '\\windows\\system32\\hosts']
{{ "c:\\windows\\system32\\hosts" | win_splitdrive | first }}  => c:
```

**Почему нужны отдельные win_* фильтры?** Потому что в Windows путях используется обратный слеш `\`, а в Linux — прямой `/`. Стандартный `basename` понимает только `/`, поэтому на Windows-путях он вернёт неверный результат.

---

### Фильтры форматов данных

```jinja2
{# Конвертация в JSON #}
{{ my_dict | to_json }}

{# Конвертация в YAML #}
{{ my_dict | to_yaml }}

{# Красивый JSON с отступами #}
{{ my_dict | to_nice_json }}

{# Красивый YAML #}
{{ my_dict | to_nice_yaml }}

{# Парсинг JSON-строки в объект #}
{{ json_string | from_json }}

{# Парсинг YAML-строки в объект #}
{{ yaml_string | from_yaml }}
```

Практическое применение:

```yaml
- name: Convert data formats
  hosts: localhost
  vars:
    app_config:
      name: myapp
      port: 8080
      debug: false
  tasks:
    - name: Write config as JSON
      copy:
        content: "{{ app_config | to_nice_json }}"
        dest: /etc/app/config.json

    - name: Write config as YAML
      copy:
        content: "{{ app_config | to_nice_yaml }}"
        dest: /etc/app/config.yaml
```

---

### Фильтры для паролей и безопасности

```jinja2
{# Хэшировать пароль через SHA-512 #}
{{ "mypassword" | password_hash('sha512') }}

{# Генерировать случайный пароль и сохранять в файл #}
{{ lookup('password', '/tmp/passwordfile length=20') }}

{# Base64 кодирование/декодирование #}
{{ "hello world" | b64encode }}   => aGVsbG8gd29ybGQ=
{{ "aGVsbG8gd29ybGQ=" | b64decode }}  => hello world
```

---

### Фильтры для работы со словарями

```jinja2
{# Объединить два словаря #}
{{ dict1 | combine(dict2) }}

{# Получить список ключей #}
{{ my_dict | dict2items }}

{# Получить значение по ключу с default #}
{{ my_dict | default({}) | combine({'key': 'value'}) }}
```

---

### Фильтры регулярных выражений

```jinja2
{# Проверить, соответствует ли строка паттерну #}
{{ "hello world" | regex_search("world") }}    => world

{# Заменить по паттерну #}
{{ "hello world" | regex_replace("world", "ansible") }}    => hello ansible

{# Найти все совпадения #}
{{ "one1two2three3" | regex_findall("[0-9]+") }}    => ['1', '2', '3']
```

---

## Часть 4: Управляющие конструкции в Jinja2

### Циклы `for`

Базовый синтаксис:
```jinja2
{% for item in collection %}
    {{ item }}
{% endfor %}
```

#### Пример: генерация `resolv.conf`

Шаблон `resolv.conf.j2`:
```jinja2
{% for name_server in name_servers %}
nameserver {{ name_server }}
{% endfor %}
```

Переменная в плейбуке:
```yaml
vars:
  name_servers:
    - 10.1.1.2
    - 10.1.1.3
    - 8.8.8.8
```

Результирующий `/etc/resolv.conf`:
```
nameserver 10.1.1.2
nameserver 10.1.1.3
nameserver 8.8.8.8
```

Автоматически — три строки из списка. Добавите четвёртый DNS в переменную — появится четвёртая строка.

#### Пример: генерация конфигурации nginx upstream

Шаблон:
```jinja2
upstream backend {
{% for server in backend_servers %}
    server {{ server.host }}:{{ server.port }} weight={{ server.weight }};
{% endfor %}
}
```

Переменные:
```yaml
backend_servers:
  - host: 192.168.1.10
    port: 8080
    weight: 3
  - host: 192.168.1.11
    port: 8080
    weight: 2
  - host: 192.168.1.12
    port: 8080
    weight: 1
```

Результат:
```nginx
upstream backend {
    server 192.168.1.10:8080 weight=3;
    server 192.168.1.11:8080 weight=2;
    server 192.168.1.12:8080 weight=1;
}
```

#### Специальные переменные внутри цикла:

```jinja2
{% for item in items %}
    {{ loop.index }}     {# Номер итерации с 1 #}
    {{ loop.index0 }}    {# Номер итерации с 0 #}
    {{ loop.first }}     {# True если первая итерация #}
    {{ loop.last }}      {# True если последняя итерация #}
    {{ loop.length }}    {# Общее количество итераций #}
    {{ item }}
{% endfor %}
```

Пример использования — добавить запятую между элементами кроме последнего:

```jinja2
[
{% for server in servers %}
    "{{ server }}"{% if not loop.last %},{% endif %}

{% endfor %}
]
```

Результат:
```json
[
    "web1",
    "web2",
    "web3"
]
```

---

### Условия `if/elif/else`

Базовый синтаксис:
```jinja2
{% if condition %}
    содержимое если истина
{% elif other_condition %}
    содержимое если другое условие истина
{% else %}
    содержимое если все условия ложны
{% endif %}
```

#### Пример: условная конфигурация

Шаблон `app.conf.j2`:
```jinja2
[application]
debug = {% if environment == "development" %}true{% else %}false{% endif %}

log_level = {% if environment == "production" %}WARNING
{% elif environment == "staging" %}INFO
{% else %}DEBUG
{% endif %}

database_host = {{ db_host }}
{% if db_port is defined %}
database_port = {{ db_port }}
{% endif %}
```

При `environment = "production"`:
```ini
[application]
debug = false
log_level = WARNING
database_host = db.example.com
```

При `environment = "development"`:
```ini
[application]
debug = true
log_level = DEBUG
database_host = localhost
```

---

### Комбинирование циклов и условий

```jinja2
{% for server in servers %}
{% if server.enabled %}
server {{ server.name }} {
    address {{ server.ip }};
    port {{ server.port | default('80') }};
}
{% endif %}
{% endfor %}
```

Переменные:
```yaml
servers:
  - name: web1
    ip: 192.168.1.10
    port: 8080
    enabled: true
  - name: web2
    ip: 192.168.1.11
    enabled: false    # Этот сервер будет пропущен
  - name: web3
    ip: 192.168.1.12
    enabled: true
    # port не задан — используется default '80'
```

Результат:
```
server web1 {
    address 192.168.1.10;
    port 8080;
}
server web3 {
    address 192.168.1.12;
    port 80;
}
```

---

## Часть 5: Модуль `template` в Ansible

### `copy` vs `template`: в чём разница?

| Модуль | Что делает | Когда использовать |
|---|---|---|
| `copy` | Копирует файл без изменений | Статические файлы (бинарники, сертификаты) |
| `template` | Обрабатывает файл как Jinja2-шаблон | Конфиги с переменными |

```yaml
# copy — файл копируется как есть:
- copy:
    src: nginx.conf        # Статический файл
    dest: /etc/nginx/nginx.conf

# template — файл обрабатывается Jinja2 перед копированием:
- template:
    src: nginx.conf.j2     # Шаблон с {{ переменными }}
    dest: /etc/nginx/nginx.conf
```

---

### Практический пример: от статики к динамике

#### Шаг 1: Статический подход (плохо)

Инвентарь:
```ini
[web_servers]
web1 ansible_host=172.20.1.100
web2 ansible_host=172.20.1.101
web3 ansible_host=172.20.1.102
```

Плейбук:
```yaml
- hosts: web_servers
  tasks:
    - name: Copy static index.html
      copy:
        src: index.html
        dest: /var/www/nginx-default/index.html
```

Статический HTML:
```html
<!DOCTYPE html>
<html>
<body>
This is a Web Server
</body>
</html>
```

Проблема: все три сервера получат одинаковую страницу. Невозможно понять, на каком сервере ты находишься.

---

#### Шаг 2: Динамический подход с шаблоном (хорошо)

Меняем `copy` на `template` и создаём шаблон:

Плейбук:
```yaml
- hosts: web_servers
  tasks:
    - name: Deploy personalized index.html
      template:
        src: index.html.j2
        dest: /var/www/nginx-default/index.html
```

Шаблон `index.html.j2`:
```html
<!DOCTYPE html>
<html>
<body>
This is {{ inventory_hostname }} Server
</body>
</html>
```

Результат на `web1`:
```html
<!DOCTYPE html>
<html>
<body>
This is web1 Server
</body>
</html>
```

На `web2`:
```html
This is web2 Server
```

На `web3`:
```html
This is web3 Server
```

Один шаблон — три уникальных страницы. `inventory_hostname` — магическая переменная Ansible, автоматически содержащая имя хоста из инвентаря.

---

### Расширенный пример: страница с системной информацией

Шаблон использует Ansible Facts:

```html
{# index.html.j2 #}
<!DOCTYPE html>
<html>
<head>
    <title>{{ inventory_hostname }} - System Info</title>
</head>
<body>
    <h1>Server: {{ inventory_hostname }}</h1>
    <h2>System Information</h2>
    <ul>
        <li>IP Address: {{ ansible_default_ipv4.address }}</li>
        <li>OS: {{ ansible_distribution }} {{ ansible_distribution_version }}</li>
        <li>Architecture: {{ ansible_architecture }}</li>
        <li>CPU cores: {{ ansible_processor_cores }}</li>
        <li>RAM: {{ ansible_memtotal_mb }} MB</li>
        <li>Disk: {{ ansible_devices.sda.size | default('N/A') }}</li>
    </ul>
    <h2>Uptime</h2>
    <p>{{ ansible_uptime_seconds | int // 3600 }} hours</p>
</body>
</html>
```

---

## Часть 6: Генерация реальных конфигурационных файлов

### Nginx конфигурация

Шаблон `nginx.conf.j2`:
```nginx
worker_processes {{ nginx_worker_processes | default(ansible_processor_cores) }};
pid /run/nginx.pid;

events {
    worker_connections {{ nginx_worker_connections | default(1024) }};
}

http {
    server_tokens {{ nginx_server_tokens | default('off') }};

    upstream {{ app_name }}_backend {
{% for server in backend_servers %}
        server {{ server.host }}:{{ server.port }};
{% endfor %}
    }

    server {
        listen {{ nginx_port | default(80) }};
        server_name {{ server_name }};

        location / {
            fastcgi_pass {{ host }}:{{ port }};
            fastcgi_param QUERY_STRING $query_string;
        }

        location ~ \.(gif|jpg|png)$ {
            root {{ image_path }};
        }

{% if ssl_enabled | default(false) %}
        listen {{ ssl_port | default(443) }} ssl;
        ssl_certificate {{ ssl_cert_path }};
        ssl_certificate_key {{ ssl_key_path }};
{% endif %}
    }
}
```

Переменные для продакшн-среды (`group_vars/production.yml`):
```yaml
nginx_worker_processes: 4
nginx_worker_connections: 4096
nginx_port: 80
server_name: myapp.example.com
host: localhost
port: 9000
image_path: /data/images
ssl_enabled: true
ssl_port: 443
ssl_cert_path: /etc/ssl/myapp.crt
ssl_key_path: /etc/ssl/myapp.key
backend_servers:
  - host: 192.168.1.10
    port: 8080
  - host: 192.168.1.11
    port: 8080
```

---

### Redis конфигурация с default-фильтрами

Шаблон `redis.conf.j2`:
```jinja2
bind {{ ip_address | default('127.0.0.1') }}
protected-mode yes
port {{ redis_port | default('6379') }}
tcp-backlog {{ tcp_backlog | default('511') }}
timeout {{ timeout | default('0') }}
tcp-keepalive {{ tcp_keepalive | default('300') }}
daemonize no
supervised no

{% if redis_password is defined and redis_password %}
requirepass {{ redis_password }}
{% endif %}

maxmemory {{ redis_maxmemory | default('256mb') }}
maxmemory-policy {{ redis_maxmemory_policy | default('allkeys-lru') }}

{% if redis_slave | default(false) %}
slaveof {{ redis_master_host }} {{ redis_master_port | default('6379') }}
{% endif %}
```

При минимальных переменных (только `ip_address` задан):
```ini
bind 192.168.1.100
protected-mode yes
port 6379
tcp-backlog 511
timeout 0
tcp-keepalive 300
daemonize no
supervised no
maxmemory 256mb
maxmemory-policy allkeys-lru
```

---

### MySQL конфигурация

```ini
{# my.cnf.j2 #}
[mysqld]
innodb-buffer-pool-size={{ mysql_buffer_pool_size | default('128M') }}
datadir={{ mysql_datadir | default('/var/lib/mysql') }}
user={{ mysql_user | default('mysql') }}
port={{ mysql_port | default('3306') }}
bind-address={{ mysql_bind_address | default('127.0.0.1') }}

max_connections={{ mysql_max_connections | default('151') }}
max_connect_errors={{ mysql_max_connect_errors | default('100') }}

{% if mysql_slow_query_log | default(false) %}
slow_query_log = 1
slow_query_log_file = {{ mysql_slow_query_log_file | default('/var/log/mysql/slow.log') }}
long_query_time = {{ mysql_long_query_time | default('2') }}
{% endif %}
```

---

### Генерация конфига для HAProxy (load balancer)

Это один из самых ярких примеров силы шаблонизации:

```jinja2
{# haproxy.cfg.j2 #}
global
    log 127.0.0.1 local0
    maxconn {{ haproxy_maxconn | default(4096) }}

defaults
    timeout connect {{ haproxy_timeout_connect | default('5s') }}
    timeout client  {{ haproxy_timeout_client | default('30s') }}
    timeout server  {{ haproxy_timeout_server | default('30s') }}

{% for service in haproxy_services %}
frontend {{ service.name }}_frontend
    bind *:{{ service.port }}
    default_backend {{ service.name }}_backend

backend {{ service.name }}_backend
    balance {{ service.balance | default('roundrobin') }}
{% for server in groups[service.group] %}
    server {{ server }} {{ hostvars[server]['ansible_host'] }}:{{ service.backend_port }} check
{% endfor %}

{% endfor %}
```

Переменные:
```yaml
haproxy_services:
  - name: web
    port: 80
    group: webservers
    backend_port: 8080
  - name: api
    port: 8443
    group: api_servers
    backend_port: 3000
    balance: leastconn
```

Здесь `groups[service.group]` — магическая переменная, возвращающая список хостов группы из инвентаря. `hostvars[server]['ansible_host']` — IP-адрес каждого хоста. Шаблон автоматически генерирует конфиг HAProxy, включая все серверы из инвентаря.

---

## Часть 7: Переменная интерполяция в плейбуках

### Как Jinja2 работает в плейбуках

Когда Ansible запускает задачу, он **сначала** обрабатывает все `{{ }}` в параметрах задачи через Jinja2, подставляя значения переменных. Только потом передаёт параметры модулю.

```yaml
- hosts: all
  tasks:
    - nsupdate:
        server: '{{ dns_server }}'
```

Инвентарь:
```ini
web1 ansible_host=172.20.1.100 dns_server=10.5.5.4
web2 ansible_host=172.20.1.101 dns_server=10.5.5.5
```

При выполнении на `web1` → `server: '10.5.5.4'`
При выполнении на `web2` → `server: '10.5.5.5'`

Интерполяция происходит **на хосте** с его набором переменных.

---

### Интерполяция в пути файлов

```yaml
- name: Create version-specific directory
  hosts: all
  vars:
    app_name: myapp
    app_version: "2.1.0"
    deploy_base: /opt
  tasks:
    - file:
        path: "{{ deploy_base }}/{{ app_name }}/{{ app_version }}"
        state: directory

    - template:
        src: "{{ app_name }}.conf.j2"
        dest: "/etc/{{ app_name }}/config.conf"
```

---

## Часть 8: Расположение шаблонов в ролях

### Структура директорий для шаблонов

В ролях шаблоны хранятся в директории `templates/`:

```
roles/
└── nginx/
    ├── tasks/
    │   └── main.yml
    ├── handlers/
    │   └── main.yml
    ├── vars/
    │   └── main.yml
    ├── defaults/
    │   └── main.yml
    └── templates/
        ├── nginx.conf.j2         # Основная конфигурация
        ├── vhost.conf.j2         # Виртуальный хост
        └── ssl.conf.j2           # SSL настройки
```

В задачах роли не нужно указывать полный путь к шаблону — Ansible автоматически ищет шаблоны в директории `templates/` роли:

```yaml
# roles/nginx/tasks/main.yml
- name: Deploy nginx configuration
  template:
    src: nginx.conf.j2         # Ищет в roles/nginx/templates/nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  notify: Reload nginx

- name: Deploy virtual host
  template:
    src: vhost.conf.j2
    dest: /etc/nginx/conf.d/{{ app_name }}.conf
  notify: Reload nginx
```

---

### Полный пример роли nginx с шаблонами

**`roles/nginx/defaults/main.yml`:**
```yaml
nginx_port: 80
nginx_worker_processes: 1
nginx_worker_connections: 1024
nginx_server_tokens: "off"
ssl_enabled: false
```

**`roles/nginx/tasks/main.yml`:**
```yaml
- name: Install nginx
  package:
    name: nginx
    state: present

- name: Deploy nginx.conf
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    validate: nginx -t -c %s
  notify: Reload nginx

- name: Deploy virtual host config
  template:
    src: vhost.conf.j2
    dest: /etc/nginx/conf.d/{{ app_name }}.conf
  notify: Reload nginx

- name: Enable nginx
  service:
    name: nginx
    state: started
    enabled: yes
```

**`roles/nginx/templates/nginx.conf.j2`:**
```nginx
worker_processes {{ nginx_worker_processes }};
pid /run/nginx.pid;

events {
    worker_connections {{ nginx_worker_connections }};
}

http {
    server_tokens {{ nginx_server_tokens }};
    include /etc/nginx/conf.d/*.conf;
}
```

**Плейбук использующий роль:**
```yaml
- name: Deploy web servers
  hosts: webservers
  vars:
    app_name: myapp
    nginx_port: 8080
    nginx_worker_processes: 4
  roles:
    - nginx
```

---

## Итоговые выводы

**Jinja2 — основа шаблонизации в Ansible:**
- `{{ переменная }}` — подстановка значения
- `{% управляющая конструкция %}` — циклы, условия
- `{# комментарий #}` — не попадает в результат

**Фильтры — трансформация данных:**
- Строковые: `upper`, `lower`, `title`, `replace`, `trim`, `length`
- Значение по умолчанию: `default('fallback')` — защита от ошибок при неопределённых переменных
- Числовые: `round`, `abs`, `int`, `float`
- Списковые: `min`, `max`, `unique`, `sort`, `sum`, `join`, `random`, `union`, `intersect`
- Файловые пути: `basename`, `dirname` (Linux), `win_basename`, `win_splitdrive` (Windows)
- Форматы: `to_json`, `to_yaml`, `from_json`, `from_yaml`, `to_nice_json`
- Безопасность: `password_hash`, `b64encode`, `b64decode`
- Регулярные выражения: `regex_search`, `regex_replace`, `regex_findall`

**Управляющие конструкции:**
- `for` — итерация по спискам → многострочные конфиги из массивов переменных
- `if/elif/else` — условный контент → разные конфиги для dev/staging/production
- `loop.index`, `loop.first`, `loop.last` — специальные переменные внутри цикла

**Модуль `template`:**
- Заменяет `copy` когда файл содержит переменные
- Файлы шаблонов именуются с расширением `.j2`
- В ролях хранятся в `templates/`, Ansible находит их автоматически
- Параметр `validate` — проверяет результат перед применением

**Практические применения:**
- Персонализированные HTML-страницы для каждого сервера
- Конфигурационные файлы nginx, redis, mysql, haproxy
- Автоматическая генерация `resolv.conf`, `hosts`, etc.
- Конфиги load balancer, автоматически включающие все хосты из инвентаря