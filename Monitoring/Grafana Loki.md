# Разбор Grafana Loki курса

**Created:** 5/25/2026 15:59:24  
**Updated:** 6/9/2026 2:39:00  
**Exported:** 6/14/2026 21:52:07  
**Link:** [https://claude.ai/chat/9e9cc4fb-998f-47f2-ba19-6c9a6fca3b85](https://claude.ai/chat/9e9cc4fb-998f-47f2-ba19-6c9a6fca3b85)  

## Assistant:

> 5/25/2026 16:00:37

# Grafana Loki: Полное руководство

## Что такое Loki?

Loki — это система агрегации логов, разработанная компанией Grafana Labs. Её главная особенность в том, что она **не индексирует содержимое логов целиком**, как это делает Elasticsearch, а индексирует только метаданные — так называемые **метки (labels)**. Это принципиальное архитектурное решение даёт несколько ключевых преимуществ:

- **Снижение затрат** — меньше данных для индексации означает меньше ресурсов и денег на хранение.
- **Простота управления** — не нужен отдельный специалист, как это часто требуется при работе с Elasticsearch.
- **Знакомая экосистема** — если вы уже работаете с Prometheus и Grafana, Loki покажется вам очень привычным: схожий синтаксис запросов, те же концепции меток.

Когда в системе что-то идёт не так, Loki позволяет быстро найти нужные логи по временному диапазону и меткам, не перебирая гигабайты проиндексированного текста.

---

## Архитектура Loki

### Как устроен сбор логов

Loki сам по себе не собирает логи — для этого используются **агенты-сборщики**, которые устанавливаются на серверы и непрерывно отправляют данные в Loki. Grafana Labs предоставляет собственный агент — **Promtail**, но архитектура открытая, и вы можете использовать:

- **Promtail** — нативный агент Loki, самый простой в настройке.
- **Fluentd** — популярный универсальный агрегатор логов.
- **Logstash** — часть стека ELK, тоже совместим с Loki.
- **Fluent Bit** — лёгкий вариант Fluentd для ресурсоограниченных сред.

### Обработка и маркировка логов

Когда лог попадает на сервер Loki, система делает следующее:

1. **Парсит** запись и извлекает основное содержимое.
2. **Считывает метки** — те, которые вы настроили в агенте.
3. **Индексирует только метки**, а полный текст лога сохраняет отдельно.

Пример лога с метками:

```
labels {job='syslog', env='production'}
{"level":40,"time":1689639590833,"pid":23220,"hostname":"DESKTOP80RTSJL",
 "method":"GET","route":"/products","code":"200"}
```

Здесь Loki проиндексирует только `job='syslog'` и `env='production'`. Сам JSON-объект хранится как есть, без индексации по каждому полю. Это и есть ключевое отличие от Elasticsearch.

### Хранилище

Loki поддерживает несколько бэкендов для хранения данных:

- **Локальная файловая система** — подходит для разработки и небольших сред.
- **Amazon S3** и другие объектные хранилища — рекомендуется для продакшна, дёшево и масштабируется автоматически.

### Запросы с помощью LogQL

Для запросов к логам Loki использует собственный язык **LogQL**. Он намеренно похож на PromQL (язык Prometheus), что снижает порог входа. Запросы можно выполнять:

- Через **Grafana Explore** — удобный графический интерфейс.
- Через **CLI** — для автоматизации и скриптов.

### Типичная схема архитектуры

Представьте такую инфраструктуру:

```
[Node 1] --> Promtail --> |              |
                          | Loki Server  | <-- Grafana (визуализация)
[Node 2] --> Promtail --> |              |
```

Логи с Node 1 и Node 2 собираются Promtail, отправляются в Loki, где маркируются, хранятся и индексируются. Grafana подключается к Loki как к источнику данных и позволяет строить дашборды и выполнять запросы.

---

## Установка Loki

### Шаг 1: Загрузка конфигурационных файлов

Первым делом скачайте готовые конфигурационные файлы для Loki и Promtail:

```bash
wget https://raw.githubusercontent.com/grafana/loki/main/cmd/loki/loki-local-config.yaml
wget https://raw.githubusercontent.com/grafana/loki/main/clients/cmd/promtail/promtail-local-config.yaml
```

### Шаг 2: Загрузка бинарного файла Loki

Перейдите на [страницу релизов Loki на GitHub](https://github.com/grafana/loki/releases) и выберите версию под вашу архитектуру. Для Linux AMD64:

```bash
curl -O -L "https://github.com/grafana/loki/releases/download/v2.8.2/loki-linux-amd64.zip"
ls                          # убедитесь, что файл скачался
unzip loki-linux-amd64.zip  # распакуйте архив
chmod a+x loki-linux-amd64  # сделайте исполняемым
```

### Шаг 3: Изучение конфигурационного файла

Откройте файл в редакторе:

```bash
vi loki-local-config.yaml
```

Типичное содержимое файла:

```yaml
auth_enabled: false

server:
  http_listen_port: 3100    # HTTP порт для API и метрик
  grpc_listen_port: 9096    # gRPC порт для внутренней коммуникации

common:
  instance_addr: 127.0.0.1
  path_prefix: /tmp/loki
  storage:
    filesystem:
      chunks_directory: /tmp/loki/chunks  # где хранятся данные логов
      rules_directory: /tmp/loki/rules    # где хранятся правила алертинга
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory  # для одной ноды достаточно in-memory хранилища

query_range:
  results_cache:
    cache:
      embedded_cache:
        enabled: true
        max_size_mb: 100  # кэш результатов запросов

schema_config:
  configs:
    - from: 2020-10-24
      # ... настройки схемы хранения
```

Если позже вы захотите перейти на S3, нужно изменить секцию `storage` — это единственное, что нужно поменять.

### Шаг 4: Запуск Loki

На Linux:
```bash
./loki-linux-amd64 -config.file=loki-local-config.yaml
```

На Windows:
```bash
.\loki-windows-amd64.exe --config.file=loki-local-config.yaml
```

В выводе вы должны увидеть строки вроде:
```
level=info ... msg="waiting until compactor is ACTIVE in the ring"
level=info ... msg="recovered WAL checkpoint recovery finished" elapsed=1.148398ms errors=false
level=info ... msg="adding connection" addr=127.0.0.1:9096
```

### Шаг 5: Проверка работы

Откройте браузер и перейдите по адресу:
```
http://[IP_АДРЕС_LOKI]:3100/metrics
```

Если вы видите текст с метриками — Loki работает корректно.

---

## Установка Promtail

Promtail устанавливается на каждый сервер, с которого нужно собирать логи. В нашем примере это Node 1 и Node 2.

### Скачивание и распаковка

На каждой ноде выполните:

```bash
wget https://github.com/grafana/loki/releases/download/v2.8.2/promtail-linux-amd64.zip
unzip promtail-linux-amd64.zip
```

Если на Node 2 не установлен `unzip`:

```bash
sudo apt install unzip
```

После распаковки вы должны увидеть файл `promtail-linux-amd64` в директории.

### Конфигурационный файл Promtail

Скачайте базовый конфиг:

```bash
wget https://raw.githubusercontent.com/grafana/loki/main/clients/cmd/promtail/promtail-local-config.yaml
```

Типичное содержимое:

```yaml
server:
  http_listen_port: 9080   # порт, на котором слушает Promtail
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml  # файл для хранения позиций чтения логов

clients:
  - url: http://localhost:3100/loki/api/v1/push  # адрес Loki сервера

scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs           # имя задания — будет меткой в Loki
          __path__: /var/log/*log  # какие файлы собирать
```

**Важно:** В секции `clients` замените `localhost` на реальный IP-адрес вашего Loki-сервера, если Promtail и Loki работают на разных машинах:

```yaml
clients:
  - url: http://192.168.1.10:3100/loki/api/v1/push
```

### Запуск Promtail

```bash
sudo ./promtail-linux-amd64 -config.file=promtail-local-config.yaml
```

`sudo` нужен, потому что системные логи в `/var/log/` доступны только суперпользователю. Пример успешного вывода:

```
level=info ... msg="Starting Promtail" version="(version=2.8.2, ...)"
level=info ... msg="tail routine: started" path=/var/log/kern.log
level=info ... msg="Seeked /var/log/syslog - &{Offset:3449718 Whence:0}"
```

Строки `tail routine: started` означают, что Promtail начал читать файлы логов.

---

## Запросы к логам через Grafana

### Подключение Loki как источника данных

1. Откройте Grafana (обычно `http://localhost:3000`).
2. Перейдите в **Connections → Data Sources → Add data source**.
3. Выберите **Loki**.
4. Укажите URL: `http://localhost:3100` (или IP вашего Loki).
5. Нажмите **Save & Test** — должно появиться сообщение об успешном подключении.

### Базовые запросы LogQL

Перейдите в раздел **Explore** и выберите Loki как источник данных.

**Получить все логи с меткой `job=varlogs`:**
```logql
{job="varlogs"}
```

**Отфильтровать только строки, содержащие слово "docker":**
```logql
{job="varlogs"} |= "docker"
```

**Логи из конкретного файла:**
```logql
{filename="/var/log/kern.log"}
```

**Логи из конкретного файла с фильтром по ключевому слову:**
```logql
{filename="/var/log/kern.log"} |= "docker"
```

**Логи из нескольких файлов (используется регулярное выражение):**
```logql
{filename=~"/var/log/kern.log|/var/log/syslog"}
```

---

## Сбор логов приложений (на примере Node.js)

Системные логи — это хорошо, но на практике важнее всего логи ваших приложений. Рассмотрим пример с Node.js-приложением.

### Структура приложения

Приложение работает на Node 1 и Node 2, пишет логи в файл `/home/vagrant/app/app.log` в JSON-формате:

```json
{"level":40,"time":1689639590833,"pid":23220,"hostname":"node-2",
 "method":"GET","route":"/products","code":"200"}
```

Поля логов:
- `level` — уровень: 30 = info, 40 = warn, 50 = error, 60 = fatal.
- `method` — HTTP-метод запроса.
- `route` — маршрут.
- `code` — HTTP-код ответа.
- `hostname` — с какого сервера пришёл лог.

### Обновление конфигурации Promtail

Остановите Promtail на Node 1 (`Ctrl+C`) и откройте конфиг:

```bash
nano promtail-local-config.yaml
```

Добавьте второй `scrape_config` для логов приложения:

```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  # Системные логи (как раньше)
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs
          __path__: /var/log/*log

  # Логи Node.js приложения (новый блок)
  - job_name: api
    static_configs:
      - targets:
          - localhost
        labels:
          job: apilogs           # уникальная метка для логов приложения
          __path__: /home/vagrant/app/*log  # путь к логам приложения
```

Сохраните файл и повторите то же на Node 2. Затем перезапустите Promtail на обоих серверах:

```bash
sudo ./promtail-linux-amd64 -config.file=promtail-local-config.yaml
```

### Запросы к логам приложения в Grafana

**Все логи приложения:**
```logql
{job="apilogs"} |= ""
```

**Логи с конкретного файла:**
```logql
{job="apilogs", filename="/home/vagrant/app/app.log"} |= ""
```

В Grafana вы увидите записи вроде:
```
2023-07-18 02:26:04.912  {"level":30,...,"hostname":"node-1","method":"GET","route":"/users/","code":201}
2023-07-18 02:26:04.857  {"level":30,...,"hostname":"node-2","method":"PATCH","route":"/cart","code":404}
```

Grafana умеет разбирать JSON-логи и строить по ним графики, фильтры и дашборды — например, можно визуализировать количество ошибок (code 500) по времени.

---

## Итоги и ключевые выводы

| Компонент | Роль | Где стоит |
|---|---|---|
| **Loki** | Хранение и индексирование логов | Центральный сервер |
| **Promtail** | Сбор и отправка логов | На каждой ноде |
| **Grafana** | Визуализация и запросы | Отдельный сервер или вместе с Loki |

**Главные принципы Loki:**

1. **Индексируются только метки** — это делает Loki быстрым и дешёвым по сравнению с полнотекстовым индексированием.
2. **Гибкость агентов** — можно использовать Promtail, Fluentd, Logstash или Fluent Bit.
3. **Масштабируемость** — легко переключиться с локального хранилища на S3 простым изменением конфига.
4. **Интеграция с Grafana** — единая точка входа для метрик (Prometheus) и логов (Loki).
5. **LogQL** — мощный язык запросов с поддержкой регулярных выражений, фильтрации по меткам и ключевым словам.

Loki особенно хорошо подходит для команд, которые уже используют Prometheus и Grafana: вы получаете единую наблюдаемость (observability) без необходимости разворачивать и поддерживать тяжёлые решения вроде Elasticsearch.

## Assistant:

> 6/9/2026 2:39:00

# Loki в Kubernetes: Полное руководство

## Концепция: зачем разворачивать Loki внутри Kubernetes?

Когда ваши приложения работают в Kubernetes, логи разбросаны по множеству контейнеров на разных нодах. Без централизованного решения вам пришлось бы подключаться к каждому поду отдельно и вручную просматривать логи — это нереально в промышленной среде.

Есть два подхода к размещению Loki:
- **Внешний** — Loki и Grafana работают на отдельных серверах за пределами кластера.
- **Внутрикластерный** — Loki, Grafana и Promtail развёрнуты прямо в Kubernetes.

Внутрикластерный вариант удобнее: всё управляется единым инструментом (Helm), меньше сетевых сложностей, проще масштабировать вместе с кластером.

### Как это работает на уровне архитектуры

```
Нода 1: [Pod A] [Pod B]  →  Promtail (DaemonSet) ──┐
Нода 2: [Pod C] [Pod D]  →  Promtail (DaemonSet) ──┼──→ Loki ──→ Grafana
Нода 3: [Pod E] [Pod F]  →  Promtail (DaemonSet) ──┘
```

Ключевой момент здесь — **DaemonSet**. Это специальный тип ресурса Kubernetes, который гарантирует, что на **каждой** ноде кластера запущена ровно одна копия пода. Когда в кластер добавляется новая нода, Kubernetes автоматически разворачивает на ней Promtail — вам ничего не нужно делать вручную.

На каждой ноде работает процесс **kubelet**, который собирает логи со своих подов. Promtail читает эти логи из директории `/var/log/pods/` и отправляет их в Loki.

---

## Развёртывание стека через Helm

Ручная настройка Loki, Promtail и Grafana по отдельности — это десятки YAML-файлов и часы работы. Helm решает эту проблему: несколько команд, и весь стек готов.

### Шаг 1: Добавление репозитория Grafana

```bash
helm repo add grafana https://grafana.github.io/helm-charts
```

Ожидаемый вывод:
```
"grafana" has been added to your repositories
```

### Шаг 2: Обновление репозиториев

```bash
helm repo update
```

```
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "grafana" chart repository
Update Complete. ⚓ Happy Helming! ⚓
```

### Шаг 3: Поиск доступных чартов

```bash
helm search repo loki
```

Вы увидите несколько вариантов:

| Чарт | Версия | Описание |
|---|---|---|
| `grafana/loki` | 5.10.0 | Простой масштабируемый режим |
| `grafana/loki-distributed` | 0.71.1 | Микросервисный режим |
| `grafana/loki-stack` | 2.6.1 | Loki + Promtail + Grafana вместе |
| `grafana/promtail` | 6.14.1 | Только Promtail |

Для большинства задач подходит **`grafana/loki-stack`** — он включает всё необходимое в одном пакете.

### Шаг 4: Изучение и настройка значений чарта

Перед установкой важно изучить настройки по умолчанию и при необходимости их изменить:

```bash
helm show values grafana/loki-stack > values.yaml
```

Откройте файл в редакторе. По умолчанию Grafana **отключена**, что неудобно. Нужно включить её явно. Вот как выглядит итоговый `values.yaml`:

```yaml
# Promtail включён и знает, куда отправлять логи
promtail:
  enabled: true
  config:
    logLevel: info
    serverPort: 3101
    clients:
      # Loki будет доступен по имени релиза внутри кластера
      - url: http://{{ .Release.Name }}:3100/loki/api/v1/push

# Fluent Bit не нужен — используем Promtail
fluent-bit:
  enabled: false

# Grafana включена с автоматической настройкой источника данных Loki
grafana:
  enabled: true
  sidecar:
    datasources:
      label: ""
      labelValue: ""
      enabled: true
      maxLines: 1000
  image:
    tag: latest
```

Обратите внимание на строку `http://{{ .Release.Name }}:3100/loki/api/v1/push`. Это шаблон Helm: `{{ .Release.Name }}` заменится на имя релиза при установке. Если вы устанавливаете как `helm install loki ...`, то URL станет `http://loki:3100/loki/api/v1/push` — это внутренний DNS-адрес сервиса Kubernetes.

### Шаг 5: Установка стека

```bash
helm install --values values.yaml loki grafana/loki-stack
```

Вывод:
```
NAME: loki
LAST DEPLOYED: Sun Aug  6 19:03:53 2023
NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES:
The Loki stack has been deployed to your cluster.
Loki can now be added as a datasource in Grafana.
```

Предупреждения `policy/v1beta1 PodSecurityPolicy is deprecated` можно игнорировать — это не ошибки, а информационные сообщения о том, что старый API устарел.

### Шаг 6: Проверка развёртывания

```bash
kubectl get all
```

Пример вывода:
```
NAME                                        READY   STATUS    RESTARTS   AGE
pod/loki-0                                  1/1     Running   0          40s
pod/loki-grafana-5df4fd7d99-x4794           2/2     Running   0          40s
pod/loki-promtail-bk9rj                     1/1     Running   0          40s

NAME                      TYPE        CLUSTER-IP       PORT(S)
service/loki              ClusterIP   10.96.247.199    3100/TCP
service/loki-grafana      ClusterIP   10.103.158.170   80/TCP
service/loki-headless     ClusterIP   None             3100/TCP
service/loki-memberlist   ClusterIP   None             7946/TCP

daemonset.apps/loki-promtail     DESIRED: 1   CURRENT: 1   READY: 1
deployment.apps/loki-grafana     READY: 1/1
statefulset.apps/loki            READY: 1/1
```

Что здесь важно понять:
- **StatefulSet для Loki** — используется потому, что Loki хранит состояние (данные логов), и ему нужен стабильный сетевой идентификатор.
- **Deployment для Grafana** — стандартное развёртывание без состояния.
- **DaemonSet для Promtail** — гарантирует запуск на каждой ноде. В данном примере нода одна, поэтому `DESIRED: 1`.

---

## Подключение к Grafana

Все сервисы имеют тип **ClusterIP** — это значит, они доступны только внутри кластера. Для локального доступа используется **port-forward**.

### Получение пароля администратора

Helm автоматически создаёт секрет с паролем Grafana. Найдём его:

```bash
kubectl get secret
```

```
NAME                    TYPE      DATA   AGE
loki                    Opaque    1      5m51s
loki-grafana            Opaque    3      5m51s
loki-promtail           Opaque    1      5m51s
```

Секрет `loki-grafana` содержит три поля:
- `admin-password` — пароль (40 байт, закодирован в Base64)
- `admin-user` — имя пользователя (5 байт = "admin")
- `ldap.toml` — конфиг LDAP (пустой)

Декодируем пароль одной командой:

```bash
kubectl get secret loki-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
```

Команда делает следующее:
- `kubectl get secret loki-grafana` — получает секрет
- `-o jsonpath="{.data.admin-password}"` — извлекает только поле с паролем
- `| base64 --decode` — декодирует из Base64 в читаемый текст

### Настройка port-forward

Получаем имя пода Grafana:

```bash
kubectl get pods
```

```
NAME                                 READY   STATUS    AGE
loki-0                               1/1     Running   2m37s
loki-grafana-5df4fd7d99-x4794        2/2     Running   2m37s
loki-promtail-bk9rj                  1/1     Running   2m37s
```

Запускаем проброс порта:

```bash
kubectl port-forward pod/loki-grafana-5df4fd7d99-x4794 3000:3000
```

Теперь открываем браузер: `http://localhost:3000`. Логинимся: логин `admin`, пароль — полученный выше.

Grafana автоматически добавила Loki как источник данных (это произошло благодаря настройке `sidecar.datasources.enabled: true` в `values.yaml`). Убедиться можно в разделе **Data Sources**.

---

## Просмотр логов Kubernetes в Grafana

### Базовые запросы

После входа в Grafana перейдите в раздел **Explore** и выберите Loki как источник данных.

Promtail в Kubernetes автоматически добавляет к логам богатый набор меток:
- `app` — имя приложения
- `component` — компонент
- `filename` — путь к файлу лога
- `instance` — имя экземпляра пода
- `job` — задание сбора логов
- `namespace` — пространство имён Kubernetes
- `pod` — имя пода
- `node_name` — имя ноды

Пример запроса — логи etcd (системного компонента Kubernetes):

```logql
{pod="etcd-minikube"} |= ``
```

Вы увидите системные логи с метаданными: имя ноды, имя задания в Promtail, путь к файлу в `/var/log/pods/`.

---

## Анализ конфигурации Promtail в Kubernetes

### Как Promtail настроен внутри кластера

Конфигурация Promtail хранится в Kubernetes Secret (не в ConfigMap, потому что может содержать чувствительные данные). Получим и декодируем её:

```bash
kubectl get secret loki-promtail -o jsonpath="{.data.promtail\.yaml}" | base64 --decode
```

Вот ключевые части конфигурации:

**Секция монтирования томов** (из описания пода):
```yaml
Mounts:
  /etc/promtail           # конфигурационный файл (из Secret)
  /run/promtail           # рабочая директория Promtail
  /var/lib/docker/containers  # логи Docker (только чтение)
  /var/log/pods           # логи подов Kubernetes (только чтение)
```

Promtail читает логи из `/var/log/pods/` — стандартное место, куда kubelet записывает вывод контейнеров.

**Секция scrape_configs** (обнаружение сервисов):

```yaml
scrape_configs:
  - job_name: kubernetes-pods
    pipeline_stages:
      - cri: {}   # парсим формат Container Runtime Interface
    kubernetes_sd_configs:
      - role: pod   # обнаруживаем все поды автоматически
    relabel_configs:
      # Извлекаем имя приложения из нескольких возможных источников
      - source_labels:
          - __meta_kubernetes_pod_label_app_kubernetes_io_name
          - __meta_kubernetes_pod_label_app
          - __tmp_controller_name
          - __meta_kubernetes_pod_name
        regex: ^.*([^[;]+)(;.*)?$
        action: replace
        target_label: app

      # Путь к файлам логов через UID пода
      - action: replace
        replacement: /var/log/pods/*$1/*.log
        separator: /
        source_labels:
          - __meta_kubernetes_pod_uid
          - __meta_kubernetes_pod_container_name
        target_label: __path__
```

**Kubernetes Service Discovery** (`kubernetes_sd_configs`) — это мощный механизм: Promtail сам обнаруживает все поды в кластере через Kubernetes API и начинает собирать их логи. Вам не нужно вручную прописывать каждый под.

**Relabeling** — правила переименования меток. Prefix `__meta_kubernetes_` означает метаданные, которые Kubernetes предоставляет о каждом поде. Они преобразуются в читаемые метки: `app`, `namespace`, `pod`, `container` и т.д.

---

## Развёртывание приложения с автоматическим сбором логов

### Создание Deployment

Создайте файл `app-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api    # эта метка будет использована Promtail для идентификации
    spec:
      containers:
      - name: api
        image: kodekloud/loki-demo    # демо-образ, генерирующий случайные логи
        resources:
          limits:
            memory: "128Mi"
            cpu: "500m"
```

Образ `kodekloud/loki-demo` генерирует случайные HTTP-запросы в формате JSON — идеально для тестирования.

### Деплой и проверка

```bash
kubectl apply -f app-deployment.yaml
# deployment.apps/api created

kubectl get pods
```

```
NAME                                    READY   STATUS    RESTARTS   AGE
api-5bb95b4844-ln5xk                    1/1     Running   0          6s
loki-0                                  1/1     Running   0          14m
loki-grafana-5df4f4d7d99-x4794          2/2     Running   0          14m
loki-promtail-bk9rj                     1/1     Running   0          14m
```

Никакой дополнительной настройки не нужно — Promtail уже собирает логи нового пода благодаря Kubernetes Service Discovery.

### Просмотр логов в Grafana

В Grafana Explore выберите метку `pod` и найдите `api-5bb95b4844-ln5xk`. Вы увидите логи вроде:

```json
{
  "level": 40,
  "time": 1691369373699,
  "pid": 1,
  "hostname": "api-5bb95b4844-ln5xk",
  "method": "POST",
  "route": "/users/",
  "code": "200"
}
```

---

## Promtail Pipelines: извлечение полей в метки

### Проблема

По умолчанию Promtail собирает логи как есть — JSON-строки в виде текста. Вы можете искать по тексту (`|= "method"`), но не можете фильтровать по конкретному полю как по метке.

Лог в Kubernetes выглядит так (двойная вложенность JSON):

```json
{
  "log": "{\"level\":50,\"time\":1691364036818,\"pid\":1,\"hostname\":\"api-5bb95b4844-ln5xk\",\"method\":\"PATCH\",\"route\":\"/users\",\"code\":\"201\"}\n",
  "stream": "stdout",
  "time": "2023-08-06T19:20:36.818396Z"
}
```

Внешний JSON — это обёртка Container Runtime. Внутри поля `log` — ещё один JSON с реальными данными. Цель: извлечь `code` и `method` как метки Loki.

### Решение: Pipeline stages

Обновляем конфигурацию Promtail, добавляя секцию `pipeline_stages`:

```yaml
scrape_configs:
  - job_name: kubernetes-pods
    pipeline_stages:
      - cri: {}   # шаг 1: парсим формат CRI (Container Runtime Interface)

      - match:
          selector: '{app="api"}'   # применяем только к подам с меткой app=api
          stages:
            # Шаг 2: из внешнего JSON извлекаем поле "log"
            - json:
                expressions:
                  log:   # сохраняем значение поля "log" во временную переменную

            # Шаг 3: из extracted["log"] извлекаем нужные поля
            - json:
                source: log   # источник — переменная из предыдущего шага
                expressions:
                  code: code       # извлекаем "code" и сохраняем как метку
                  method: method   # извлекаем "method" и сохраняем как метку
    kubernetes_sd_configs:
      - role: pod
    # ... остальные relabel_configs
```

**Пошаговое объяснение pipeline:**

1. `cri: {}` — разбирает стандартный формат вывода контейнеров (timestamp + поток + флаги).
2. `match` с `selector: '{app="api"}'` — этот pipeline применяется только к логам от нашего API-приложения. Системные поды будут обрабатываться стандартно.
3. Первый `json` stage — извлекает строку из поля `log` внешнего JSON.
4. Второй `json` stage с `source: log` — парсит уже извлечённую строку как JSON и берёт из неё `code` и `method`.

### Применение изменений в Kubernetes

Конфигурация Promtail хранится в Secret, поэтому нельзя просто отредактировать файл — нужно обновить Secret:

**1. Сохраняем текущую конфигурацию:**
```bash
kubectl get secret loki-promtail \
  -o jsonpath="{.data.promtail\.yaml}" \
  | base64 --decode > promtail.yaml
```

**2. Редактируем файл** (добавляем pipeline stages как показано выше).

**3. Удаляем старый Secret:**
```bash
kubectl delete secret loki-promtail
```

**4. Создаём новый Secret из обновлённого файла:**
```bash
kubectl create secret generic loki-promtail --from-file=./promtail.yaml
```

**5. Перезапускаем под Promtail:**
```bash
kubectl delete pod loki-promtail-bk9rj
```

Kubernetes автоматически создаст новый под с обновлённой конфигурацией. Через несколько секунд проверяем:

```bash
kubectl get pod
```

### Результат в Grafana

После применения изменений логи обогащаются новыми метками. Теперь можно делать точные запросы:

**Все запросы с кодом 200:**
```logql
{pod="api-5bb95b4844-ln5xk", code="200"} |= ""
```

**Все DELETE-запросы с ошибкой 500:**
```logql
{pod="api-5bb95b4844-ln5xk", method="DELETE", code="500"} |= ""
```

**Все ошибки в конкретном namespace:**
```logql
{namespace="default", code="500"} |= ""
```

Это кардинально отличается от полнотекстового поиска: вместо `|= "\"code\":\"500\""` (неудобно, медленно) вы пишете `code="500"` (чисто, быстро, индексировано).

---

## Итоговая архитектура всего стека

```
┌─────────────────────────────────────────────────────────┐
│                   Kubernetes Cluster                     │
│                                                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │  Node 1  │  │  Node 2  │  │  Node 3  │              │
│  │          │  │          │  │          │              │
│  │ [API Pod]│  │ [API Pod]│  │ [etcd]   │              │
│  │ [App Pod]│  │ [App Pod]│  │ [kube-ap]│              │
│  │          │  │          │  │          │              │
│  │ Promtail │  │ Promtail │  │ Promtail │  ← DaemonSet │
│  │(DaemonSet│  │(DaemonSet│  │(DaemonSet│              │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘              │
│       │             │             │                      │
│       └─────────────┼─────────────┘                     │
│                     ▼                                    │
│              ┌─────────────┐                             │
│              │    Loki     │  ← StatefulSet              │
│              │ (port 3100) │                             │
│              └──────┬──────┘                             │
│                     │                                    │
│              ┌──────▼──────┐                             │
│              │   Grafana   │  ← Deployment               │
│              │  (port 80)  │                             │
│              └─────────────┘                             │
│                     ▲                                    │
│            port-forward :3000                            │
└─────────────────────┼───────────────────────────────────┘
                       │
                  Браузер пользователя
                  http://localhost:3000
```

---

## Ключевые выводы

**Почему Helm — это правильный выбор для Loki в Kubernetes:**
одна команда разворачивает весь стек, автоматическая настройка Grafana datasource, Promtail уже знает, где искать логи Kubernetes.

**Почему DaemonSet — единственно правильный способ деплоя Promtail:**
гарантирует сбор логов с каждой ноды, включая новые ноды при масштабировании кластера.

**Почему Pipeline stages критически важны:**
без них вы ищете текст в JSON-строках (медленно). С ними поля становятся индексированными метками (быстро и удобно). Разница особенно заметна при большом объёме логов.

**Главный принцип безопасности:** пароли в Kubernetes хранятся в Secrets в кодировке Base64 — это не шифрование. Для продакшна используйте внешние vault-решения (HashiCorp Vault, AWS Secrets Manager).

**Port-forward только для разработки:** в продакшне нужен Ingress или LoadBalancer для доступа к Grafana снаружи кластера.

Powered by Claude Exporter (https://www.ai-chat-exporter.net)
