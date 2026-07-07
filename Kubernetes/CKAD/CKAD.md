# 1.0 - Полное руководство по Kubernetes: Архитектура, контейнеры и поды

Давай разберём всё по порядку — от фундаментальных понятий до практических примеров.

---

## Часть 1. Архитектура Kubernetes

### Что такое нода (Node)?

Нода — это машина (физическая или виртуальная), на которой установлен Kubernetes. Раньше ноды называли «minions». Именно на нодах запускаются контейнеры с твоими приложениями.

**Проблема одной ноды:** если она выходит из строя, приложение перестаёт работать. Решение — объединять ноды в **кластер**.

### Что такое кластер (Cluster)?

Кластер — это группа нод, работающих вместе. Преимущества:
- Если одна нода падает, другие продолжают обслуживать пользователей
- Нагрузка распределяется между нодами
- Обеспечивается высокая доступность (High Availability)

### Мастер-нода (Master Node)

Мастер-нода управляет всем кластером. Она:
- Хранит информацию о состоянии кластера
- Следит за здоровьем рабочих нод
- Перераспределяет рабочие нагрузки при сбоях

### Компоненты Kubernetes

При установке Kubernetes автоматически разворачиваются следующие компоненты:

| Компонент | Где живёт | Что делает |
|---|---|---|
| **API Server** | Мастер | Фронтенд кластера — принимает команды от пользователей и инструментов |
| **etcd** | Мастер | Распределённое key-value хранилище всех данных кластера |
| **Controller Manager** | Мастер | Следит за состоянием кластера и исправляет отклонения |
| **Scheduler** | Мастер | Решает, на какую ноду поставить новый контейнер |
| **Kubelet** | Каждая рабочая нода | Агент, который следит за тем, чтобы контейнеры работали |
| **Container Runtime** | Каждая рабочая нода | ПО для запуска контейнеров (например, containerd) |

**Мнемоника:** мастер думает и командует, рабочие ноды исполняют.

### Основные команды kubectl

```bash
kubectl run hello-minikube       # запустить приложение
kubectl cluster-info             # информация о кластере
kubectl get nodes                # список всех нод
```

---

## Часть 2. Docker vs ContainerD — история и эволюция

### Почему вообще возник этот вопрос?

Изначально Kubernetes был написан только под Docker. Docker — это не просто среда запуска контейнеров, а целый комбайн, включающий:
- Docker CLI (командная строка)
- Docker API
- Инструменты сборки образов
- Управление томами (volumes)
- Систему безопасности
- Среду выполнения контейнеров — **containerd** + **runc**

Когда появились альтернативные среды выполнения (например, **rkt**), Kubernetes ввёл **Container Runtime Interface (CRI)** — стандартный интерфейс, через который любая совместимая среда может работать с Kubernetes.

**Проблема:** Docker создавался до CRI и не поддерживал его нативно. Kubernetes пришлось сделать костыль — **Docker Shim** — временный мост между Docker и CRI.

### Что такое containerd?

Containerd — это тот самый компонент внутри Docker, который непосредственно управляет контейнерами (через runc). Он:
- Полностью совместим с CRI
- Может работать как самостоятельная среда выполнения без Docker
- Является graduated-проектом CNCF (это знак зрелости и надёжности)

### Что произошло в Kubernetes 1.24?

Docker Shim был удалён. Kubernetes больше не поддерживает Docker напрямую. Теперь используется containerd (или другие CRI-совместимые среды) напрямую.

**Важно:** это не значит, что Docker умер! Docker по-прежнему:
- Используется для разработки и сборки образов
- Популярен среди разработчиков
- Создаёт образы, совместимые с containerd (оба следуют стандарту OCI)

Kubernetes просто перестал использовать Docker как **среду выполнения** в production-кластерах.

---

## Часть 3. Инструменты командной строки: ctr, nerdctl, crictl

### 1. `ctr` — отладочный инструмент containerd

Поставляется вместе с containerd. Предназначен для отладки, не для повседневной работы.

```bash
# Установка containerd
tar Cxzvf /usr/local containerd-1.6.2-linux-amd64.tar.gz

# Работа с ctr
ctr images pull docker.io/library/redis:alpine
ctr run docker.io/library/redis:alpine redis
```

Ограничения: скудный функционал, не рекомендуется для регулярного использования.

### 2. `nerdctl` — полноценная замена Docker CLI

Docker-совместимый интерфейс для containerd. Поддерживает:
- Шифрованные образы
- Lazy pulling (ленивая загрузка)
- P2P-распространение образов
- Подпись образов
- Интеграцию с namespace Kubernetes

```bash
nerdctl run --name redis redis:alpine
nerdctl run --name webserver -p 80:80 -d nginx
```

Это практически те же команды, что и в Docker — переход почти безболезненный.

### 3. `crictl` — универсальный инструмент для отладки CRI

Разработан сообществом Kubernetes. Работает с **любой** CRI-совместимой средой (containerd, CRI-O и др.). Главное отличие — он знает о подах Kubernetes, чего Docker не умеет.

```bash
crictl pull busybox      # загрузить образ
crictl images            # список образов
crictl ps -a             # список всех контейнеров
```

Команды очень похожи на Docker: `attach`, `exec`, `images`, `inspect`, `logs`, `ps`, `stats`, `version` — всё это есть в crictl.

### Настройка endpoint в Kubernetes 1.24+

До версии 1.24 crictl сам перебирал доступные сокеты. Теперь нужно указывать явно:

```bash
export CONTAINER_RUNTIME_ENDPOINT=unix:///run/containerd/containerd.sock
```

Другие возможные endpoints:
- `unix:///run/crio/crio.sock` — для CRI-O
- `unix:///var/run/cri-dockerd.sock` — для cri-dockerd

### Итоговое сравнение инструментов

| Инструмент | Кем создан | Для чего | Совместимость |
|---|---|---|---|
| `ctr` | containerd | Отладка | Только containerd |
| `nerdctl` | containerd | Повседневная работа | Только containerd |
| `crictl` | Kubernetes | Отладка в кластере | Любой CRI-runtime |

---

## Часть 4. Поды (Pods) — основа Kubernetes

### Что такое под?

Под — это наименьшая развёртываемая единица в Kubernetes. Kubernetes не запускает контейнеры напрямую — он оборачивает их в поды.

**Аналогия:** если контейнер — это программа, то под — это процесс операционной системы, в котором эта программа запускается.

### Масштабирование через поды

Когда растёт нагрузка — создаются новые поды, а не добавляются контейнеры в существующий под.

```
До масштабирования:     [Нода1: Pod(App)]
После масштабирования:  [Нода1: Pod(App)] [Нода1: Pod(App)]
При заполнении ноды:    [Нода1: Pod(App)] [Нода2: Pod(App)]
```

**Правило:** один экземпляр приложения = один под. Хочешь 3 копии — создай 3 пода.

### Мультиконтейнерные поды

Под может содержать несколько контейнеров — например, основное приложение и вспомогательный (helper) контейнер. Они:
- Создаются и удаляются вместе
- Общаются через `localhost`
- Разделяют одно сетевое пространство имён
- Могут иметь общие тома хранилища

**Пример:** веб-приложение + sidecar-контейнер для сбора логов.

### Docker vs Kubernetes: управление связанными контейнерами

**Вручную в Docker:**
```bash
docker run python-app
docker run python-app
docker run helper --link app1
docker run helper --link app2
# При падении app1 — вручную останавливай helper1
# Сеть — настраивай вручную
# Тома — монтируй вручную
```

**Автоматически в Kubernetes:**
```yaml
spec:
  containers:
    - name: app
      image: python-app
    - name: helper
      image: helper-image
# Kubernetes сам управляет сетью, томами и жизненным циклом
```

### Развёртывание пода через kubectl

```bash
# Создать под с nginx
kubectl run nginx --image=nginx

# Посмотреть статус подов
kubectl get pods
```

Вывод:
```
NAME                    READY   STATUS              RESTARTS   AGE
nginx-8586cf59-whssr    0/1     ContainerCreating   0          3s

NAME                    READY   STATUS    RESTARTS   AGE
nginx-8586cf59-whssr    1/1     Running   0          8s
```

**Важно:** под запущен, но nginx не доступен извне — нужна дополнительная настройка Service.

---

## Часть 5. Создание подов через YAML

### Структура YAML-файла Kubernetes

Каждый Kubernetes-объект описывается YAML-файлом с четырьмя обязательными полями верхнего уровня:

```yaml
apiVersion: v1          # версия API (v1, apps/v1 и т.д.)
kind: Pod               # тип объекта
metadata:               # метаданные
  name: myapp-pod
  labels:
    app: myapp
spec:                   # спецификация объекта
  containers:
    - name: nginx-container
      image: nginx
```

### Поле `apiVersion`

| Тип объекта | apiVersion |
|---|---|
| Pod | v1 |
| Service | v1 |
| ReplicaSet | apps/v1 |
| Deployment | apps/v1 |

### Поле `metadata`

Содержит имя объекта и метки (labels). Метки — это произвольные key-value пары для группировки и фильтрации ресурсов.

```yaml
metadata:
  name: myapp-pod
  labels:
    app: myapp
    costcenter: amer    # можно добавлять любые метки
    location: NA
```

**Критично:** отступы должны быть одинаковыми для полей одного уровня. Неправильный отступ = ошибка парсинга.

### Поле `spec`

Описывает содержимое объекта. Для пода — список контейнеров:

```yaml
spec:
  containers:
    - name: nginx-container   # дефис означает элемент массива
      image: nginx
    - name: redis-container   # второй контейнер (если нужен)
      image: redis
```

### Полный пример: под с одним контейнером

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
  labels:
    app: myapp
    type: front-end
spec:
  containers:
    - name: nginx-container
      image: nginx
```

### Полный пример: под с двумя контейнерами

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
  labels:
    app: myapp
spec:
  containers:
    - name: nginx-container
      image: nginx
    - name: backend-container
      image: redis
```

---

## Часть 6. Практика: развёртывание пода из YAML

### Шаг 1. Создать файл на мастер-ноде

```bash
mkdir -p /home/osboxes/demos/pod
cd /home/osboxes/demos/pod

cat > pod-definition.yml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
  labels:
    app: myapp
spec:
  containers:
    - name: nginx-container
      image: nginx
EOF
```

### Шаг 2. Проверить содержимое файла

```bash
cat pod-definition.yml
```

### Шаг 3. Удалить старые ресурсы (если есть)

```bash
kubectl get pods
kubectl delete deployment nginx   # если есть конфликтующий деплоймент
kubectl get pods                  # убедиться, что ничего нет
```

### Шаг 4. Создать под

```bash
kubectl create -f pod-definition.yml
# pod "myapp-pod" created
```

### Шаг 5. Наблюдать за запуском

```bash
kubectl get pods
# NAME        READY   STATUS              RESTARTS   AGE
# myapp-pod   0/1     ContainerCreating   0          8s

kubectl get pods
# NAME        READY   STATUS    RESTARTS   AGE
# myapp-pod   1/1     Running   0          19s
```

### Шаг 6. Детальная информация о поде

```bash
kubectl describe pod myapp-pod
```

Вывод покажет:
- На какой ноде запущен под
- Детали контейнера (образ, ID, порты, состояние)
- Переменные окружения
- Смонтированные тома
- **Events** — хронологию событий: scheduling → pulling image → создание контейнера → запуск

---

## Итоговые выводы

**Об архитектуре:**
- Kubernetes — система оркестрации контейнеров с чётким разделением на мастер-ноду (управление) и рабочие ноды (выполнение)
- Каждый компонент выполняет строго свою роль

**О контейнерных средах:**
- Docker deprecated в Kubernetes как runtime, но не как инструмент разработки
- Containerd — современный стандарт для production-кластеров
- `nerdctl` — лучший выбор для повседневной работы с containerd
- `crictl` — для отладки в Kubernetes-окружении

**О подах:**
- Под — атомарная единица Kubernetes, обёртка над контейнером
- Масштабирование = больше подов, не больше контейнеров в поде
- Мультиконтейнерные поды используются для вспомогательных сервисов (sidecar-паттерн)

**О YAML:**
- Четыре обязательных поля: `apiVersion`, `kind`, `metadata`, `spec`
- Отступы критичны — используй пробелы, не табы
- `kubectl create -f файл.yaml` — основная команда развёртывания
- `kubectl describe pod имя` — лучший инструмент диагностики

---

# 1.1 - Полное руководство по Kubernetes: Поды, ReplicaSets, Deployments и Namespaces

---

## Часть 1. Практика работы с подами: императивные команды и YAML

### Проверка начального состояния кластера

Прежде чем что-либо создавать, всегда проверяй текущее состояние кластера:

```bash
kubectl get pods
# No resources found in default namespace.
```

Это хорошая привычка — убедиться, что нет конфликтующих ресурсов, прежде чем начинать работу.

---

### Создание пода императивной командой

```bash
kubectl run nginx --image=nginx
# pod/nginx created
```

Сразу после создания под может находиться в статусе `ContainerCreating` — это нормально, Kubernetes скачивает образ и инициализирует контейнер:

```
NAME            READY   STATUS              RESTARTS   AGE
nginx           0/1     ContainerCreating   0          17s
newpods-llstt   0/1     ContainerCreating   0          11s
newpods-pnnx8   0/1     ContainerCreating   0          11s
newpods-k87fx   0/1     ContainerCreating   0          11s
```

Через несколько секунд поды переходят в статус `Running`.

---

### Инспектирование подов: два уровня детализации

**Базовый уровень — список подов:**
```bash
kubectl get pods
```

**Расширенный уровень — с информацией о нодах:**
```bash
kubectl get pods -o wide
```

Вывод команды `-o wide` добавляет столбцы IP-адреса и имени ноды:

```
NAME              READY   STATUS    RESTARTS   AGE     IP            NODE
newpods-pnnx8    1/1     Running   0          2m3s    10.42.0.10   controlplane
newpods-llstt    1/1     Running   0          2m3s    10.42.0.12   controlplane
nginx            1/1     Running   0          2m9s    10.42.0.9    controlplane
```

**Детальный уровень — полная информация о конкретном поде:**
```bash
kubectl describe pod <имя-пода>
```

Вывод `describe` содержит:
- На какой ноде запущен под и его IP
- Какие контейнеры внутри, их образы и ID
- Статус каждого контейнера
- Переменные окружения
- Смонтированные тома
- **Events** — хронологию событий (очень полезно при отладке)

---

### Мультиконтейнерные поды и диагностика ошибок

Рассмотрим под `webapp` с двумя контейнерами:

```bash
kubectl describe pod webapp
```

Вывод покажет оба контейнера:

```
Containers:
  nginx:
    Image: nginx
    State: Running
    Ready: True
    
  agentx:
    Image: agentx
    State: Waiting
    Reason: ErrImagePull
    Ready: False
```

Столбец `READY` в выводе `kubectl get pods` показывает `0/2` — это означает, что из двух контейнеров ни один не готов (агентx тянет за собой весь под):

```
NAME     READY   STATUS             RESTARTS   AGE
webapp   0/2     ImagePullBackOff   0          15s
```

**Диагноз:** образ `agentx` не существует в Docker Hub или написан с ошибкой.

**Два типа ошибок образов:**
- `ErrImagePull` — первая попытка скачать образ завершилась ошибкой
- `ImagePullBackOff` — Kubernetes уже несколько раз пробовал и теперь увеличивает интервалы между попытками (backoff)

**Удаление проблемного пода:**
```bash
kubectl delete pod webapp
# pod "webapp" deleted
```

---

### Declarative подход: dry-run и YAML

**Dry-run** — мощный инструмент, который позволяет сгенерировать YAML-манифест без реального создания объекта:

```bash
kubectl run redis --image=redis123 --dry-run=client -o yaml
```

Вывод:
```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: redis
  name: redis
spec:
  containers:
  - image: redis123
    name: redis
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

Перенаправляем в файл:
```bash
kubectl run redis --image=redis123 --dry-run=client -o yaml > redis.yaml
```

Создаём под с намеренно неверным образом `redis123`:
```bash
kubectl create -f redis.yaml
# pod/redis created

kubectl get pods
# redis   0/1     ErrImagePull   0   10s
```

Редактируем файл, исправляя `redis123` → `redis`:
```yaml
spec:
  containers:
  - image: redis    # исправлено
    name: redis
```

Применяем изменения:
```bash
kubectl apply -f redis.yaml
```

Проверяем:
```bash
kubectl get pods
# redis   1/1     Running   0   92s
```

**Разница между `kubectl create` и `kubectl apply`:**
- `create` — создаёт объект, ошибётся если объект уже существует
- `apply` — создаёт если нет, обновляет если есть (идемпотентная операция). Именно `apply` используют в CI/CD

---

## Часть 2. ReplicaSets — контроллеры репликации

### Зачем нужны ReplicaSets?

Представь: у тебя один под с приложением. Он падает — пользователи видят ошибку. ReplicaSet решает эту проблему, поддерживая указанное количество работающих подов в любой момент времени.

Два ключевых преимущества:
1. **Высокая доступность (High Availability)** — при падении пода автоматически создаётся новый
2. **Балансировка нагрузки** — несколько подов распределяют трафик

Даже при одном желаемом поде (replicas: 1) ReplicaSet полезен — он автоматически пересоздаст упавший под.

---

### Старый способ: ReplicationController

```yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: myapp-rc
  labels:
    app: myapp
    type: front-end
spec:
  replicas: 3
  template:
    metadata:
      name: myapp-pod
      labels:
        app: myapp
        type: front-end
    spec:
      containers:
        - name: nginx-container
          image: nginx
```

```bash
kubectl create -f rc-definition.yaml
kubectl get replicationcontroller
kubectl get pods
# Поды будут называться myapp-rc-xxxxx
```

ReplicationController — устаревшая технология. Используй ReplicaSet.

---

### Современный способ: ReplicaSet

Три ключевых отличия от ReplicationController:
1. `apiVersion: apps/v1` (не `v1`)
2. `kind: ReplicaSet`
3. Обязательное поле `selector`

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: myapp-replicaset
  labels:
    app: myapp
    type: front-end
spec:
  replicas: 3
  selector:
    matchLabels:
      type: front-end
  template:
    metadata:
      name: myapp-pod
      labels:
        app: myapp
        type: front-end
    spec:
      containers:
        - name: nginx-container
          image: nginx
```

```bash
kubectl create -f replicaset-definition.yaml
kubectl get replicaset
kubectl get pods
```

---

### Зачем нужен selector в ReplicaSet?

`selector` — это то, что делает ReplicaSet умнее ReplicationController. ReplicaSet может управлять подами, которые уже существовали до его создания, если их метки совпадают с селектором.

```yaml
# Селектор ReplicaSet
selector:
  matchLabels:
    tier: front-end

# Метки в шаблоне пода (должны совпадать!)
metadata:
  labels:
    tier: front-end
```

**Важное правило:** метки в `selector.matchLabels` должны точно совпадать с метками в `template.metadata.labels`. Несовпадение = ошибка при создании.

---

### Практика: типичные ошибки при создании ReplicaSets

**Ошибка 1 — неверная версия API:**

```yaml
apiVersion: v1       # НЕВЕРНО для ReplicaSet!
kind: ReplicaSet
```

```bash
kubectl create -f replicaset-definition-1.yaml
# error: unable to recognize: no matches for kind "ReplicaSet" in version "v1"
```

Как узнать правильную версию:
```bash
kubectl explain replicaset
# VERSION: apps/v1
```

Исправляем на `apiVersion: apps/v1` и создаём снова.

**Ошибка 2 — несовпадение меток:**

```yaml
spec:
  selector:
    matchLabels:
      tier: frontend   # ← selector

  template:
    metadata:
      labels:
        tier: nginx    # ← НЕ совпадает с selector!
```

```bash
# The ReplicaSet "replicaset-2" is invalid: spec.template.metadata.labels:
# Invalid value: map[string]string{"tier":"nginx"}: 
# selector does not match template labels
```

Исправляем `tier: nginx` → `tier: frontend` в шаблоне пода.

---

### Самовосстановление ReplicaSet

Одно из ключевых свойств ReplicaSet — он всегда поддерживает desired count:

```bash
kubectl get pods
# new-replica-set-wkzjh    0/1     ImagePullBackOff
# new-replica-set-vpkh8    0/1     ImagePullBackOff
# new-replica-set-hr2zqw   0/1     ImagePullBackOff
# new-replica-set-tn2mp    0/1     ImagePullBackOff

kubectl delete pod new-replica-set-wkzjh
# pod "new-replica-set-wkzjh" deleted

kubectl get pods
# ReplicaSet немедленно создал новый под вместо удалённого!
# Снова 4 пода.
```

Это и есть reconciliation loop — постоянное сравнение текущего состояния с желаемым.

---

### Обновление образа в ReplicaSet и важный нюанс

```bash
kubectl edit rs new-replica-set
```

Находим и меняем:
```yaml
containers:
  - name: busybox-container
    image: busybox    # было busybox777
```

**Критически важный нюанс:** обновление ReplicaSet НЕ перезапускает существующие поды! Изменение применяется только к новым подам, которые будут созданы после этого.

Чтобы применить новый образ к существующим подам, нужно вручную удалить их:

```bash
kubectl delete pod new-replica-set-vpkh8 new-replica-set-tn2mp new-replica-set-7r2qw
```

ReplicaSet автоматически создаст новые поды уже с правильным образом. Этот недостаток устранён в Deployments (rolling update).

---

### Масштабирование ReplicaSet

**Способ 1 — через файл:**
```bash
# Меняем replicas: 3 → replicas: 6 в файле
kubectl replace -f replicaset-definition.yaml
```

**Способ 2 — командой scale:**
```bash
kubectl scale --replicas=6 -f replicaset-definition.yaml
# или
kubectl scale --replicas=6 replicaset/myapp-replicaset
# или сокращённо
kubectl scale rs new-replica-set --replicas=5
```

**Масштабирование вниз через kubectl edit:**
```bash
kubectl edit rs new-replica-set
# Меняем replicas: 5 → replicas: 2
# Сохраняем — лишние поды будут немедленно удалены
```

Проверка:
```bash
kubectl get rs new-replica-set
# NAME              DESIRED   CURRENT   READY   AGE
# new-replica-set   2         2         2       15m
```

**Важное замечание:** при использовании `kubectl scale` с флагом `-f` изменения не записываются в файл — только в живой объект кластера. Файл останется со старым значением, что может привести к путанице.

---

### Таблица команд для ReplicaSets

| Команда | Что делает |
|---|---|
| `kubectl create -f <file>` | Создать объект из файла |
| `kubectl get replicaset` (или `rs`) | Список всех ReplicaSets |
| `kubectl describe rs <name>` | Детали ReplicaSet |
| `kubectl edit rs <name>` | Редактировать ReplicaSet вживую |
| `kubectl delete rs <name>` | Удалить ReplicaSet (и его поды) |
| `kubectl scale rs <name> --replicas=N` | Масштабировать |
| `kubectl replace -f <file>` | Обновить из файла |
| `kubectl explain replicaset` | Справка по полям и apiVersion |

---

## Часть 3. Deployments — оркестрация обновлений

### Почему ReplicaSet недостаточно?

ReplicaSet хорошо поддерживает количество подов, но не умеет:
- Обновлять поды по одному без простоя (rolling update)
- Откатываться на предыдущую версию при ошибке (rollback)
- Приостанавливать и группировать несколько изменений

**Deployment решает всё это.** Deployment → создаёт ReplicaSet → ReplicaSet управляет подами.

```
Deployment
    └── ReplicaSet
            ├── Pod
            ├── Pod
            └── Pod
```

---

### YAML-манифест Deployment

Манифест практически идентичен ReplicaSet — меняется только `kind`:

```yaml
apiVersion: apps/v1
kind: Deployment          # ← единственное отличие от ReplicaSet
metadata:
  name: myapp-deployment
  labels:
    app: myapp
    type: front-end
spec:
  replicas: 3
  selector:
    matchLabels:
      type: front-end
  template:
    metadata:
      name: myapp-pod
      labels:
        app: myapp
        type: front-end
    spec:
      containers:
      - name: nginx-container
        image: nginx
```

```bash
kubectl create -f deployment-definition.yml
# deployment "myapp-deployment" created
```

---

### Что создаётся при деплойменте

```bash
kubectl get deployments
# NAME               DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
# myapp-deployment   3         3         3            3           21s

kubectl get replicasets
# NAME                        DESIRED   CURRENT   READY   AGE
# myapp-deployment-6795844b58  3         3         3      21s

kubectl get pods
# myapp-deployment-6795844b58-5rbj1   1/1   Running   0   21s
# myapp-deployment-6795844b58-h4w55   1/1   Running   0   21s
# myapp-deployment-6795844b58-1fjhv   1/1   Running   0   21s
```

Имена объектов строятся по принципу: `deployment-name` → `deployment-name-<hash-rs>` → `deployment-name-<hash-rs>-<hash-pod>`

Посмотреть всё сразу:
```bash
kubectl get all
```

---

### Типичные ошибки при создании Deployment

**Ошибка — неверный регистр `kind`:**

```yaml
kind: deployment    # НЕВЕРНО
kind: Deployment    # ВЕРНО — с заглавной буквы
```

```bash
# Error: no kind "deployment" is registered for version "apps/v1"
```

Kubernetes чувствителен к регистру в поле `kind`.

---

### Создание Deployment командой (без YAML)

```bash
kubectl create deployment webapp --image=nginx --replicas=3
```

Создать и сразу экспортировать в YAML для последующей правки:
```bash
kubectl create deployment webapp --image=nginx --replicas=3 --dry-run=client -o yaml > webapp.yaml
```

---

### Deployment vs ReplicaSet: итоговое сравнение

| Возможность | ReplicaSet | Deployment |
|---|---|---|
| Поддержание N подов | ✅ | ✅ |
| Rolling update | ❌ | ✅ |
| Rollback | ❌ | ✅ |
| Пауза/возобновление | ❌ | ✅ |
| Управляет ReplicaSet | ❌ (сам ReplicaSet) | ✅ |
| Рекомендуется для prod | ❌ | ✅ |

В реальной практике ReplicaSet напрямую почти не используется — всегда создают Deployment.

---

## Часть 4. Namespaces — пространства имён

### Концепция и аналогия

Представь две семьи: в семье Смитов живёт Марк, в семье Уильямс тоже живёт Марк. Внутри своей семьи каждого называют просто «Марк». Но если нужно обратиться к Марку из другой семьи — говорят «Марк Уильямс».

Kubernetes namespace работает точно так же: это изолированное пространство, внутри которого ресурсы называются просто по имени, а для обращения к ресурсам другого namespace нужно полное имя.

---

### Встроенные namespaces Kubernetes

При установке кластера автоматически создаются три namespace:

**`default`** — где создаются все твои ресурсы, если не указать иное.

**`kube-system`** — системные компоненты Kubernetes: DNS, networking, metrics-server и т.д. Изолирован от пользователей, чтобы случайно не сломать кластер.

**`kube-public`** — ресурсы, доступные всем пользователям без аутентификации.

**`kube-node-lease`** — служебный namespace для heartbeat-сообщений нод.

---

### Зачем создавать свои namespaces?

В маленьких проектах можно работать в `default`. В enterprise-окружениях namespaces используются для:

- **Изоляции сред:** `dev`, `staging`, `prod` — в одном кластере, но разделены
- **Разграничения команд:** `team-frontend`, `team-backend`
- **Квот ресурсов:** каждый namespace получает свою долю CPU и памяти
- **Политик безопасности:** RBAC применяется на уровне namespace

```
Кластер
├── kube-system    (системные компоненты)
├── default        (твои ресурсы по умолчанию)
├── dev            (разработка)
├── staging        (тестирование)
└── prod           (продакшн)
```

---

### DNS-адресация между namespaces

**Внутри одного namespace** — обращаемся по имени сервиса:
```python
mysql.connect("db-service")
```

**Из другого namespace** — нужно полное имя (FQDN):
```python
mysql.connect("db-service.dev.svc.cluster.local")
```

Структура FQDN:
```
db-service  .  dev  .  svc  .  cluster.local
    │           │      │         │
  имя         namespace  тип    домен кластера
 сервиса                ресурса
```

Kubernetes автоматически создаёт DNS-записи такого формата для каждого сервиса.

---

### Практические команды с namespaces

**Посмотреть все namespaces:**
```bash
kubectl get namespaces
kubectl get ns    # сокращённо

# NAME              STATUS    AGE
# default           Active    6m50s
# kube-system       Active    6m49s
# kube-public       Active    6m49s
# kube-node-lease   Active    6m49s
# finance           Active    27s
# marketing         Active    27s
# dev               Active    27s
# prod              Active    27s
```

**Список подов в конкретном namespace:**
```bash
kubectl get pods --namespace=kube-system
kubectl get pods -n research    # сокращённо
```

**Создать под в конкретном namespace:**
```bash
kubectl run redis --image=redis -n finance
```

Или через YAML, добавив namespace в metadata:
```yaml
metadata:
  name: myapp-pod
  namespace: dev    # ← явно указываем namespace
```

```bash
kubectl create -f pod-definition.yml
# Под создастся в namespace dev, даже без флага --namespace
```

**Список подов во всех namespaces:**
```bash
kubectl get pods --all-namespaces
```

Пример вывода:
```
NAMESPACE    NAME                        READY   STATUS    AGE
kube-system  coredns-5788995cd-bkj56    1/1     Running   9m
marketing    redis-db                   1/1     Running   3m
marketing    blue                       0/1     CrashLoopBackOff  3m
dev          red-app                    1/1     Running   3m
finance      payroll                    1/1     Running   3m
research     dna-1                      1/1     Running   3m
research     dna-2                      0/1     CrashLoopBackOff  3m
```

Это незаменимо при поиске подов по всему кластеру.

---

### Создание namespace

**Через YAML:**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: dev
```
```bash
kubectl create -f namespace-definition.yml
```

**Через командную строку:**
```bash
kubectl create namespace dev
kubectl create namespace dev-ns
```

---

### Установка дефолтного namespace

Если постоянно работаешь с одним namespace, можно переключить контекст:

```bash
kubectl config set-context $(kubectl config current-context) --namespace=dev
```

После этого `kubectl get pods` будет показывать поды namespace `dev` без флага `-n`.

Чтобы вернуться к `default`:
```bash
kubectl config set-context $(kubectl config current-context) --namespace=default
```

---

### Resource Quotas — ограничения ресурсов для namespace

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: dev
spec:
  hard:
    pods: "10"               # не более 10 подов
    requests.cpu: "4"        # суммарный запрос CPU
    requests.memory: 5Gi     # суммарный запрос памяти
    limits.cpu: "10"         # максимальный лимит CPU
    limits.memory: 10Gi      # максимальный лимит памяти
```

```bash
kubectl create -f compute-quota.yaml
```

Это гарантирует, что ни один namespace не «съест» все ресурсы кластера.

---

### Практика: поиск пода в нужном namespace

Типичная задача — найти под `blue` в кластере:

```bash
kubectl get pods --all-namespaces | grep blue
# marketing    blue    0/1   CrashLoopBackOff   3m
```

Под находится в namespace `marketing`.

**Доступ к сервису внутри своего namespace:**
```bash
kubectl get svc -n marketing
# NAME          TYPE       CLUSTER-IP      PORT(S)
# blue-service  NodePort   10.43.82.162    8080:30082/TCP
# db-service    NodePort   10.43.134.33    6379:30758/TCP
```

Из пода `blue` обращаемся к `db-service` просто по имени: `db-service`.

**Доступ к сервису в другом namespace (dev):**
```bash
kubectl get svc -n dev
# NAME         TYPE        CLUSTER-IP      PORT(S)
# db-service   ClusterIP   10.43.252.9     6379/TCP
```

Из namespace `marketing` обращаемся: `db-service.dev.svc.cluster.local`

---

## Часть 5. Императивные команды — быстрый старт без YAML

### Зачем нужны императивные команды?

На экзамене CKA/CKAD время ограничено. Писать YAML вручную долго. Императивные команды позволяют создавать объекты мгновенно.

### Полный набор команд

**Создание пода:**
```bash
kubectl run nginx-pod --image=nginx:alpine
# pod/nginx-pod created
```

**Под с меткой:**
```bash
kubectl run redis --image=redis:alpine --labels=tier=db
```

**Под с открытым портом:**
```bash
kubectl run custom-nginx --image=nginx --port=8080
```

**Под + сервис одной командой:**
```bash
kubectl run httpd --image=httpd:alpine --port=80 --expose
# Создаёт и под, и ClusterIP сервис на порту 80
```

**Создать сервис для существующего пода:**
```bash
kubectl expose pod redis --port=6379 --name=redis-service
# Автоматически подхватывает метки пода как selector!
```

**Создание Deployment:**
```bash
kubectl create deployment webapp --image=nginx --replicas=3
```

**Создание namespace:**
```bash
kubectl create namespace dev-ns
```

**Deployment в конкретном namespace:**
```bash
kubectl create deployment redis-deploy --image=redis --replicas=2 -n dev-ns

kubectl get deployment -n dev-ns
# NAME           READY   UP-TO-DATE   AVAILABLE   AGE
# redis-deploy   2/2     2            2           12s
```

---

### Связка dry-run + yaml — главный трюк на экзамене

Генерируем YAML без создания объекта:

```bash
kubectl run nginx --image=nginx --dry-run=client -o yaml > pod.yaml
kubectl create deployment webapp --image=nginx --dry-run=client -o yaml > deploy.yaml
```

Затем редактируем файл и применяем — это намного быстрее, чем писать YAML с нуля.

---

### Проверка всего созданного

```bash
kubectl get pod
# NAME                       READY   STATUS    RESTARTS   AGE
# nginx-pod                  1/1     Running   0          12m
# redis                      1/1     Running   0          10m
# webapp-7b59bf687d-n7xxp    1/1     Running   0          5m
# webapp-7b59bf687d-rds95    1/1     Running   0          5m
# webapp-7b59bf687d-4gqmt    1/1     Running   0          5m
# custom-nginx               1/1     Running   0          3m
# httpd                      1/1     Running   0          8s

kubectl get svc
# NAME            TYPE        CLUSTER-IP      PORT(S)     AGE
# kubernetes      ClusterIP   10.43.0.1       443/TCP     20m
# redis-service   ClusterIP   10.43.56.187    6379/TCP    6m
# httpd           ClusterIP   10.43.112.233   80/TCP      15s

kubectl describe svc httpd
# Selector: run=httpd    ← автоматически взят из метки пода
# Endpoints: 10.0.2.17:80
```

---

## Итоговые выводы

### Об управлении подами

Всегда начинай с `kubectl get pods` для проверки состояния. `kubectl describe pod <name>` — твой главный инструмент диагностики: секция Events покажет, что пошло не так. `ErrImagePull` и `ImagePullBackOff` — почти всегда опечатка в имени образа или его отсутствие в реестре.

### О ReplicaSets

ReplicaSet — контроллер, который обеспечивает, что всегда запущено нужное число подов. Selector и Labels должны совпадать. Обновление ReplicaSet не перезапускает существующие поды — нужно удалять их вручную. Для production используй Deployment.

### О Deployments

Deployment = ReplicaSet + rolling updates + rollback. Это стандартный способ деплоя в Kubernetes. Структура имён: `deployment → replicaset → pod` отражается в именах объектов.

### О Namespaces

Namespace — логическая изоляция внутри кластера. Внутри namespace — обращайся по имени сервиса. Между namespaces — используй FQDN формата `service.namespace.svc.cluster.local`. Resource Quotas ограничивают потребление ресурсов на уровне namespace.

### О рабочем процессе

Лучший подход: `dry-run -o yaml` для генерации шаблона → правка файла → `kubectl apply`. Это даёт воспроизводимость и документацию. Императивные команды хороши для быстрых задач и экзаменов, декларативный YAML — для production и CI/CD.

---

# 2.1 - Полное руководство по Docker и Kubernetes: образы, команды, переменные окружения, ConfigMaps и Secrets

Это подробное руководство охватывает все темы из предоставленных материалов. Разберём каждую из них максимально детально.

---

## Часть 1. Docker-образы: создание и модификация

### Что такое Docker-образ?

Docker-образ — это шаблон, на основе которого запускаются контейнеры. Образ состоит из набора слоёв, каждый из которых представляет собой результат выполнения одной инструкции в Dockerfile. Образы можно создавать самостоятельно, если нужное приложение недоступно на Docker Hub, или если вы хотите полностью контролировать процесс сборки.

### Зачем контейнеризировать приложения?

Прежде чем писать Dockerfile, полезно понять, как приложение запускалось бы вручную. Рассмотрим пример с Python Flask-приложением. Вручную вы бы делали следующее:

1. Взяли базовую операционную систему, например Ubuntu
2. Обновили репозитории пакетов через APT
3. Установили системные зависимости и Python
4. Установили необходимые Python-пакеты через pip
5. Скопировали исходный код приложения в нужную директорию, например `/opt`
6. Запустили Flask-сервер

Dockerfile автоматизирует именно эти шаги.

### Структура Dockerfile

```dockerfile
FROM ubuntu

RUN apt-get update && apt-get -y install python python-setuptools python-dev
RUN pip install flask flask-mysql

COPY . /opt/source-code

ENTRYPOINT FLASK_APP=/opt/source-code/app.py flask run --host=0.0.0.0
```

Разберём каждую инструкцию подробно:

**`FROM ubuntu`**
Указывает базовый образ. Каждый Docker-образ начинается с базового слоя — это либо образ операционной системы, либо уже готовый образ с Docker Hub. Здесь мы берём чистый Ubuntu.

**`RUN apt-get update && apt-get -y install python python-setuptools python-dev`**
Выполняет команды во время сборки образа. Эта инструкция обновляет список пакетов и устанавливает Python со вспомогательными инструментами. Флаг `-y` отвечает автоматически "да" на все вопросы установщика.

**`RUN pip install flask flask-mysql`**
Вторая команда RUN устанавливает Python-зависимости: фреймворк Flask и модуль для работы с MySQL.

**`COPY . /opt/source-code`**
Копирует исходный код из текущей директории на вашем компьютере в директорию `/opt/source-code` внутри образа.

**`ENTRYPOINT FLASK_APP=/opt/source-code/app.py flask run --host=0.0.0.0`**
Задаёт команду, которая выполняется при запуске контейнера. Здесь мы устанавливаем переменную окружения `FLASK_APP` и запускаем Flask-сервер, доступный на всех сетевых интерфейсах (`0.0.0.0`).

### Послойная архитектура Docker

Docker обрабатывает инструкции последовательно, создавая слои. Это очень важная концепция: если вы изменяете одну инструкцию в Dockerfile, Docker повторно выполняет только её и все последующие инструкции. Все предыдущие слои берутся из кэша, что значительно ускоряет пересборку образа.

Например, если вы изменили только исходный код приложения (инструкция `COPY`), Docker не будет заново устанавливать Ubuntu, Python и pip-пакеты — он возьмёт эти слои из кэша и пересоберёт только начиная с `COPY`.

Если сборка прервётся на каком-то шаге, Docker сохранит успешно созданные слои в кэше. При повторном запуске сборки после исправления ошибки он начнёт с упавшего шага, а не с начала.

### Просмотр слоёв образа

Чтобы посмотреть все слои образа и их размеры, используйте:

```bash
docker history <имя-образа>
```

Эта команда покажет список инструкций, которые создали каждый слой, а также размер каждого слоя.

### Сборка Docker-образа

После того как Dockerfile готов, собираем образ:

```bash
docker build -f Dockerfile -t mmumshad/my-custom-app .
```

- `-f Dockerfile` — указывает файл Dockerfile (можно опустить, если файл называется именно `Dockerfile`)
- `-t mmumshad/my-custom-app` — задаёт имя (тег) образа
- `.` — указывает контекст сборки (текущая директория)

Вывод команды будет выглядеть примерно так:

```
Step 1/5 : FROM ubuntu
 ---> ccc7a11d65b1
Step 2/5 : RUN apt-get update && apt-get install -y python ...
 ---> Running in a7840bfad17
...
Successfully built 9f27c36920bc
```

Каждый шаг выводится с идентификатором созданного слоя.

### Что можно контейнеризировать?

Docker не ограничен веб-приложениями. Контейнеризировать можно практически всё: базы данных, инструменты разработки, браузеры, утилиты вроде `curl`, музыкальные плееры и многое другое. Контейнеризация меняет подход к установке программного обеспечения: вместо того чтобы устанавливать приложение напрямую в операционную систему, вы запускаете его в изолированном контейнере. При удалении контейнера не остаётся никаких следов на хост-системе.

---

## Часть 2. Команды и аргументы в Docker

### Почему контейнер сразу завершается?

Когда вы запускаете контейнер на основе Ubuntu, он немедленно останавливается:

```bash
docker run ubuntu
docker ps       # контейнер не отображается
docker ps -a    # контейнер в статусе "Exited"
```

Почему? Потому что контейнеры принципиально отличаются от виртуальных машин. Контейнер существует ровно столько, сколько работает его основной процесс. Ubuntu по умолчанию запускает `bash`, но bash — интерактивная оболочка, которая ждёт ввода от пользователя. Если Docker не подключает терминал, bash не получает ввода и немедленно завершается. Вместе с ним завершается и контейнер.

### Инструкция CMD

Поведение контейнера при запуске определяется инструкцией `CMD` в Dockerfile. Например:

- образ nginx содержит `CMD ["nginx"]` — запускает nginx-процесс
- образ MySQL содержит `CMD ["mysqld"]` — запускает MySQL-сервер
- образ Ubuntu содержит `CMD ["bash"]` — запускает bash

```dockerfile
# Фрагмент Dockerfile Ubuntu
FROM ubuntu:14.04
# ... установка пакетов ...
CMD ["bash"]
```

### Переопределение CMD при запуске контейнера

Вы можете заменить команду по умолчанию, добавив свою команду к `docker run`:

```bash
docker run ubuntu sleep 5
```

Контейнер запустится, выполнит `sleep 5` (поспит 5 секунд) и завершится. Этот подход временный — он работает только для данного запуска.

### Постоянное изменение CMD: создание нового образа

Чтобы изменение было постоянным, создайте новый образ на основе Ubuntu:

```dockerfile
FROM ubuntu
CMD ["sleep", "5"]
```

Обратите внимание: команда записывается в формате JSON-массива `["sleep", "5"]`, а не как строка `sleep 5`. Docker рекомендует именно JSON-формат.

Теперь соберём и запустим:

```bash
docker build -t ubuntu-sleeper .
docker run ubuntu-sleeper       # всегда спит 5 секунд
docker run ubuntu-sleeper sleep 10  # переопределяем: спит 10 секунд
```

Но есть проблема: при переопределении вы вынуждены каждый раз писать `sleep 10`, `sleep 20` и так далее. Было бы удобнее передавать только число.

### Инструкция ENTRYPOINT

`ENTRYPOINT` задаёт исполняемый файл, который всегда запускается при старте контейнера. Все аргументы, переданные в `docker run`, добавляются к `ENTRYPOINT`, а не заменяют его.

```dockerfile
FROM ubuntu
ENTRYPOINT ["sleep"]
```

Теперь:

```bash
docker run ubuntu-sleeper 10    # выполняется: sleep 10
docker run ubuntu-sleeper 20    # выполняется: sleep 20
```

Но что если вы запустите контейнер без аргументов?

```bash
docker run ubuntu-sleeper       # ошибка: sleep требует аргумент
```

Контейнер упадёт с ошибкой, потому что `sleep` не получил числа. Здесь на помощь приходит сочетание `ENTRYPOINT` и `CMD`.

### Комбинация ENTRYPOINT и CMD

```dockerfile
FROM ubuntu
ENTRYPOINT ["sleep"]
CMD ["5"]
```

Теперь поведение следующее:

```bash
docker run ubuntu-sleeper       # выполняется: sleep 5  (CMD используется как аргумент по умолчанию)
docker run ubuntu-sleeper 10    # выполняется: sleep 10 (аргумент из командной строки заменяет CMD)
docker run ubuntu-sleeper 20    # выполняется: sleep 20
```

`CMD` здесь играет роль значения по умолчанию для аргументов `ENTRYPOINT`. Если передать аргумент при запуске, он заменяет `CMD`.

### Ключевые различия между CMD и ENTRYPOINT

| Характеристика | CMD | ENTRYPOINT |
|---|---|---|
| Назначение | Команда по умолчанию или аргументы по умолчанию | Фиксированный исполняемый файл |
| Поведение при передаче аргументов в `docker run` | Полностью заменяется | Аргументы добавляются к нему |
| Переопределение | Напрямую через командную строку | Только через флаг `--entrypoint` |

### Переопределение ENTRYPOINT

Чтобы полностью заменить `ENTRYPOINT`, используйте флаг `--entrypoint`:

```bash
docker run --entrypoint sleep2.0 ubuntu-sleeper 10
# выполняется: sleep2.0 10
```

---

## Часть 3. Команды и аргументы в Kubernetes

### Связь с Docker-концепциями

Kubernetes позволяет переопределять Docker-инструкции `ENTRYPOINT` и `CMD` прямо в манифесте Pod'а. Сопоставление выглядит так:

| Kubernetes | Docker | Назначение |
|---|---|---|
| `command` | `ENTRYPOINT` | Заменяет исполняемый файл контейнера |
| `args` | `CMD` | Заменяет аргументы по умолчанию |

### Переопределение аргументов (CMD) в Kubernetes

Предположим, у нас есть образ `ubuntu-sleeper` с Dockerfile:

```dockerfile
FROM ubuntu
ENTRYPOINT ["sleep"]
CMD ["5"]
```

По умолчанию запуск в Docker: `sleep 5`

Чтобы заставить Pod спать 10 секунд вместо 5:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ubuntu-sleeper-pod
spec:
  containers:
    - name: ubuntu-sleeper
      image: ubuntu-sleeper
      args: ["10"]
```

Поле `args` заменяет `CMD` из Dockerfile. Итоговая команда: `sleep 10`.

Создаём Pod:

```bash
kubectl create -f pod-definition.yml
```

### Переопределение ENTRYPOINT в Kubernetes

Чтобы полностью заменить `ENTRYPOINT`, используем поле `command`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ubuntu-sleeper-pod
spec:
  containers:
    - name: ubuntu-sleeper
      image: ubuntu-sleeper
      command: ["sleep2.0"]
      args: ["10"]
```

Итоговая команда: `sleep2.0 10`

Это эквивалентно Docker-команде:
```bash
docker run --entrypoint sleep2.0 ubuntu-sleeper 10
```

### Практические задачи и решения

**Задача 1: Создание Pod'а, который спит 5000 секунд**

Есть два способа записи:

**Способ 1 — всё в одном массиве `command`:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ubuntu-sleeper-2
spec:
  containers:
    - name: ubuntu
      image: ubuntu
      command: ["sleep", "5000"]
```

**Способ 2 — раздельно:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ubuntu-sleeper-2
spec:
  containers:
    - name: ubuntu
      image: ubuntu
      command: ["sleep"]
      args: ["5000"]
```

Оба варианта корректны. Важно: каждый элемент массива должен быть строкой. Число `5000` без кавычек вызовет ошибку:

```
cannot unmarshal number into the Go struct field Container.command of type string
```

Поэтому всегда пишите `"5000"` в кавычках.

**Задача 2: Обновление запущенного Pod'а**

Прямое редактирование большинства полей запущенного Pod'а невозможно. Правильный подход:

```bash
# Редактируем Pod (изменения сохраняются во временный файл)
kubectl edit pod ubuntu-sleeper-3

# Принудительно заменяем Pod новой конфигурацией
kubectl replace --force -f /tmp/kubectl-edit-2693604347.yaml
```

Эта команда удаляет существующий Pod и создаёт новый с обновлёнными настройками.

**Задача 3: Передача аргументов через `kubectl run`**

Для разделения аргументов самого `kubectl` и аргументов контейнера используется двойной дефис `--`:

```bash
kubectl run webapp-green --image=kodekloud/webapp-color -- --color=green
```

Всё, что идёт после `--`, передаётся как аргументы в контейнер.

### Важный пример: когда `command` не делает то, что ожидается

Рассмотрим Dockerfile:

```dockerfile
FROM python:3.6-alpine
RUN pip install flask
COPY . /opt/
EXPOSE 8080
WORKDIR /opt
ENTRYPOINT ["python", "app.py"]
CMD ["--color", "red"]
```

По умолчанию контейнер выполняет: `python app.py --color red`

Теперь посмотрим на следующий манифест Pod'а:

```yaml
spec:
  containers:
    - name: simple-webapp
      image: kodekloud/webapp-color
      command: ["--color", "green"]
```

**Что пойдёт не так?** Поле `command` заменяет `ENTRYPOINT`. То есть контейнер попытается выполнить `--color green` как исполняемый файл, что вызовет ошибку. Нужно писать:

```yaml
spec:
  containers:
    - name: simple-webapp
      image: kodekloud/webapp-color
      command: ["python", "app.py"]
      args: ["--color", "green"]
```

Теперь выполняется: `python app.py --color green` — корректно.

---

## Часть 4. Переменные окружения в Kubernetes

### Прямое определение переменных окружения

В Docker вы передаёте переменные окружения через флаг `-e`:

```bash
docker run -e APP_COLOR=pink simple-webapp-color
```

В Kubernetes аналог — поле `env` в спецификации контейнера:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: simple-webapp-color
spec:
  containers:
  - name: simple-webapp-color
    image: simple-webapp-color
    ports:
    - containerPort: 8080
    env:
    - name: APP_COLOR
      value: pink
```

`env` — это массив, где каждый элемент имеет поля `name` и `value`. Это самый простой способ, подходящий для разработки и простых сценариев.

**Проблема прямого определения:** если у вас много Pod'ов с одинаковыми переменными, изменение значения требует редактирования каждого Pod'а отдельно. Это неудобно и чревато ошибками.

### Управление переменными через ConfigMaps и Secrets

Вместо жёсткого кодирования значений можно ссылаться на внешние источники:

```yaml
# Ссылка на ConfigMap
env:
- name: APP_COLOR
  valueFrom:
    configMapKeyRef:
      name: my-config
      key: app_color

# Ссылка на Secret
env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: app-secret
      key: DB_Password
```

### Сравнение трёх методов

| Метод | Описание | Когда применять |
|---|---|---|
| Прямое присваивание (`value`) | Значение захардкожено прямо в манифесте Pod'а | Разработка, простые сценарии |
| Ссылка на ConfigMap (`configMapKeyRef`) | Значение берётся из ConfigMap | Конфигурация, не содержащая секретов |
| Ссылка на Secret (`secretKeyRef`) | Значение берётся из Secret | Пароли, токены, ключи |

---

## Часть 5. ConfigMaps: централизованное управление конфигурацией

### Проблема, которую решают ConfigMaps

Представьте, что у вас 50 Pod'ов, каждый из которых использует переменную `APP_COLOR=blue`. Если нужно изменить цвет, вам придётся редактировать все 50 манифестов. ConfigMap решает эту проблему: вы храните данные конфигурации в одном месте, а Pod'ы ссылаются на него.

### Шаг 1: Создание ConfigMap

**Императивный подход (через командную строку):**

```bash
# Из пар ключ=значение
kubectl create configmap app-config \
  --from-literal=APP_COLOR=blue \
  --from-literal=APP_MODE=prod

# Из файла
kubectl create configmap app-config --from-file=app_config.properties
```

**Декларативный подход (через YAML-файл):**

```yaml
# config-map.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_COLOR: blue
  APP_MODE: prod
```

```bash
kubectl create -f config-map.yaml
```

### Просмотр ConfigMaps

```bash
# Список всех ConfigMap'ов
kubectl get configmaps

# Подробная информация
kubectl describe configmaps app-config
```

Вывод `describe`:

```
Name:         app-config
Namespace:    default
Data
====
APP_COLOR:
----
blue
APP_MODE:
----
prod
```

### Шаг 2: Внедрение ConfigMap в Pod

**Метод 1: envFrom — инъекция всех переменных из ConfigMap**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: simple-webapp-color
spec:
  containers:
    - name: simple-webapp-color
      image: simple-webapp-color
      ports:
        - containerPort: 8080
      envFrom:
        - configMapRef:
            name: app-config
```

Все ключи из `app-config` становятся переменными окружения контейнера.

**Метод 2: env с valueFrom — отдельные переменные**

```yaml
env:
  - name: APP_COLOR
    valueFrom:
      configMapKeyRef:
        name: app-config
        key: APP_COLOR
```

Позволяет брать конкретные ключи из ConfigMap и давать переменным другие имена.

**Метод 3: Монтирование как файлы (Volume)**

```yaml
volumes:
  - name: app-config-volume
    configMap:
      name: app-config
```

При таком подходе каждый ключ ConfigMap становится отдельным файлом. Имя файла — ключ, содержимое — значение.

### Практический пример: смена цвета фона

Предположим, веб-приложение отображает цветной фон, цвет которого определяется переменной `APP_COLOR`.

**Шаг 1:** Создаём ConfigMap:
```bash
kubectl create cm webapp-config-map --from-literal=APP_COLOR=darkblue
```

**Шаг 2:** Экспортируем текущий Pod:
```bash
kubectl get pod webapp-color -o yaml > pod.yaml
```

**Шаг 3:** Удаляем текущий Pod:
```bash
kubectl delete pod webapp-color
```

**Шаг 4:** Редактируем `pod.yaml`, заменяя жёсткое значение на ссылку:

```yaml
env:
- name: APP_COLOR
  valueFrom:
    configMapKeyRef:
      name: webapp-config-map
      key: APP_COLOR
```

**Шаг 5:** Применяем:
```bash
kubectl apply -f pod.yaml
```

Теперь фон стал тёмно-синим.

---

## Часть 6. Secrets: безопасное хранение конфиденциальных данных

### Почему ConfigMap не подходит для паролей?

ConfigMaps хранят данные в открытом виде. Если злоумышленник получит доступ к кластеру или репозиторию с манифестами, он увидит пароли. Secrets хранят данные в кодированном формате (base64), что является дополнительным уровнем защиты (хотя и не шифрованием).

### Различие между кодированием и шифрованием

Это важный момент: base64 — это кодирование, а не шифрование. Любой может декодировать base64-значение:

```bash
echo -n 'bXlzcWw=' | base64 --decode
# Вывод: mysql
```

Поэтому Secrets требуют дополнительных мер безопасности (RBAC, шифрование etcd).

### Кодирование значений

Прежде чем создавать Secret декларативным методом, нужно закодировать значения:

```bash
echo -n 'mysql' | base64
# Вывод: bXlzcWw=

echo -n 'root' | base64
# Вывод: cm9vdA==

echo -n 'paswrd' | base64
# Вывод: cGFzd3Jk
```

Флаг `-n` в `echo` убирает символ новой строки в конце, что важно для корректного кодирования.

### Создание Secrets

**Императивный метод:**

```bash
kubectl create secret generic app-secret \
  --from-literal=DB_Host=mysql \
  --from-literal=DB_User=root \
  --from-literal=DB_Password=paswrd
```

При императивном создании Kubernetes сам кодирует значения в base64.

**Из файла:**

```bash
kubectl create secret generic app-secret --from-file=app_secret.properties
```

**Декларативный метод (значения уже должны быть в base64):**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
data:
  DB_Host: bXlzcWw=
  DB_User: cm9vdA==
  DB_Password: cGFzd3Jk
```

```bash
kubectl create -f secret-data.yaml
```

### Просмотр Secrets

```bash
# Список
kubectl get secrets

# Описание (значения скрыты)
kubectl describe secrets

# Просмотр закодированных значений
kubectl get secret app-secret -o yaml
```

`describe` намеренно скрывает значения, показывая только размеры. Чтобы увидеть значения, нужна флаг `-o yaml`.

### Декодирование значений

```bash
echo -n 'bXlzcWw=' | base64 --decode
# Вывод: mysql

echo -n 'cm9vdA==' | base64 --decode
# Вывод: root
```

### Инъекция Secrets в Pod

**Метод 1: envFrom — все ключи как переменные окружения**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: simple-webapp-color
spec:
  containers:
    - name: simple-webapp-color
      image: simple-webapp-color
      ports:
        - containerPort: 8080
      envFrom:
        - secretRef:
            name: app-secret
```

**Метод 2: Монтирование как Volume**

```yaml
volumes:
  - name: app-secret-volume
    secret:
      secretName: app-secret
```

При монтировании как Volume каждый ключ Secret становится файлом:

```bash
ls /opt/app-secret-volumes
# Вывод: DB_Host  DB_Password  DB_User

cat /opt/app-secret-volumes/DB_Password
# Вывод: paswrd  (значение уже декодировано!)
```

Обратите внимание: при монтировании как Volume Kubernetes автоматически декодирует значения из base64. Приложение читает файл и получает уже открытое значение.

### Шифрование Secrets в etcd

По умолчанию Secrets хранятся в etcd в незашифрованном виде (только base64). Для реальной защиты необходимо включить шифрование:

```yaml
# EncryptionConfiguration
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
    providers:
      - aesgcm:
          keys:
            - name: key1
              secret: C2VjcmVjT0glZzIHNLY3VyZQ==
      - identity: {}
```

Этот файл передаётся kube-apiserver через параметр `--encryption-provider-config`.

Манифест kube-apiserver при этом дополняется:

```yaml
spec:
  containers:
    - command:
        - kube-apiserver
        - --encryption-provider-config=/etc/kubernetes/enc/enc.yaml
  volumeMounts:
    - name: enc
      mountPath: /etc/kubernetes/enc
      readOnly: true
  volumes:
    - name: enc
      hostPath:
        path: /etc/kubernetes/enc
        type: DirectoryOrCreate
```

### Важные предостережения при работе с Secrets

1. **Base64 — не шифрование.** Любой, у кого есть доступ к объекту Secret, может декодировать данные.

2. **Не храните файлы Secret в системах контроля версий (Git).** Если файл попадёт в публичный репозиторий, секреты будут скомпрометированы.

3. **По умолчанию etcd не шифруется.** Включайте шифрование в production-окружениях.

4. **Используйте RBAC** для ограничения доступа к Secrets. Только те Pod'ы и пользователи, которым это необходимо, должны иметь доступ.

5. **Рассмотрите внешние хранилища секретов:** AWS Secrets Manager, Azure Key Vault, Google Secret Manager, HashiCorp Vault. Они обеспечивают более высокий уровень безопасности, храня секреты вне etcd.

---

## Общие выводы и рекомендации

### Архитектурный подход к конфигурации

```
Конфигурационные данные
        │
        ├── Не чувствительные (цвета, режимы, URL)
        │         └──► ConfigMap
        │
        └── Чувствительные (пароли, токены, ключи)
                  └──► Secret
```

### Цепочка от Docker к Kubernetes

```
Dockerfile             Kubernetes Pod
──────────             ──────────────
FROM           →       image:
RUN            →       (выполняется при сборке образа)
COPY           →       (происходит при сборке образа)
ENTRYPOINT     →       command:
CMD            →       args:
ENV            →       env: / envFrom:
```

### Практические рекомендации

1. **Разделяйте конфигурацию и код.** Не хардкодьте значения в образах. Используйте ConfigMaps и Secrets.

2. **Используйте описательные имена** для ConfigMaps и Secrets. Вместо `config` пишите `webapp-config`, `db-config`.

3. **Помните о порядке инструкций в Dockerfile.** Редко меняющиеся инструкции (установка зависимостей) ставьте раньше, часто меняющиеся (копирование кода) — позже. Это максимизирует использование кэша.

4. **Всегда проверяйте синтаксис YAML.** Числа в массивах `command` и `args` должны быть в кавычках.

5. **Для обновления Pod'ов** используйте `kubectl replace --force`, так как большинство полей Pod'а нельзя изменить на лету.

6. **В production всегда шифруйте etcd** и используйте RBAC для контроля доступа к Secrets.

---

Это руководство охватывает все аспекты работы с Docker-образами и Kubernetes-конфигурацией: от создания простого Dockerfile до безопасного управления секретами в production-окружении. Каждая концепция опирается на предыдущую, выстраивая полную картину контейнеризированных развёртываний.

---

# 2.2 - Полное руководство: Secrets, шифрование etcd, безопасность Docker и Kubernetes, ресурсы и сервисные аккаунты

---

## Часть 1. Практическая работа с Kubernetes Secrets

### Инспекция стандартных секретов кластера

Первое, с чего начинается работа с любым новым кластером — проверка уже существующих секретов:

```bash
kubectl get secrets
```

В типичном кластере вы увидите нечто подобное:

```
NAME                      TYPE                                  DATA   AGE
default-token-cr4sr       kubernetes.io/service-account-token    3     7m50s
```

Этот секрет создаётся Kubernetes автоматически для каждого namespace. Он содержит три элемента:

```bash
kubectl describe secret default-token-cr4sr
```

В секции `Data` будут показаны:
- `ca.crt` — сертификат центра сертификации кластера (570 байт)
- `namespace` — имя namespace в закодированном виде (7 байт)
- `token` — JWT-токен для аутентификации в API Kubernetes

Важно понимать: поле `type` (`kubernetes.io/service-account-token`) — это тип объекта Secret, а не сами секретные данные. Секретными данными являются именно ключи в секции `Data`.

### Практический сценарий: веб-приложение с MySQL

Рассмотрим реальный пример из практики. В кластере развёрнуто два Pod'а: веб-приложение и MySQL-сервер.

```bash
kubectl get pods
```
```
NAME         READY   STATUS    RESTARTS   AGE
webapp-pod   1/1     Running   0          26s
mysql        1/1     Running   0          26s
```

```bash
kubectl get svc
```
```
NAME             TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)           AGE
kubernetes       ClusterIP  10.43.0.1       <none>        443/TCP           10m
webapp-service   NodePort   10.43.73.93     <none>        8080:30000/TCP    40s
sql01            ClusterIP  10.43.128.20    <none>        3306/TCP          40s
```

Приложение пытается подключиться к MySQL, но получает ошибку:
- Database host is not set
- DB user is not set
- DB password is not set

Это происходит потому, что переменные окружения для подключения к БД нигде не определены. Решение — создать Secret с нужными данными.

### Создание Secret для базы данных

```bash
kubectl create secret generic db-secret \
  --from-literal=DB_Host=sql01 \
  --from-literal=DB_User=root \
  --from-literal=DB_Password=password123
```

Проверяем создание:

```bash
kubectl get secret
```
```
NAME                 TYPE                                  DATA   AGE
default-token-cr4sr  kubernetes.io/service-account-token    3     10m
db-secret            Opaque                                 3     6s
```

Тип `Opaque` означает произвольный пользовательский секрет (в отличие от специализированных типов вроде `service-account-token` или `docker-registry`).

### Подключение Secret к Pod'у

Обновляем манифест Pod'а, добавив `envFrom`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: webapp-pod
  namespace: default
  labels:
    name: webapp-pod
spec:
  containers:
    - name: webapp
      image: kodekloud/simple-webapp-mysql
      imagePullPolicy: Always
      envFrom:
        - secretRef:
            name: db-secret
```

Применяем с принудительной заменой (удалением старого Pod'а):

```bash
kubectl replace --force -f webapp-pod.yaml
```

После этого приложение успешно подключается к MySQL, получая все три переменные окружения (`DB_Host`, `DB_User`, `DB_Password`) из Secret'а.

---

## Часть 2. Шифрование Secrets в etcd

### Почему это важно

Kubernetes Secrets хранятся в etcd — распределённом хранилище ключ-значение, которое является "сердцем" кластера. По умолчанию данные в etcd хранятся в base64-кодированном, но **не зашифрованном** виде. Это означает, что любой, у кого есть доступ к etcd (физический или сетевой), может прочитать все секреты.

### Создание Secret для демонстрации

```bash
kubectl create secret generic my-secret --from-literal=key1=supersecret
```

```bash
kubectl get secret my-secret -o yaml
```

Вывод:
```yaml
apiVersion: v1
data:
  key1: c3VwZXJzZWNyZXQ=
kind: Secret
metadata:
  name: my-secret
  namespace: default
type: Opaque
```

Декодируем:
```bash
echo "c3VwZXJzZWNyZXQ=" | base64 --decode
# Вывод: supersecret
```

### Проверка хранения в etcd

Чтобы убедиться, что данные хранятся в открытом виде, используем утилиту `etcdctl`:

```bash
ETCDCTL_API=3 etcdctl \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  get /registry/secrets/default/my-secret | hexdump -C
```

В hex-дампе вы увидите слово `supersecret` в читаемом виде — это подтверждает, что шифрования нет.

### Проверка наличия шифрования

Сначала проверим, включено ли уже шифрование:

```bash
ps -aux | grep kube-api | grep "encryption-provider-config"
```

Если вывод пустой — шифрование не настроено.

### Шаг 1: Создание ключа шифрования

Генерируем 32-байтный случайный ключ и кодируем его в base64:

```bash
head -c 32 /dev/urandom | base64
# Пример вывода: mZMplUTYCdFXFZ/Q0XVLQ2DuLSQIj0T5b3D8y0sMKPc=
```

### Шаг 2: Создание файла конфигурации шифрования

```bash
mkdir -p /etc/kubernetes/enc
cat > /etc/kubernetes/enc/enc.yaml << 'EOF'
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: mZMplUTYCdFXFZ/Q0XVLQ2DuLSQIj0T5b3D8y0sMKPc=
      - identity: {}
EOF
```

Порядок провайдеров имеет значение. `aescbc` стоит первым — это означает, что все новые записи будут зашифрованы. `identity: {}` стоит вторым — это позволяет читать уже существующие незашифрованные секреты.

### Шаг 3: Обновление манифеста kube-apiserver

Редактируем `/etc/kubernetes/manifests/kube-apiserver.yaml`:

```yaml
spec:
  containers:
    - name: kube-apiserver
      command:
        - kube-apiserver
        - --advertise-address=10.6.118.3
        # ... другие флаги ...
        - --encryption-provider-config=/etc/kubernetes/enc/enc.yaml  # добавляем
      volumeMounts:
        # ... существующие ...
        - name: enc
          mountPath: /etc/kubernetes/enc
          readOnly: true   # добавляем
  volumes:
    # ... существующие ...
    - name: enc
      hostPath:
        path: /etc/kubernetes/enc
        type: DirectoryOrCreate  # добавляем
```

После сохранения файла kube-apiserver автоматически перезапустится (он работает как статический Pod).

### Шаг 4: Проверка шифрования

Создаём новый секрет:

```bash
kubectl create secret generic my-secret-2 --from-literal=key2=topsecret
```

Проверяем в etcd:

```bash
ETCDCTL_API=3 etcdctl \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  get /registry/secrets/default/my-secret-2 | hexdump -C
```

Теперь слово `topsecret` не читается в дампе — данные зашифрованы.

### Шаг 5: Повторное шифрование существующих секретов

Секреты, созданные до включения шифрования, остаются незашифрованными. Чтобы зашифровать их все:

```bash
kubectl get secrets --all-namespaces -o json | kubectl replace -f -
```

Эта команда читает все секреты и записывает их обратно — теперь уже через зашифрованный путь.

### Методы шифрования в Kubernetes

В Kubernetes доступно несколько провайдеров шифрования:

| Провайдер | Описание | Сила |
|---|---|---|
| `identity` | Без шифрования (plaintext) | — |
| `aescbc` | AES в режиме CBC | Надёжный, рекомендован |
| `aesgcm` | AES в режиме GCM | Более быстрый |
| `secretbox` | XSalsa20 + Poly1305 | Современный |
| `kms` | Интеграция с внешним KMS | Максимальная безопасность |

---

## Часть 3. Безопасность в Docker: основы для понимания Kubernetes

### Изоляция процессов через Linux Namespaces

Контейнеры Docker разделяют ядро хост-системы, но изолированы с помощью механизма Linux Namespaces. Каждый контейнер получает собственное пространство имён для процессов.

Запустим контейнер:
```bash
docker run ubuntu sleep 3600
```

Внутри контейнера процесс `sleep` виден с PID 1:
```
PID   USER     COMMAND
1     root     sleep 3600
```

На хост-системе тот же процесс виден с другим PID (например, 3816):
```
PID   USER     COMMAND
3816  root     sleep 3600
```

Это изоляция пространства имён: контейнер "думает", что он единственный, хотя хост видит реальную картину.

### Управление пользователем контейнера

По умолчанию Docker запускает процессы внутри контейнера от имени пользователя `root`. Это может быть проблемой безопасности, потому что в случае уязвимости в приложении атакующий получит root-привилегии внутри контейнера.

**Способ 1: флаг `--user` при запуске:**

```bash
docker run --user=1000 ubuntu sleep 3600
```

Проверяем на хосте:
```bash
ps aux | grep sleep
# USER: 1000
```

**Способ 2: инструкция `USER` в Dockerfile:**

```dockerfile
FROM ubuntu
USER 1000
```

```bash
docker build -t my-ubuntu-image .
docker run my-ubuntu-image sleep 3600
```

Второй способ предпочтительнее для production: он обеспечивает, что образ всегда запускается с правильным пользователем без необходимости помнить о флаге при каждом запуске.

### Root в контейнере vs Root на хосте: Linux Capabilities

Возникает закономерный вопрос: если процесс в контейнере работает как root, он так же опасен, как настоящий root на хосте?

Ответ: нет, и вот почему. Docker использует механизм **Linux Capabilities** для ограничения привилегий root внутри контейнера.

В Linux root — это не монолитная "суперсила". Привилегии разбиты на отдельные capabilities:

- `CHOWN` — изменение владельца файлов
- `NET_ADMIN` — управление сетевыми интерфейсами
- `SYS_TIME` — изменение системного времени
- `KILL` — отправка сигналов процессам
- `SYS_BOOT` — перезагрузка системы
- `NET_BIND_SERVICE` — привязка к привилегированным портам (<1024)
- и многие другие (всего более 30)

Docker по умолчанию предоставляет контейнеру лишь некоторые из них, исключая наиболее опасные (например, перезагрузку хоста).

**Добавление capability:**
```bash
docker run --cap-add MAC_ADMIN ubuntu
docker run --cap-add NET_ADMIN ubuntu
```

**Удаление capability:**
```bash
docker run --cap-drop KILL ubuntu
```

**Полные привилегии (использовать крайне осторожно!):**
```bash
docker run --privileged ubuntu
```

Флаг `--privileged` снимает все ограничения и даёт контейнеру полный доступ к хост-системе. Никогда не используйте его в production без крайней необходимости.

---

## Часть 4. Security Contexts в Kubernetes

### Концепция Security Context

Security Context в Kubernetes — это прямой аналог флагов безопасности Docker (`--user`, `--cap-add`, `--cap-drop`), только описанный декларативно в YAML-манифесте.

Security Context может быть определён на двух уровнях:

1. **На уровне Pod'а** — применяется ко всем контейнерам в Pod'е
2. **На уровне контейнера** — применяется только к конкретному контейнеру

Если настройки указаны на обоих уровнях — контейнерный уровень имеет приоритет и переопределяет Pod-уровень.

### Security Context на уровне контейнера

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-pod
spec:
  containers:
    - name: ubuntu
      image: ubuntu
      command: ["sleep", "3600"]
      securityContext:
        runAsUser: 1000
        capabilities:
          add: ["MAC_ADMIN"]
```

Здесь `runAsUser: 1000` задаёт UID процесса, а `capabilities.add` добавляет Linux capability.

**Важно:** `capabilities` можно указывать только на уровне контейнера, не Pod'а. На уровне Pod'а `capabilities` недоступны.

### Security Context на уровне Pod'а

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-pod
spec:
  securityContext:
    runAsUser: 1001    # применяется ко всем контейнерам
  containers:
    - name: ubuntu
      image: ubuntu
      command: ["sleep", "3600"]
```

### Приоритет: контейнер vs Pod

Рассмотрим показательный пример с двумя контейнерами:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-pod
spec:
  securityContext:
    runAsUser: 1001    # Pod-уровень
  containers:
    - image: ubuntu
      name: web
      command: ["sleep", "5000"]
      securityContext:
        runAsUser: 1002  # Контейнер-уровень — перекрывает Pod-уровень
    - image: ubuntu
      name: sidecar
      command: ["sleep", "5000"]
      # Нет контейнерного securityContext — наследует от Pod'а
```

Результат:
- Контейнер `web` работает как **пользователь 1002** (контейнерный уровень перекрыл Pod-уровень)
- Контейнер `sidecar` работает как **пользователь 1001** (наследует от Pod'а)

### Практические задачи

**Задача 1: Проверка пользователя внутри Pod'а**

```bash
kubectl exec -it ubuntu-sleeper -- bash
whoami
# root
```

**Задача 2: Изменить Pod, чтобы процесс работал как UID 1010**

```bash
# Экспортируем конфигурацию
kubectl get pod ubuntu-sleeper -o yaml > ubuntu-sleeper.yaml
```

Редактируем файл — добавляем `securityContext` на уровне Pod'а:

```yaml
spec:
  securityContext:
    runAsUser: 1010
  containers:
    - command:
        - sleep
        - "4800"
      image: ubuntu
      name: ubuntu
```

```bash
kubectl delete pod ubuntu-sleeper --force
kubectl apply -f ubuntu-sleeper.yaml
```

**Задача 3: Запустить Pod как root с capability SYS_TIME**

Убираем `securityContext` на уровне Pod'а (или не указываем `runAsUser` — по умолчанию это root), добавляем capability на уровне контейнера:

```yaml
spec:
  containers:
    - command:
        - sleep
        - "4800"
      image: ubuntu
      name: ubuntu
      securityContext:
        capabilities:
          add: ['SYS_TIME']
```

**Задача 4: Добавить несколько capabilities**

```yaml
securityContext:
  capabilities:
    add: ['SYS_TIME', 'NET_ADMIN']
```

```bash
kubectl delete pod ubuntu-sleeper --force
kubectl apply -f ubuntu-sleeper.yaml
```

---

## Часть 5. Требования к ресурсам в Kubernetes

### Как Kubernetes распределяет ресурсы

Каждый узел кластера имеет фиксированное количество CPU и памяти. Когда создаётся Pod, планировщик (scheduler) анализирует доступные ресурсы на каждом узле и выбирает подходящий. Если ни один узел не имеет достаточных ресурсов, Pod остаётся в статусе `Pending`.

Для диагностики:
```bash
kubectl describe pod <имя-pod'а>
# В секции Events будет: "Insufficient cpu" или "Insufficient memory"
```

### Resource Requests: минимальные требования

Resource Request — это количество ресурсов, которое Pod **гарантированно получит**. Планировщик выбирает только те узлы, где есть как минимум столько свободных ресурсов.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: simple-webapp-color
spec:
  containers:
  - name: simple-webapp-color
    image: simple-webapp-color
    ports:
    - containerPort: 8080
    resources:
      requests:
        memory: "4Gi"
        cpu: "2"
```

**Форматы CPU:**
- `1` — один vCPU (= 1 AWS vCPU = 1 GCP Core = 1 Azure Core = 1 Hyperthread)
- `0.5` или `500m` — половина vCPU (m = milli)
- `100m` — минимально разумное значение

**Форматы памяти:**
- `256Mi` — 256 мебибайт (2²⁸ байт)
- `1Gi` — 1 гибибайт (2³⁰ байт)
- `256M` — 256 мегабайт (10⁶ × 256 байт, отличается от Mi!)
- `1G` — 1 гигабайт

### Resource Limits: максимальное потребление

Resource Limit — это потолок потребления ресурсов, выше которого контейнер не сможет подняться.

```yaml
resources:
  requests:
    memory: "1Gi"
    cpu: "1"
  limits:
    memory: "2Gi"
    cpu: "2"
```

**Что происходит при превышении лимитов:**

- **CPU:** контейнер **троттлится** (искусственно замедляется). Он не может использовать больше CPU, чем указано в лимите, но и не завершается. CPU throttling — это предсказуемое поведение.

- **Память:** если контейнер пытается использовать больше памяти, чем установлен лимит, Pod **завершается с ошибкой OOMKilled** (Out Of Memory Killed). Память не поддаётся троттлингу — её нельзя "придушить", только убить процесс.

### Четыре сценария конфигурации ресурсов

**Сценарий 1: Нет ни requests, ни limits**

Контейнер может потреблять сколько угодно ресурсов. Он может "съесть" все ресурсы узла, лишив ресурсов другие Pod'ы. Допустимо только в строго контролируемых средах.

**Сценарий 2: Есть limits, но нет requests**

Kubernetes автоматически приравнивает requests к limits. Контейнер гарантированно получит ровно столько, сколько указано в limits, и не сможет превысить это значение.

**Сценарий 3: Есть и requests, и limits**

Самый распространённый и рекомендуемый вариант для production. Контейнер гарантированно получает resources (requests), но может кратковременно использовать больше вплоть до limits при наличии свободных ресурсов на узле.

**Сценарий 4: Есть requests, но нет limits**

Контейнер гарантированно получит запрошенные ресурсы. Если на узле есть свободные ресурсы, он может потреблять больше. Опасен тем, что один Pod может забрать все дополнительные ресурсы.

### Практическая задача: OOMKilled

Рассмотрим Pod `elephant`, который не запускается:

```bash
kubectl describe pod elephant
```

В выводе находим:
```
State: Waiting
Reason: CrashLoopBackOff
Last State: Terminated
Reason: OOMKilled
Exit Code: 1
Limits:
  memory: 10Mi
Requests:
  memory: 5Mi
```

Приложение внутри Pod'а пытается использовать 15 MB памяти, но лимит — 10 Mi. Kubernetes убивает контейнер, тот перезапускается, снова убивается — получается цикл CrashLoopBackOff.

Решение:

```bash
kubectl get pod elephant -o yaml > elephant.yaml
kubectl delete pod elephant
vi elephant.yaml  # меняем 10Mi на 20Mi
kubectl apply -f elephant.yaml
```

### LimitRange: умолчания для namespace

По умолчанию Pod'ы без указанных ресурсов не имеют никаких ограничений. `LimitRange` позволяет задать умолчания для всего namespace:

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: cpu-resource-constraint
spec:
  limits:
  - type: Container
    default:         # лимит по умолчанию (если не указан)
      cpu: "500m"
    defaultRequest:  # request по умолчанию (если не указан)
      cpu: "500m"
    max:             # максимально допустимый лимит
      cpu: "1"
    min:             # минимально допустимый request
      cpu: "100m"
```

Аналогично для памяти:

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: memory-resource-constraint
spec:
  limits:
  - type: Container
    default:
      memory: "1Gi"
    defaultRequest:
      memory: "1Gi"
    max:
      memory: "1Gi"
    min:
      memory: "500Mi"
```

Важно: LimitRange применяется только к новым и обновлённым Pod'ам, не к уже существующим.

### ResourceQuota: общий бюджет namespace

Если LimitRange управляет отдельными контейнерами, то `ResourceQuota` управляет совокупным потреблением всего namespace:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: namespace-quota
spec:
  hard:
    requests.cpu: "4"
    requests.memory: "4Gi"
    limits.cpu: "10"
    limits.memory: "10Gi"
```

Это означает: все Pod'ы в namespace вместе не могут запросить более 4 CPU и 4 Gi памяти, а использовать — более 10 CPU и 10 Gi.

---

## Часть 6. Service Accounts: аутентификация машин в Kubernetes

### Два типа аккаунтов

В Kubernetes существуют два принципиально разных типа аккаунтов:

**User Accounts** — для людей (администраторов, разработчиков), которые управляют кластером через kubectl или дашборд.

**Service Accounts** — для приложений и сервисов, которым нужно взаимодействовать с Kubernetes API. Типичные примеры: Prometheus (мониторинг), Jenkins (CI/CD), ArgoCD (GitOps), пользовательские операторы.

### Создание Service Account

```bash
kubectl create serviceaccount dashboard-sa
```

```bash
kubectl get serviceaccount
```
```
NAME          SECRETS   AGE
default       1         218d
dashboard-sa  1         4d
```

```bash
kubectl describe serviceaccount dashboard-sa
```
```
Name:                dashboard-sa
Namespace:           default
Mountable secrets:   dashboard-sa-token-kbbdm
Tokens:              dashboard-sa-token-kbbdm
```

### Получение и использование токена

```bash
kubectl describe secret dashboard-sa-token-kbbdm
```

В поле `token` будет JWT-токен. Его можно использовать для вызова Kubernetes API:

```bash
curl https://192.168.56.70:6443/api \
  --insecure \
  --header "Authorization: Bearer eyJhbgG..."
```

### Default Service Account и автоматическое монтирование

В каждом namespace Kubernetes автоматически создаёт Service Account по имени `default`. Когда вы создаёте Pod без указания `serviceAccountName`, Kubernetes автоматически монтирует токен `default` Service Account в Pod.

Посмотрим на Pod без явно указанного SA:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-kubernetes-dashboard
spec:
  containers:
    - name: my-kubernetes-dashboard
      image: my-kubernetes-dashboard
```

```bash
kubectl describe pod my-kubernetes-dashboard
```

В выводе увидим:
```
Mounts:
  /var/run/secrets/kubernetes.io/serviceaccount from default-token-j4hkv (ro)
```

Токен монтируется по пути `/var/run/secrets/kubernetes.io/serviceaccount/token`. Приложение может читать его напрямую из файловой системы.

### Использование кастомного Service Account

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-kubernetes-dashboard
spec:
  containers:
    - name: my-kubernetes-dashboard
      image: my-kubernetes-dashboard
  serviceAccountName: dashboard-sa
```

После пересоздания Pod'а:

```bash
kubectl describe pod my-kubernetes-dashboard
# Mounts: /var/run/secrets/kubernetes.io/serviceaccount from dashboard-sa-token-kbbdm (ro)
```

Изменить `serviceAccountName` у работающего Pod'а нельзя — только пересоздание.

### Отключение автоматического монтирования токена

Если приложению не нужен доступ к Kubernetes API (например, обычный веб-сервер), рекомендуется отключить автоматическое монтирование токена из соображений безопасности:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-webapp
spec:
  automountServiceAccountToken: false
  containers:
    - name: my-webapp
      image: my-webapp
```

### Изменения в Kubernetes 1.22 и 1.24

**До версии 1.22:** создание Service Account автоматически создавало Secret с бессрочным JWT-токеном. Это было неудобно с точки зрения безопасности — токен не истекал никогда.

**Kubernetes 1.22 (KEP-1205):** введён TokenRequest API. Теперь токены генерируются динамически, привязаны к конкретной аудитории (audience-bound) и имеют ограниченный срок жизни. Они монтируются через `projected volumes`, а не через обычные Secret-тома:

```yaml
volumes:
  - name: kube-api-access-6mtg8
    projected:
      defaultMode: 420
      sources:
        - serviceAccountToken:
            expirationSeconds: 3607  # ~1 час
            path: token
        - configMap:
            name: kube-root-ca.crt
            items:
              - key: ca.crt
                path: ca.crt
        - downwardAPI:
            items:
              - fieldRef:
                  fieldPath: metadata.namespace
```

**Kubernetes 1.24 (KEP-2799):** создание Service Account больше не создаёт Secret с токеном автоматически. Если токен нужен явно (например, для внешнего сервиса), его нужно создать вручную:

```bash
kubectl create token dashboard-sa
```

Команда создаёт временный токен с ограниченным сроком действия (по умолчанию 1 час). Для изменения срока:

```bash
kubectl create token dashboard-sa --duration=8h
```

### Создание долгоживущего токена (legacy-подход)

Если по каким-то причинам нужен бессрочный токен (например, для сторонних систем, которые не умеют обновлять токены), можно создать Secret вручную:

```yaml
apiVersion: v1
kind: Secret
type: kubernetes.io/service-account-token
metadata:
  name: mysecretname
  annotations:
    kubernetes.io/service-account.name: dashboard-sa
```

Kubernetes автоматически заполнит этот Secret токеном для указанного Service Account. Этот подход считается устаревшим и менее безопасным — используйте его только при острой необходимости.

---

## Общие выводы и связи между темами

### Карта безопасности Kubernetes

```
Безопасность Kubernetes
        │
        ├── Данные (Secrets)
        │     ├── Хранение: etcd (base64, без шифрования по умолчанию)
        │     ├── Шифрование at rest: EncryptionConfiguration
        │     └── Внешние KMS: AWS/Azure/GCP/Vault
        │
        ├── Процессы (Security Contexts)
        │     ├── runAsUser: UID процесса
        │     ├── capabilities: Linux capabilities
        │     └── Приоритет: контейнер > Pod
        │
        ├── Ресурсы (Resource Management)
        │     ├── requests: минимальная гарантия
        │     ├── limits: максимальный потолок
        │     ├── LimitRange: умолчания для namespace
        │     └── ResourceQuota: общий бюджет namespace
        │
        └── Идентичность (Service Accounts)
              ├── Для приложений, обращающихся к API
              ├── Автоматическое монтирование токена
              └── Токены с ограниченным сроком (v1.22+)
```

### Ключевые принципы безопасности

1. **Принцип наименьших привилегий:** запускайте контейнеры с минимально необходимыми правами. Избегайте root, добавляйте только нужные capabilities.

2. **Defence in depth (глубокая оборона):** Secrets закодированы + etcd зашифрован + RBAC ограничивает доступ + внешний KMS хранит ключи.

3. **Не доверяйте умолчаниям:** default Service Account имеет ограниченные права, но лучше явно создавать SA для каждого приложения.

4. **Правильный размер ресурсов:** слишком маленькие лимиты приводят к OOMKilled, слишком большие — к расточительству и нестабильности при конкуренции за ресурсы.

5. **Secrets не для публичных репозиториев:** никогда не коммитьте YAML-файлы с секретами в Git. Используйте sealed-secrets, vault-agent или другие решения для безопасного хранения.

---

# 2.3 - Полное руководство: Service Accounts, Taints/Tolerations, Node Selectors, Node Affinity и их комбинирование

---

## Часть 1. Практическая работа с Service Accounts

### Диагностика проблем с правами доступа

Начнём с реального сценария, который отлично демонстрирует, зачем нужны Service Accounts и что происходит, когда права настроены неправильно.

Проверяем список Service Accounts в namespace по умолчанию:

```bash
kubectl get sa
```
```
NAME       SECRETS   AGE
default    0         20m
dev        0         35s
```

В кластере есть два SA: `default` (создаётся автоматически) и `dev` (создан вручную).

Проверяем, есть ли у `default` SA токен:

```bash
kubectl describe serviceaccount default
```

В секции `Tokens` будет пусто — начиная с Kubernetes 1.24, токены не создаются автоматически.

### Инспекция развёртывания dashboard-приложения

Предположим, в кластере развёрнуто веб-приложение для мониторинга Kubernetes (dashboard):

```bash
kubectl get deployments
kubectl describe deployment web-dashboard
```

В выводе видим:

```
Pod Template:
  Containers:
   web-dashboard:
    Image: gcr.io/kodekloud/customimage/my-kubernetes-dashboard
    Port: 8080/TCP
    Environment:
      PYTHONUNBUFFERED: 1
```

Приложение пытается обращаться к Kubernetes API, чтобы получить список Pod'ов. Но в логах видим ошибку:

```
pods is forbidden: User "system:serviceaccount:default:default" cannot list resource "pods" in API group "" in the namespace "default"
```

Это классическая ошибка недостаточных прав. Разберём её:

- `system:serviceaccount` — это тип аккаунта (сервисный, не пользовательский)
- `default` — namespace
- `default` — имя Service Account

То есть Pod использует `default` Service Account, у которого нет прав на чтение списка Pod'ов. Чтобы убедиться, описываем Pod:

```bash
kubectl get pod
kubectl describe pod <имя-pod'а>
```

В выводе:
```
Service Account: default
Mounts:
  /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-swjvh (ro)
```

Токен монтируется автоматически из volume-проекции, но прав он не даёт — у `default` SA минимальные привилегии.

### Создание нового Service Account с правами

**Шаг 1:** Создаём SA с нужными правами:

```bash
kubectl create serviceaccount dashboard-sa
```
```
serviceaccount/dashboard-sa created
```

**Шаг 2:** Проверяем RBAC-конфигурацию. В директории `/var/rbac/` могут находиться готовые файлы:

- `pod-reader-role.yaml` — определяет Role с правом читать Pod'ы
- `dashboard-sa-role-binding.yaml` — привязывает эту Role к `dashboard-sa`

Пример Role:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: default
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
```

Пример RoleBinding:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
- kind: ServiceAccount
  name: dashboard-sa
  namespace: default
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

**Шаг 3:** Генерируем токен для `dashboard-sa`:

```bash
kubectl create token dashboard-sa
```

Вывод — JWT-токен, который можно вставить в UI дашборда для авторизации. После этого дашборд покажет список Pod'ов.

### Обновление Deployment для автоматического использования нового SA

Вместо ручного ввода токена каждый раз лучше настроить Deployment так, чтобы он автоматически использовал `dashboard-sa`:

**Шаг 1:** Экспортируем текущий Deployment:

```bash
kubectl get deployment web-dashboard -o yaml > dashboard.yaml
```

**Шаг 2:** Редактируем `dashboard.yaml`, добавляя `serviceAccountName` в Pod-спецификацию:

```yaml
spec:
  replicas: 1
  selector:
    matchLabels:
      name: web-dashboard
  template:
    metadata:
      labels:
        name: web-dashboard
    spec:
      serviceAccountName: dashboard-sa    # добавляем эту строку
      containers:
      - env:
        - name: PYTHONUNBUFFERED
          value: "1"
        image: gcr.io/kodekloud/customimage/my-kubernetes-dashboard
        imagePullPolicy: Always
        name: web-dashboard
        ports:
        - containerPort: 8080
```

**Шаг 3:** Применяем:

```bash
kubectl apply -f dashboard.yaml
```

Теперь при каждом запуске Pod'а Kubernetes автоматически монтирует токен `dashboard-sa`, и приложение получает нужные права без ручного ввода.

**Важный нюанс:** в отличие от Pod'а, Deployment можно обновить без пересоздания — он создаст новый ReplicaSet с обновлёнными Pod'ами по стратегии RollingUpdate.

### Итоги по Service Accounts

Правильный workflow работы с SA выглядит так:

```
Создать SA → Создать Role с нужными правами → Создать RoleBinding → 
Указать SA в Pod/Deployment → Kubernetes автоматически монтирует токен
```

---

## Часть 2. Taints и Tolerations: управление размещением Pod'ов

### Концептуальная аналогия

Представьте человека, которого атакует насекомое. Если человека обработать репеллентом (taint), большинство насекомых (Pod'ов) будут отталкиваться. Но некоторые насекомые, устойчивые к данному репелленту (tolerant), смогут приземлиться.

В Kubernetes:
- **Taint** — метка на узле, отталкивающая Pod'ы
- **Toleration** — свойство Pod'а, позволяющее игнорировать конкретный taint

Важнейшее ограничение: taints/tolerations контролируют, **какие Pod'ы узел НЕ примет**, но НЕ гарантируют, **на каком именно узле Pod окажется**. Pod с нужной toleration может попасть на любой подходящий узел, а не обязательно на тот, который taint'd.

### Синтаксис taint

```bash
kubectl taint nodes <имя-узла> <ключ>=<значение>:<эффект>
```

Три возможных эффекта:

| Эффект | Поведение |
|---|---|
| `NoSchedule` | Новые Pod'ы без toleration не планируются на этот узел |
| `PreferNoSchedule` | Планировщик старается избегать этого узла, но не гарантирует |
| `NoExecute` | Новые Pod'ы не планируются + существующие без toleration **выселяются** |

### Практический пример: пошаговый разбор

**Шаг 1: Проверяем узлы кластера**

```bash
kubectl get nodes
```
```
NAME           STATUS   ROLES                  AGE    VERSION
controlplane   Ready    control-plane,master   17m    v1.20.0
node01         Ready    <none>                 16m    v1.20.0
```

**Шаг 2: Проверяем наличие taint'ов на node01**

```bash
kubectl describe node node01
```

В выводе:
```
Taints: <none>
```

На node01 нет taint'ов — Pod'ы могут размещаться там свободно.

**Шаг 3: Добавляем taint на node01**

```bash
kubectl taint node node01 spray=moreteam:NoSchedule
```

Теперь только Pod'ы с toleraton `spray=moreteam:NoSchedule` смогут попасть на node01.

**Шаг 4: Создаём Pod без toleration (mosquito)**

```bash
kubectl run mosquito --image=nginx
```

```bash
kubectl get pods
```
```
NAME        READY   STATUS    RESTARTS   AGE
mosquito    0/1     Pending   0          3m37s
```

Pod завис в статусе `Pending`. Описываем:

```bash
kubectl describe pod mosquito
```

В секции Events:
```
Warning  FailedScheduling  45s  default-scheduler  
0/2 nodes are available: 
  1 node(s) had taint {spray: moreteam:NoSchedule}, that the pod didn't tolerate, 
  1 node(s) had taint {node-role.kubernetes.io/master:NoSchedule}, that the pod didn't tolerate.
```

Оба узла недоступны: node01 имеет наш taint, controlplane имеет системный taint master.

**Шаг 5: Создаём Pod с toleration (bee)**

Нельзя задать tolerations через `kubectl run` напрямую, поэтому используем dry-run для генерации YAML:

```bash
kubectl run bee --image=nginx --dry-run=client -o yaml > bee.yaml
```

Редактируем `bee.yaml`, добавляя секцию `tolerations`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: bee
  name: bee
spec:
  containers:
  - image: nginx
    name: bee
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
  tolerations:
  - key: "spray"
    operator: "Equal"
    value: "moreteam"
    effect: "NoSchedule"
```

Применяем:

```bash
kubectl apply -f bee.yaml
```

```bash
kubectl get pods -o wide
```
```
NAME        READY   STATUS    RESTARTS   AGE     IP            NODE
bee         1/1     Running   0          36s     10.244.1.2    node01
mosquito    0/1     Pending   0          4m6s    <none>        <none>
```

Pod `bee` успешно размещён на node01, а `mosquito` по-прежнему ждёт.

**Шаг 6: Снимаем taint с controlplane, чтобы mosquito смог запуститься**

Проверяем taint на controlplane:

```bash
kubectl describe node controlplane
```
```
Taints: node-role.kubernetes.io/master:NoSchedule
```

Снимаем taint — обратите внимание на знак `-` в конце команды:

```bash
kubectl taint node controlplane node-role.kubernetes.io/master:NoSchedule-
```

```bash
kubectl describe node controlplane
```
```
Taints: <none>
```

Теперь `mosquito` автоматически планируется на controlplane:

```bash
kubectl get pods
```
```
NAME       READY   STATUS    RESTARTS   AGE
bee        1/1     Running   0          2m37s
mosquito   1/1     Running   0          6m7s
```

### Эффект NoExecute: выселение существующих Pod'ов

Это самый "агрессивный" эффект. Когда он применяется к узлу:

1. Новые Pod'ы без toleration не планируются (как NoSchedule)
2. Существующие Pod'ы без toleration **немедленно выселяются**

Пример сценария: у вас три узла с Pod'ами A, B, C, D. Вы решаете выделить node01 для специального приложения и применяете taint с `NoExecute`. Pod C, работающий на node01 без нужного toleration, будет выселен. Pod D с нужным toleration останется.

### Taint на master-узле

При инициализации кластера Kubernetes автоматически применяет taint к master-узлу:

```
node-role.kubernetes.io/master:NoSchedule
```

Именно поэтому обычные Pod'ы не запускаются на master. Это best practice: master должен быть занят только системными компонентами (etcd, kube-apiserver, scheduler и т.д.). Как мы видели выше, этот taint можно снять, но делать это в production не рекомендуется.

---

## Часть 3. Node Selectors: простое ограничение размещения

### Проблема

Представьте кластер с тремя узлами: два маломощных и один мощный. Задача — запускать ресурсоёмкие Pod'ы только на мощном узле.

По умолчанию Kubernetes-планировщик распределяет Pod'ы по всем доступным узлам. Без дополнительных настроек тяжёлый Pod может оказаться на слабом узле.

### Решение: nodeSelector

**Шаг 1:** Навешиваем метку на нужный узел:

```bash
kubectl label nodes node-1 size=Large
```

**Шаг 2:** В Pod-манифесте указываем `nodeSelector`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
spec:
  containers:
    - name: data-processor
      image: data-processor
  nodeSelector:
    size: Large
```

Kubernetes выберет только те узлы, у которых есть метка `size=Large`.

### Ограничения nodeSelector

Node Selectors работают только с простыми условиями вида "ключ = значение". Они не могут выразить:

- "Большой **или** средний" (логическое ИЛИ)
- "Не маленький" (отрицание)
- "Больше X ресурсов"

Для таких случаев нужен Node Affinity.

---

## Часть 4. Node Affinity: гибкое управление размещением

### Переход от nodeSelector к nodeAffinity

То же требование "только на Large-узле", но через Node Affinity:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
spec:
  containers:
    - name: data-processor
      image: data-processor
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: size
                operator: In
                values:
                  - Large
```

Разберём структуру детально:

- `affinity` — корневое поле для всех политик affinity
- `nodeAffinity` — конкретно для привязки к узлам
- `requiredDuringSchedulingIgnoredDuringExecution` — тип политики (подробно ниже)
- `nodeSelectorTerms` — массив условий (между элементами массива работает логическое ИЛИ)
- `matchExpressions` — условия внутри одного терма (между ними работает логическое И)
- `key: size` — ключ метки узла
- `operator: In` — оператор сравнения
- `values: [Large]` — допустимые значения

### Операторы matchExpressions

**Оператор `In`: узел должен иметь метку с одним из указанных значений**

```yaml
# Pod на Large ИЛИ Medium узлах
- key: size
  operator: In
  values:
    - Large
    - Medium
```

**Оператор `NotIn`: узел НЕ должен иметь метку с указанными значениями**

```yaml
# Pod на любом узле, кроме Small
- key: size
  operator: NotIn
  values:
    - Small
```

**Оператор `Exists`: метка должна существовать (значение не важно)**

```yaml
# Pod на любом узле с меткой "size" (любое значение)
- key: size
  operator: Exists
# поле values не нужно!
```

**Оператор `DoesNotExist`: метка должна отсутствовать**

```yaml
- key: gpu
  operator: DoesNotExist
```

**Операторы `Gt` и `Lt`: числовое сравнение**

```yaml
# Узлы с более чем 4 GPU
- key: gpu-count
  operator: Gt
  values:
    - "4"
```

### Типы Node Affinity политик

Название типа политики состоит из двух частей:
1. Поведение **во время планирования** (DuringScheduling)
2. Поведение **во время выполнения** (DuringExecution)

**`requiredDuringSchedulingIgnoredDuringExecution`**

- Во время планирования: правило **обязательно**. Если нет подходящего узла — Pod остаётся Pending.
- Во время выполнения: изменения меток узла **игнорируются**. Если метка исчезнет — Pod продолжает работать.

Применение: критически важные рабочие нагрузки, которые нельзя запускать "где попало".

**`preferredDuringSchedulingIgnoredDuringExecution`**

- Во время планирования: правило **желательно**, но не обязательно. Если нет подходящего узла — Pod размещается на любом доступном.
- Во время выполнения: то же самое — изменения меток игнорируются.

Применение: оптимизация размещения без жёсткого ограничения.

**`requiredDuringSchedulingRequiredDuringExecution`** (планируется в будущих версиях)

- Во время планирования: правило обязательно.
- Во время выполнения: если метка на узле изменится и Pod перестанет соответствовать правилу — Pod будет **выселен**.

Применение: строгое соблюдение политик в динамических кластерах.

### Практические задачи с Node Affinity

**Задача 1: Развернуть "blue" deployment только на node01**

```bash
# Шаг 1: Навешиваем метку
kubectl label node node01 color=blue

# Шаг 2: Создаём deployment
kubectl create deployment blue --image=nginx --replicas=3

# Шаг 3: Генерируем YAML для редактирования
kubectl get deployment blue -o yaml > blue.yaml
```

Редактируем `blue.yaml`, добавляя nodeAffinity в `spec.template.spec`:

```yaml
spec:
  template:
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: color
                    operator: In
                    values:
                      - blue
      containers:
        - name: nginx
          image: nginx
```

```bash
kubectl apply -f blue.yaml
kubectl get pods -o wide
```
```
NAME                    READY   STATUS    NODE
blue-566c768bd6-f8xzm   1/1     Running   node01
blue-566c768bd6-jsz95   1/1     Running   node01
blue-566c768bd6-sf9dk   1/1     Running   node01
```

Все три реплики на node01.

**Задача 2: Развернуть "red" deployment только на controlplane**

```bash
kubectl create deployment red --image=nginx --replicas=2 --dry-run=client -o yaml > red.yaml
```

Добавляем nodeAffinity с оператором `Exists` для проверки роли master:

```yaml
spec:
  template:
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: node-role.kubernetes.io/master
                    operator: Exists
      containers:
        - image: nginx
          name: nginx
```

```bash
kubectl create -f red.yaml
```

Pod'ы "red" запустятся на controlplane, несмотря на его taint — потому что toleration для системных taint'ов часто уже присутствует, или мы явно указали affinity для master.

---

## Часть 5. Taints/Tolerations vs Node Affinity: сравнение и комбинирование

### Ключевые различия

Понимание разницы между двумя механизмами критично:

| Характеристика | Taints & Tolerations | Node Affinity |
|---|---|---|
| **Направление ограничения** | Узел отталкивает Pod'ы | Pod притягивается к узлам |
| **Гарантия попадания на нужный узел** | Нет | Да (при `required`) |
| **Защита узла от чужих Pod'ов** | Да | Нет |
| **Механизм** | Отталкивание | Притягивание |

### Почему каждый метод недостаточен сам по себе

**Только taints/tolerations:** если у Pod'а есть toleration для taint'а узла, он может попасть туда, но также может попасть на любой другой узел без taint'а. Нет гарантии, что Pod окажется именно на "своём" узле.

**Только node affinity:** Pod гарантированно попадёт на нужный узел (если он существует), но на этот же узел могут попасть и "чужие" Pod'ы из других команд, у которых нет affinity-правил.

### Задача: полная изоляция узлов для команд

Представьте общий кластер с тремя узлами (Blue, Red, Green) и тремя командами. Задача — чтобы:

1. Blue Pod работал **только** на Blue узле
2. На Blue узел попадали **только** Blue Pod'ы
3. То же самое для Red и Green

**Решение: комбинируем оба механизма**

**Шаг 1:** Помечаем узлы метками (для Node Affinity):

```bash
kubectl label node blue-node color=blue
kubectl label node red-node color=red
kubectl label node green-node color=green
```

**Шаг 2:** Наносим taint'ы на узлы (чтобы отталкивать чужие Pod'ы):

```bash
kubectl taint node blue-node color=blue:NoSchedule
kubectl taint node red-node color=red:NoSchedule
kubectl taint node green-node color=green:NoSchedule
```

**Шаг 3:** В каждый Pod добавляем и toleration, и node affinity.

Пример для Blue Pod'а:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: blue-pod
spec:
  containers:
    - name: app
      image: my-app
  
  # Toleration: разрешает попасть на blue-node (без него taint оттолкнёт)
  tolerations:
    - key: "color"
      operator: "Equal"
      value: "blue"
      effect: "NoSchedule"
  
  # Node Affinity: гарантирует попадание именно на blue-node
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: color
                operator: In
                values:
                  - blue
```

**Результат комбинации:**

- Taint на blue-node отталкивает Red и Green Pod'ы (у них нет toleration для `color=blue`)
- Node Affinity в Blue Pod'е гарантирует, что он попадёт именно на blue-node, а не на любой другой узел

Только Blue Pod имеет **и** toleration для blue-node **и** affinity к blue-node — поэтому он туда попадёт и только туда.

### Визуализация логики

```
Blue Pod:
  toleration: color=blue:NoSchedule    → может попасть на blue-node (taint не отталкивает)
  affinity: color=blue (required)      → должен попасть на blue-node

Red Pod:
  toleration: color=red:NoSchedule     → НЕ может попасть на blue-node (taint отталкивает)
  affinity: color=red (required)       → должен попасть на red-node

Итог: 
  blue-node ← только Blue Pod (taint блокирует других + affinity направляет Blue)
  red-node  ← только Red Pod
  green-node ← только Green Pod
```

---

## Общая карта механизмов размещения Pod'ов

```
Механизмы размещения Pod'ов в Kubernetes
                    │
        ┌───────────┴───────────┐
        │                       │
   Со стороны УЗЛА        Со стороны POD'а
        │                       │
   Taints                  Tolerations (пара к taint)
   (отталкивание)          
                          Node Selectors (простое ключ=значение)
                          
                          Node Affinity (гибкие выражения)
                            ├── required (обязательно)
                            └── preferred (желательно)
                          
                          Pod Affinity (привязка к другим Pod'ам)
                          Pod Anti-Affinity (отталкивание от Pod'ов)
```

### Когда что применять

| Сценарий | Инструмент |
|---|---|
| Запретить планирование на узле для большинства Pod'ов | Taint `NoSchedule` |
| Выселить работающие Pod'ы с узла | Taint `NoExecute` |
| Мягко избегать узла | Taint `PreferNoSchedule` |
| Pod должен попасть на конкретный узел | Node Affinity `required` |
| Pod предпочитает определённый узел | Node Affinity `preferred` |
| Простая привязка по одной метке | Node Selector |
| Полная изоляция узла для конкретных Pod'ов | Taint + Node Affinity |

---

## Итоговые выводы

**Service Accounts** — основа машинной аутентификации в Kubernetes. Всегда создавайте отдельные SA для каждого приложения с минимально необходимыми правами. Никогда не полагайтесь на `default` SA в production.

**Taints** действуют как "запрет на вход" для узла. Они защищают узел от нежелательных Pod'ов, но не контролируют, куда именно пойдут Pod'ы с нужными tolerations.

**Node Affinity** — это "компас" для Pod'а, указывающий, на каком узле он должен запуститься. Но без taint'ов на узлах другие Pod'ы могут попасть туда же.

**Комбинация taint + node affinity** даёт полную двустороннюю изоляцию: узел защищён от чужих Pod'ов (taint), а Pod гарантированно попадает на нужный узел (node affinity). Это единственный способ добиться строгой изоляции в общем кластере.

---

# 3.0 - Multi-Container Pods и Init Containers в Kubernetes

## Часть 1: Multi-Container Pods — Многоконтейнерные поды

---

### Что такое под (Pod) в Kubernetes?

Прежде чем углубляться в тему, важно понять базовое понятие. Pod — это наименьшая развёртываемая единица в Kubernetes. Он может содержать один или несколько контейнеров, которые работают вместе как единое целое.

По умолчанию большинство подов содержат **один контейнер**. Однако бывают ситуации, когда два или более контейнера должны работать бок о бок — именно тогда используются **многоконтейнерные поды (Multi-Container Pods)**.

---

### Зачем нужны многоконтейнерные поды?

Современная разработка приложений строится на принципе **микросервисов**: большое монолитное приложение разбивается на маленькие независимые компоненты. Каждый компонент можно разрабатывать, деплоить и масштабировать независимо.

Однако иногда два сервиса настолько тесно связаны, что их выгодно держать вместе. Классический пример:

- **Веб-сервер** — обрабатывает HTTP-запросы
- **Агент логирования** — собирает и отправляет логи в централизованную систему

Логично держать их раздельно как процессы, но запускать вместе в одном поде, чтобы они могли взаимодействовать максимально эффективно.

---

### Ключевые преимущества многоконтейнерных подов

#### 1. Общий жизненный цикл (Shared Lifecycle)
Все контейнеры в поде **запускаются и останавливаются одновременно**. Если под создаётся — стартуют все контейнеры. Если под удаляется — останавливаются все. Это гарантирует, что вспомогательный сервис (например, агент логов) всегда присутствует рядом с основным приложением.

#### 2. Единое сетевое пространство (Unified Network Namespace)
Все контейнеры внутри одного пода **разделяют один и тот же сетевой стек**. Это значит, что они могут общаться между собой через `localhost`, не требуя дополнительной конфигурации сети.

Пример: если веб-сервер слушает порт `8080`, то агент логирования может обращаться к нему как `localhost:8080` — просто и быстро.

#### 3. Общие тома хранилища (Shared Storage Volumes)
Контейнеры в одном поде могут **читать и писать в одни и те же тома**. Например, веб-сервер пишет логи в файл `/var/log/app.log`, а агент логирования читает этот же файл и отправляет его в Elasticsearch или другой сборщик логов.

---

### Как создать многоконтейнерный под?

#### Базовый под с одним контейнером:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: simple-webapp
  labels:
    name: simple-webapp
spec:
  containers:
  - name: simple-webapp
    image: simple-webapp
    ports:
    - containerPort: 8080
```

Здесь всё просто: один раздел `containers`, один контейнер.

#### Многоконтейнерный под (добавляем агент логирования):

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: simple-webapp
  labels:
    name: simple-webapp
spec:
  containers:
  - name: simple-webapp
    image: simple-webapp
    ports:
    - containerPort: 8080
  - name: log-agent
    image: log-agent
```

Разница минимальна — достаточно добавить **ещё один элемент в массив `containers`**. Kubernetes сам позаботится о том, чтобы оба контейнера запустились вместе, имели общую сеть и могли использовать общие тома.

---

### Паттерны проектирования многоконтейнерных подов

В Kubernetes выделяют три классических архитектурных паттерна для многоконтейнерных подов. Разберём каждый подробно.

---

#### Паттерн 1: Sidecar (Прицеп / Боковой вагон)

**Идея:** рядом с основным контейнером запускается вспомогательный — "sidecar", который расширяет или дополняет функциональность основного, не вмешиваясь в его код.

**Типичный пример:** агент логирования рядом с веб-сервером.

```
┌─────────────────────────────────┐
│            POD                  │
│  ┌─────────────┐  ┌──────────┐  │
│  │  Web Server │  │  Sidecar │  │
│  │  (основной) │  │ (лог-    │  │
│  │             │──│  агент)  │──┼──► Log Server
│  └─────────────┘  └──────────┘  │
└─────────────────────────────────┘
```

**Когда использовать:**
- Сбор и отправка логов
- Мониторинг и метрики
- Синхронизация файлов (например, git-sync для обновления контента сайта)
- Обработка SSL/TLS-трафика

**Преимущество:** код основного приложения остаётся чистым и не знает о существовании агента. Приложение просто пишет логи, а sidecar сам их собирает.

---

#### Паттерн 2: Adapter (Адаптер)

**Идея:** адаптер-контейнер стандартизирует или трансформирует данные, поступающие от основного контейнера, перед отправкой во внешнюю систему.

**Типичный пример:** разные микросервисы генерируют логи в разных форматах. Централизованная система сбора логов ожидает единый формат. Вместо того чтобы переписывать каждый сервис, рядом с каждым запускается контейнер-адаптер, который нормализует формат.

Представьте, что три разных сервиса пишут логи вот так:

```
12-JULY-2018 16:05:49 "GET /index1.html" 200
12/JUL/2018:16:05:49 -0800 "GET /index2.html" 200
GET 1531411549 "/index3.html" 200
```

Три разных формата даты, разные разделители, разный порядок полей. Адаптер-контейнер берёт эти разнородные логи и приводит их к единому стандарту перед отправкой в Elasticsearch, Splunk или другую систему.

```
┌───────────────────────────────────────┐
│                  POD                  │
│  ┌─────────────┐  ┌─────────────────┐ │
│  │   Сервис    │  │    Adapter      │ │
│  │  (пишет     │──│  (нормализует   │─┼──► Центральный
│  │  свой формат│  │   формат логов) │ │    сборщик логов
│  └─────────────┘  └─────────────────┘ │
└───────────────────────────────────────┘
```

**Когда использовать:**
- Нормализация форматов логов
- Преобразование форматов метрик
- Трансформация данных между устаревшими и современными системами

---

#### Паттерн 3: Ambassador (Посол / Посредник)

**Идея:** контейнер-посредник берёт на себя функцию маршрутизации трафика к правильному бэкенду в зависимости от окружения, скрывая эту логику от основного приложения.

**Типичный пример:** приложение должно подключаться к базе данных. В разработке — это локальная БД, на тестовом стенде — тестовая БД, в продакшне — продакшн БД.

Без ambassador'а в коде приложения пришлось бы писать логику определения окружения. Это усложняет код и делает его менее универсальным.

**С паттерном Ambassador:**

```
┌──────────────────────────────────────────────────────┐
│                        POD                           │
│  ┌──────────────┐     ┌──────────────────────────┐   │
│  │  Приложение  │     │    Ambassador Container   │   │
│  │              │────►│    (proxy)                │   │
│  │  → localhost │     │                           │──►│ Dev DB
│  └──────────────┘     │  определяет окружение     │──►│ Test DB
│                       │  и маршрутизирует запросы │──►│ Prod DB
│                       └──────────────────────────┘   │
└──────────────────────────────────────────────────────┘
```

Приложение **всегда** обращается к `localhost`, а ambassador сам решает, куда направить запрос.

**Когда использовать:**
- Маршрутизация запросов к разным БД в разных окружениях
- Service discovery
- Rate limiting и circuit breaking
- Мониторинг исходящих запросов

---

## Часть 2: Init Containers — Инициализирующие контейнеры

---

### Что такое Init Containers?

**Init Containers** — это специальные контейнеры, которые запускаются **до** основных контейнеров пода. Они выполняют подготовительную работу: загружают данные, ждут доступности сервисов, проводят миграции БД и т.д.

Ключевые характеристики:

- Запускаются **строго последовательно** (один за другим)
- Каждый следующий init-контейнер стартует только после успешного завершения предыдущего
- Только после завершения **всех** init-контейнеров стартуют основные контейнеры
- Если init-контейнер завершается с ошибкой — под перезапускается

---

### Как определить под с init-контейнером?

Чтобы посмотреть список всех подов:

```bash
kubectl get pods
```

Пример вывода:

```
NAME    READY   STATUS    RESTARTS   AGE
red     1/1     Running   0          54s
green   2/2     Running   0          54s
blue    1/1     Running   0          54s
```

Чтобы узнать детали конкретного пода:

```bash
kubectl describe pod <имя-пода>
```

В выводе нужно искать секцию `Init Containers`. Если она есть — под имеет init-контейнеры.

---

### Разбор примера: поды red, green и blue

#### Под red — есть init-контейнер

В описании пода red видно секцию `Init Containers`:

```
Init Containers:
  init-myservice:
    Image: busybox
    Command:
      sh
      -c
      sleep 5
    State: Terminated
    Reason: Completed
    Exit Code: 0
```

Init-контейнер с именем `init-myservice` использовал образ `busybox`, выполнил команду `sleep 5` (подождал 5 секунд) и **успешно завершился** (Exit Code: 0, State: Terminated, Reason: Completed).

#### Под green — нет init-контейнера

В описании пода green секция `Init Containers` отсутствует. Видны только основные контейнеры:

```
Containers:
  red-container:
    Image: busybox:1.28
    Command:
      - sh
      - -c
      - echo The app is running! && sleep 3600
    State: Running
```

#### Под blue — есть init-контейнер

```
Init Containers:
  init-myservice:
    Image: busybox
    Command:
      - sh
      - -c
      - sleep 5
    State: Terminated
    Reason: Completed
```

Аналогично поду red — init-контейнер на образе `busybox` выполнил `sleep 5` и завершился успешно.

**Итог первой части:**
| Под | Init Container? | Образ | Команда | Состояние |
|-----|----------------|-------|---------|-----------|
| red | ✅ Да | busybox | sleep 5 | Terminated (Completed) |
| green | ❌ Нет | — | — | — |
| blue | ✅ Да | busybox | sleep 5 | Terminated (Completed) |

---

### Разбор примера: под purple с двумя init-контейнерами

Под `purple` содержит **два init-контейнера**, которые запускаются последовательно:

```
Init Containers:
  warm-up-1:
    Image: busybox:1.28
    Command:
      sh -c sleep 600      ← ждёт 10 минут
    State: Running
    Ready: False

  warm-up-2:
    Image: busybox:1.28
    Command:
      sh -c sleep 1200     ← ждёт 20 минут
    State: Waiting
    Reason: PodInitializing
    Ready: False
```

**Поведение:**
1. Сначала запускается `warm-up-1` и спит **600 секунд** (10 минут)
2. Только после его завершения запускается `warm-up-2` и спит **1200 секунд** (20 минут)
3. Только после завершения обоих запускается основной контейнер `purple-container`

**Итого:** под `purple` станет полностью доступен через **1800 секунд (30 минут)** после создания.

Статус пода в `kubectl get pods` будет выглядеть как `Init:0/2`, что означает: "выполнено 0 из 2 init-контейнеров".

---

### Практика: обновление пода red

Задача: обновить под `red`, добавив init-контейнер на образе `busybox`, который будет спать 20 секунд.

Важный момент: **нельзя обновить init-контейнеры у уже запущенного пода**. Нужно его пересоздать.

#### Шаг 1: Экспортировать текущую конфигурацию в файл

```bash
kubectl get pod red -o yaml > red.yaml
```

Флаг `-o yaml` говорит Kubernetes вернуть конфигурацию в формате YAML. `> red.yaml` перенаправляет вывод в файл.

#### Шаг 2: Удалить существующий под

```bash
kubectl delete pod red
```

#### Шаг 3: Отредактировать файл red.yaml

Добавить секцию `initContainers` в `spec`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: red
  namespace: default
spec:
  initContainers:
  - name: red-initcontainer
    image: busybox
    command:
    - "sleep"
    - "20"
  containers:
  - name: red-container
    image: busybox:1.28
    imagePullPolicy: IfNotPresent
    command:
    - sh
    - -c
    - echo The app is running! && sleep 3600
```

**Обратите внимание:** секция `initContainers` добавляется **выше** секции `containers`, но находится внутри `spec`. Это логично: init-контейнеры должны завершиться **до** запуска основных.

#### Шаг 4: Применить новую конфигурацию

```bash
kubectl apply -f red.yaml
```

После применения под red пересоздастся. Сначала запустится `red-initcontainer` (подождёт 20 секунд), затем стартует основной `red-container`.

---

### Диагностика и исправление: под orange с CrashLoopBackOff

#### Проблема

Команда `kubectl get pods` показывает:

```
NAME      READY   STATUS                   RESTARTS     AGE
orange    0/1     Init:CrashLoopBackOff    1 (12s ago)  16s
```

`CrashLoopBackOff` означает, что контейнер запускается, сразу падает, Kubernetes пытается его перезапустить, и цикл повторяется.

#### Диагностика

```bash
kubectl describe pod orange
```

В описании видна команда init-контейнера:

```
Command:
  sh
  -c
  sleeep 2;
```

**Нашли проблему!** Опечатка: `sleeep` вместо `sleep` (лишняя буква `e`). Команда `sleeep` не существует в системе, поэтому оболочка возвращает Exit Code: 127 ("команда не найдена"), контейнер падает, Kubernetes пробует перезапустить — и так по кругу.

#### Исправление

**Шаг 1:** Экспортировать конфигурацию

```bash
kubectl get pod orange -o yaml > orange.yaml
```

**Шаг 2:** Удалить под

```bash
kubectl delete pod orange
```

**Шаг 3:** Исправить опечатку в orange.yaml

Было:
```yaml
initContainers:
- name: init-myservice
  image: busybox
  command:
  - sh
  - -c
  - sleeep 2    # ← ОШИБКА
```

Стало:
```yaml
initContainers:
- name: init-myservice
  image: busybox
  command:
  - sh
  - -c
  - sleep 2     # ← ИСПРАВЛЕНО
```

**Шаг 4:** Применить исправление

```bash
kubectl apply -f orange.yaml
```

После этого init-контейнер успешно выполнит `sleep 2`, завершится с кодом 0, и основной контейнер `orange-container` стартует в штатном режиме.

---

## Итоговые выводы

### Multi-Container Pods

| Паттерн | Задача | Пример |
|---------|--------|--------|
| **Sidecar** | Расширить функциональность основного контейнера | Агент логирования рядом с веб-сервером |
| **Adapter** | Стандартизировать данные от основного контейнера | Нормализация форматов логов |
| **Ambassador** | Проксировать трафик к правильному бэкенду | Маршрутизация к Dev/Test/Prod БД |

**Главные правила:**
- Контейнеры в поде общаются через `localhost` — никакой дополнительной сетевой настройки
- Все контейнеры стартуют и останавливаются вместе
- Общие тома позволяют контейнерам обмениваться данными через файловую систему
- Для добавления контейнера — просто добавить ещё один элемент в массив `containers`

### Init Containers

| Ситуация | Что делать |
|----------|-----------|
| Нужно выполнить подготовку до старта основного приложения | Использовать init-контейнеры |
| Нужно дождаться доступности другого сервиса | Init-контейнер с циклом проверки |
| Pod в статусе `Init:CrashLoopBackOff` | Искать опечатки или логические ошибки в команде init-контейнера |
| Нужно обновить init-контейнер | Экспорт в YAML → удаление пода → правка файла → apply |

**Важные моменты:**
- Init-контейнеры запускаются **строго последовательно**
- Провал любого init-контейнера = перезапуск всего пода
- Статус `Init:X/Y` показывает, сколько init-контейнеров уже выполнено из общего числа
- Нельзя изменить спецификацию init-контейнеров у запущенного пода — только пересоздать

---

# 4.0 - Наблюдаемость в Kubernetes: Полное руководство

## Содержание
1. Жизненный цикл пода
2. Readiness Probes (Пробы готовности)
3. Liveness Probes (Пробы живучести)
4. Практический пример настройки проб
5. Логирование
6. Мониторинг

---

## 1. Жизненный цикл пода

Прежде чем разбираться с пробами, важно понять, через какие состояния проходит под в Kubernetes.

### Стадии жизненного цикла

**Pending (Ожидание)**

Когда под только создаётся, он попадает в состояние `Pending`. На этой стадии планировщик Kubernetes (scheduler) ищет подходящий узел (node) для размещения пода. Если свободных узлов нет — под так и остаётся в состоянии ожидания. Чтобы выяснить причину задержки, используют команду:

```bash
kubectl describe pod <имя-пода>
```

**ContainerCreating (Создание контейнера)**

После того как планировщик выбрал узел, под переходит в состояние `ContainerCreating`. На этой стадии происходит скачивание образов (images) и запуск контейнеров.

**Running (Работает)**

Когда все контейнеры успешно запущены, под переходит в состояние `Running` и остаётся в нём до завершения работы приложения или принудительной остановки.

```bash
kubectl get pods
# NAME                        READY   STATUS    RESTARTS   AGE
# jenkins-566f687bf-c7nzf     1/1     Running   0          12m
# nginx-65899c769f-9lzh       1/1     Running   0          6h
# redis-b48685f8b-fbnmx       1/1     Running   0          6h
```

### Условия готовности пода (Pod Conditions)

Kubernetes отслеживает несколько условий (conditions), которые описывают состояние пода подробнее, чем просто статус:

| Условие | Описание |
|---|---|
| `PodScheduled` | Под назначен на узел |
| `Initialized` | Init-контейнеры завершили работу |
| `ContainersReady` | Все контейнеры готовы |
| `Ready` | Под готов принимать трафик |

Все эти условия можно увидеть через:

```bash
kubectl describe pod <имя-пода>
```

### Главная проблема: готовность пода ≠ готовность приложения

Здесь кроется ключевое противоречие. Kubernetes считает под готовым принимать трафик сразу, как только контейнер запустился. Но разные приложения требуют разного времени на инициализацию:

- Простой скрипт — готов за миллисекунды
- База данных — может потребоваться несколько секунд
- Jenkins-сервер — может потребоваться 10–15 секунд и более
- Сложный веб-сервер — может требовать минуты для полной загрузки

Без специальных проверок Kubernetes начнёт направлять трафик на под, который ещё не готов его обрабатывать. Именно для решения этой проблемы существуют **Readiness Probes**.

---

## 2. Readiness Probes — Пробы готовности

### Что такое Readiness Probe?

**Readiness Probe** — это механизм, позволяющий разработчику сообщить Kubernetes, когда приложение действительно готово принимать трафик. Пока проба не вернула успешный результат, Kubernetes не будет направлять на этот под никаких запросов.

### Три типа проб готовности

#### 1. HTTP GET Probe

Kubernetes отправляет HTTP GET запрос на указанный путь и порт. Если ответ — код в диапазоне 200–399, проба считается успешной.

```yaml
readinessProbe:
  httpGet:
    path: /api/ready
    port: 8080
```

**Когда использовать:** для веб-приложений и REST API, у которых есть эндпоинт проверки здоровья.

#### 2. TCP Socket Probe

Kubernetes пытается открыть TCP-соединение на указанный порт. Если соединение устанавливается — проба успешна.

```yaml
readinessProbe:
  tcpSocket:
    port: 3306
```

**Когда использовать:** для баз данных (MySQL, PostgreSQL) и других сервисов, которые не имеют HTTP-интерфейса, но слушают определённый порт.

#### 3. Exec Command Probe

Kubernetes выполняет указанную команду внутри контейнера. Если команда завершается с кодом выхода `0` — проба успешна.

```yaml
readinessProbe:
  exec:
    command:
      - cat
      - /app/is_ready
```

**Когда использовать:** для нестандартных случаев, когда ни HTTP, ни TCP не подходят — например, проверка наличия файла, статус внутреннего процесса и т.д.

### Параметры настройки проб

Помимо типа пробы, можно задать дополнительные параметры:

```yaml
readinessProbe:
  httpGet:
    path: /api/ready
    port: 8080
  initialDelaySeconds: 10   # Ждать 10 секунд перед первой проверкой
  periodSeconds: 5           # Проверять каждые 5 секунд
  failureThreshold: 8        # После 8 неудач — считать под не готовым
```

**`initialDelaySeconds`** — задержка перед первой проверкой. Нужна, чтобы дать приложению время на старт. Если не задать — Kubernetes начнёт проверять под немедленно, и первые несколько проверок будут неизбежно неудачными.

**`periodSeconds`** — интервал между проверками. По умолчанию — 10 секунд.

**`failureThreshold`** — сколько неудачных проверок подряд допустимо перед тем, как под пометить как "не готов". По умолчанию — 3.

### Полный пример конфигурации пода с Readiness Probe

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: simple-webapp
  labels:
    name: simple-webapp
spec:
  containers:
  - name: simple-webapp
    image: simple-webapp
    ports:
    - containerPort: 8080
    readinessProbe:
      httpGet:
        path: /api/ready
        port: 8080
      initialDelaySeconds: 10
      periodSeconds: 5
      failureThreshold: 8
```

**Что произойдёт:** Kubernetes подождёт 10 секунд, затем каждые 5 секунд будет отправлять GET-запрос на `http://<pod-ip>:8080/api/ready`. Только когда запрос вернёт успешный ответ, под получит статус Ready и начнёт принимать трафик. Если подряд 8 раз придёт неудача — под будет помечен как не готовый.

### Readiness Probe в многоподовом окружении

Особенно важна роль Readiness Probe при масштабировании. Представьте ситуацию:

- Работает один под, обслуживающий все запросы
- Вы масштабируете Deployment, добавляется второй под
- Второй под запустился, но приложению нужна ещё минута для инициализации
- **Без Readiness Probe:** Kubernetes сразу начинает направлять половину трафика на не готовый под → пользователи получают ошибки
- **С Readiness Probe:** Kubernetes ждёт, пока второй под пройдёт проверку, и только потом включает его в балансировку трафика

**Вывод по Readiness Probe:** этот механизм защищает пользователей от получения ошибок в момент старта новых подов. Он обеспечивает плавное масштабирование и обновление приложений.

---

## 3. Liveness Probes — Пробы живучести

### Проблема, которую решает Liveness Probe

Readiness Probe решает задачу "готов ли под принимать трафик". Но есть другая проблема: что если приложение запущено, работает, но "зависло"? Например:

- Приложение попало в бесконечный цикл из-за ошибки
- Произошла взаимная блокировка (deadlock)
- Приложение перестало отвечать на запросы, но процесс ещё "жив"

В таком случае Kubernetes видит, что процесс запущен, и ничего не предпринимает. Под висит "живым", но фактически бесполезным.

### Сравнение поведения Docker и Kubernetes при сбоях

**В Docker:** если контейнер упал — он остановился и никто его не перезапустит автоматически.

```bash
docker run nginx
# Если nginx упал:
docker ps -a
# CONTAINER ID   IMAGE   STATUS
# 45aacca36850   nginx   Exited (1) 41 seconds ago
# Контейнер мёртв и никто его не поднимет
```

**В Kubernetes:** при падении контейнера kubelet автоматически его перезапускает. Можно это увидеть в счётчике `RESTARTS`:

```bash
kubectl get pods
# NAME       READY   STATUS    RESTARTS   AGE
# nginx-pod  0/1     Running   2          1d
#                              ^--- два перезапуска
```

Но Kubernetes перезапустит контейнер только если процесс реально завершился. Если процесс завис — он не завершился, и Kubernetes ничего не сделает. Именно здесь нужен **Liveness Probe**.

### Что такое Liveness Probe?

**Liveness Probe** — это периодическая проверка состояния контейнера. Если проба завершается неудачей — Kubernetes считает контейнер "мёртвым" и пересоздаёт его, даже если процесс формально ещё работает.

Разработчик сам определяет, что значит "здоровый" для его приложения:

- Для веб-сервиса: API отвечает на запросы
- Для базы данных: TCP-порт открыт
- Для специфичных задач: выполнение кастомной команды

### Три типа Liveness Probe

Синтаксис аналогичен Readiness Probe, только ключевое слово — `livenessProbe`.

#### 1. HTTP GET

```yaml
livenessProbe:
  httpGet:
    path: /api/healthy
    port: 8080
```

#### 2. TCP Socket

```yaml
livenessProbe:
  tcpSocket:
    port: 3306
```

#### 3. Exec Command

```yaml
livenessProbe:
  exec:
    command:
      - cat
      - /app/is_healthy
```

### Полный пример конфигурации с Liveness Probe

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: simple-webapp
  labels:
    name: simple-webapp
spec:
  containers:
    - name: simple-webapp
      image: simple-webapp
      ports:
        - containerPort: 8080
      livenessProbe:
        httpGet:
          path: /api/healthy
          port: 8080
        initialDelaySeconds: 10
        periodSeconds: 5
        failureThreshold: 8
```

**Что произойдёт:** каждые 5 секунд Kubernetes будет проверять `/api/healthy`. Если 8 раз подряд проверка не пройдёт (например, приложение зависло и не отвечает) — Kubernetes убьёт контейнер и пересоздаст его.

### Важное предупреждение о Liveness Probe

Неправильно настроенная Liveness Probe может стать источником проблем:

- Если `initialDelaySeconds` слишком мал — Kubernetes начнёт убивать под ещё во время его инициализации
- Если `failureThreshold` слишком мал — временный сбой в сети или кратковременная нагрузка приведут к лишним перезапускам
- Цикличные перезапуски (CrashLoopBackOff) ухудшают производительность и затрудняют диагностику

**Правило:** Liveness Probe должна проверять именно то, что критично для работы приложения. Не стоит делать её слишком строгой.

---

## 4. Практический пример — настройка обеих проб

Рассмотрим реальный сценарий из практики, демонстрирующий, как обе пробы работают вместе.

### Шаг 1: Начальное состояние

Есть один работающий под `simple-webapp-1`. Тест-скрипт подтверждает — всё работает:

```bash
./curl-test.sh
# Message from simple-webapp-1 : I am ready! OK
# Message from simple-webapp-1 : I am ready! OK
# ... (всё хорошо)
```

### Шаг 2: Добавление второго пода без Readiness Probe

Добавляем `simple-webapp-2` без каких-либо проб. Результат:

```bash
./curl-test.sh
# Message from simple-webapp-1 : I am ready! OK
# Message from simple-webapp-1 : I am ready! OK
# Failed         <--- запрос попал на не готовый pod 2
# Failed
# Message from simple-webapp-1 : I am ready! OK
# Failed
```

Kubernetes уже направляет трафик на второй под, хотя тот ещё не готов.

### Шаг 3: Добавление Readiness Probe ко второму поду

```bash
# Экспортируем конфиг пода
kubectl get pod simple-webapp-2 -o yaml > webapp2.yaml

# Удаляем под
kubectl delete pod simple-webapp-2
```

Редактируем `webapp2.yaml`, добавляем:

```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
```

Применяем:

```bash
kubectl apply -f webapp2.yaml
```

Теперь результат теста:

```bash
./curl-test.sh
# Message from simple-webapp-1 : I am ready! OK (pod 2 ещё не готов)
# Message from simple-webapp-1 : I am ready! OK
# ...
# Message from simple-webapp-2 : I am ready! OK (pod 2 прошёл пробу!)
# Message from simple-webapp-1 : I am ready! OK (балансировка работает)
```

### Шаг 4: Симуляция падения пода

```bash
./crash-app.sh
# Message from simple-webapp-2 : Mayday! Mayday! Going to crash!
```

Kubernetes автоматически перезапустит под. Пока второй под недоступен — весь трафик идёт на первый.

### Шаг 5: Добавление Liveness Probe для защиты от зависания

Если под зависает (не отвечает, но и не падает) — только Liveness Probe поможет. Добавляем обоим подам:

```yaml
livenessProbe:
  httpGet:
    path: /live
    port: 8080
  periodSeconds: 1
  initialDelaySeconds: 80
```

`initialDelaySeconds: 80` — даём приложению время на старт, только потом начинаем проверять.

Итоговая конфигурация пода с обеими пробами:

```yaml
spec:
  containers:
  - image: kodekloud/webapp-delayed-start
    name: simple-webapp
    ports:
    - containerPort: 8080
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      periodSeconds: 10
      failureThreshold: 3
    livenessProbe:
      httpGet:
        path: /live
        port: 8080
      periodSeconds: 1
      initialDelaySeconds: 80
```

После симуляции зависания:

```bash
./freeze-app.sh
# Под завис...

kubectl get pod
# Kubernetes обнаружил, что /live не отвечает
# Контейнер пересоздан автоматически
```

**Итоговая разница между пробами:**

| | Readiness Probe | Liveness Probe |
|---|---|---|
| **Цель** | Под готов принимать трафик? | Приложение живо и не зависло? |
| **При неудаче** | Под исключается из балансировки | Контейнер перезапускается |
| **Процесс не убивается** | ✓ (под просто не получает трафик) | ✗ (контейнер убивается) |
| **Типичный сценарий** | Медленная инициализация | Зависшее приложение |

---

## 5. Логирование

### Логирование в Docker

Контейнер пишет логи в стандартный вывод (stdout). При запуске в foreground-режиме они видны сразу:

```bash
docker run kodekloud/event-simulator
# 2018-10-06 15:57:15,937 - root - INFO - USER1 logged in
# 2018-10-06 15:57:16,943 - root - INFO - USER2 logged out
# ...
```

При запуске в фоновом режиме (`-d`):

```bash
docker run -d kodekloud/event-simulator
# <container_id>

docker logs <container_id>
# Логи доступны по запросу
```

### Логирование в Kubernetes

В Kubernetes логи контейнера просматриваются через `kubectl logs`. Флаг `-f` включает режим "следить за логами в реальном времени" (аналог `tail -f`):

```bash
kubectl create -f event-simulator.yaml
kubectl logs -f event-simulator-pod
# 2018-10-06 15:57:15,937 - root - INFO - USER1 logged in
# 2018-10-06 15:57:16,943 - root - INFO - USER2 logged out
# ...
```

Пример pod-файла:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: event-simulator-pod
spec:
  containers:
    - name: event-simulator
      image: kodekloud/event-simulator
```

### Логирование в поде с несколькими контейнерами

Если под содержит несколько контейнеров — нужно явно указать имя контейнера, иначе команда завершится ошибкой:

```yaml
spec:
  containers:
    - name: event-simulator
      image: kodekloud/event-simulator
    - name: image-processor
      image: some-image-processor
```

```bash
# Ошибка — Kubernetes не знает, какой контейнер имеется в виду:
kubectl logs -f event-simulator-pod
# error: a container name must be specified for pod event-simulator-pod,
# choose one of: [event-simulator image-processor]

# Правильно — указываем имя контейнера:
kubectl logs -f event-simulator-pod event-simulator
```

### Практический пример: диагностика по логам

**Сценарий 1:** Пользователь USER5 не может войти в систему.

```bash
kubectl logs webapp-1
# WARNING: USER5 Failed to Login as the account is locked due to MANY FAILED ATTEMPTS.
# WARNING: USER5 Failed to Login as the account is locked due to MANY FAILED ATTEMPTS.
```

**Вывод:** аккаунт заблокирован из-за множества неудачных попыток входа. Логи позволили мгновенно диагностировать проблему.

**Сценарий 2:** Под с двумя контейнерами, пользователь сообщает об ошибке при покупке.

```bash
kubectl logs webapp-2
# error: a container name must be specified for pod webapp-2,
# choose one of: [simple-webapp db]

kubectl logs webapp-2 simple-webapp
# WARNING: USER30 Order failed as the item is OUT OF STOCK.
```

**Вывод:** товар отсутствует на складе. Нужно было указать имя контейнера, так как в поде их два.

---

## 6. Мониторинг

### Зачем мониторить Kubernetes?

Мониторинг позволяет отслеживать здоровье и производительность кластера. Ключевые метрики:

**На уровне узлов (nodes):**
- Количество узлов и их статус
- Потребление CPU, памяти, сети, дискового пространства

**На уровне подов (pods):**
- Количество запущенных подов
- Потребление CPU и памяти каждым подом

### Инструменты мониторинга

Kubernetes не включает полноценную систему мониторинга "из коробки". Доступны:

- **Metrics Server** — лёгкое in-memory решение для базового мониторинга
- **Prometheus** — мощная open-source система с хранением истории
- **Elastic Stack** — для централизованного логирования и метрик
- **Datadog, Dynatrace** — коммерческие решения

В рамках базового курса рассматривается **Metrics Server**.

### Как работает Metrics Server

На каждом узле кластера работает компонент **kubelet**, управляющий подами. В составе kubelet есть **cAdvisor (Container Advisor)** — он собирает метрики производительности из контейнеров и передаёт их Metrics Server через API kubelet.

**Важное ограничение:** Metrics Server хранит данные только в памяти. Он не сохраняет историю. Для анализа тенденций во времени нужны Prometheus или другие решения.

### Установка Metrics Server

**Для Minikube:**

```bash
minikube addons enable metrics-server
```

**Для других окружений:**

```bash
git clone https://github.com/kubernetes-incubator/metrics-server.git
kubectl create -f deploy/1.8+/
```

После выполнения будут созданы необходимые роли, сервисные аккаунты и деплойменты.

### Просмотр метрик

**Метрики узлов:**

```bash
kubectl top node
# NAME          CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
# kubemaster    166          8%     1337Mi          70%
# kubnode1      36           1%     1046Mi          55%
# kubnode2      39           1%     1048Mi          55%
```

**Метрики подов:**

```bash
kubectl top pod
# NAME       CPU(cores)   MEMORY(bytes)
# elephant   20m          32Mi
# lion       1m           18Mi
# rabbit     131m         252Mi
```

### Анализ метрик

Из примера выше можно сделать выводы:

- **Больше всего CPU потребляет:** `rabbit` — 131 мilli-core
- **Больше всего памяти потребляет:** `rabbit` — 252Mi
- **Меньше всего CPU потребляет:** `lion` — всего 1 milli-core
- **Меньше всего памяти потребляет:** `lion` — 18Mi

Под `rabbit` явно требует внимания — его потребление ресурсов в разы выше остальных. Это может свидетельствовать о проблеме или некорректных лимитах ресурсов.

---

## Итоговые выводы

**Readiness Probe** защищает пользователей от ошибок в момент запуска или масштабирования: под получает трафик только тогда, когда приложение действительно к этому готово.

**Liveness Probe** обеспечивает автоматическое восстановление зависших приложений: если под "завис" и не отвечает, Kubernetes сам пересоздаёт контейнер без ручного вмешательства.

**Логирование** через `kubectl logs` — первый инструмент диагностики. При нескольких контейнерах в поде всегда указывайте имя контейнера.

**Мониторинг** через Metrics Server даёт быстрый обзор потребления ресурсов, но не хранит историю. Для серьёзной эксплуатации нужны дополнительные инструменты.

Все эти инструменты вместе формируют фундамент **наблюдаемости (observability)** — способности понимать, что происходит внутри вашего кластера в любой момент времени.

---

# 5.1 - Kubernetes: Labels, Selectors, Annotations, Rolling Updates и Rollbacks

Полный разбор тем из документации KodeKloud на русском языке.

---

## Часть 1: Labels (Метки) и Selectors (Селекторы)

### Что такое Labels и зачем они нужны?

Представьте, что вы управляете огромным складом с тысячами товаров. Чтобы быстро найти нужный товар, вы клеите на каждый из них ярлыки: «электроника», «красный», «хрупкий», «срочно». Именно так работают **Labels** в Kubernetes.

**Label (метка)** — это пара «ключ: значение», которая прикрепляется к любому объекту Kubernetes: Pod, Service, ReplicaSet, Deployment и т.д. Метки не влияют на поведение самих объектов — они служат исключительно для организации и идентификации.

**Selector (селектор)** — это механизм фильтрации, который позволяет выбирать объекты по их меткам.

### Аналогии для понимания

- **Интернет-магазин**: фильтры «цвет: красный», «размер: XL», «бренд: Nike» — это Labels. Когда вы применяете фильтр, вы используете Selector.
- **YouTube**: теги видео — это Labels. Поиск по тегу — это Selector.
- **Зоомагазин**: у каждого животного есть свойства «вид: птица», «цвет: зелёный», «размер: маленький». Фраза «покажи мне всех зелёных птиц» — это Selector.

### Почему это критически важно в Kubernetes?

В реальных кластерах могут работать **сотни и тысячи объектов** одновременно:
- Pods разных приложений
- Services для разных окружений
- ReplicaSets для разных версий
- Deployments для разных команд

Без системы организации найти нужный объект среди тысячи других практически невозможно. Labels и Selectors решают эту задачу элегантно и эффективно.

---

### Как задать Labels в манифесте?

Labels указываются в секции `metadata` любого Kubernetes-объекта:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: simple-webapp
  labels:
    app: App1               # ключ: значение
    function: Front-end     # ещё одна метка
    environment: production # можно добавлять сколько угодно
    version: "2.1"
    team: backend
spec:
  containers:
  - name: simple-webapp
    image: simple-webapp
    ports:
    - containerPort: 8080
```

**Правила именования:**
- Ключ может содержать префикс и имя: `app.kubernetes.io/name`
- Значение: строка до 63 символов
- Допустимы буквы, цифры, дефис, подчёркивание, точка
- Значение может быть пустым

### Как фильтровать объекты по Labels?

```bash
# Получить все Pods с меткой app=App1
kubectl get pods --selector app=App1

# Несколько условий (логическое И)
kubectl get pods --selector app=App1,environment=production

# Сокращённый синтаксис -l вместо --selector
kubectl get pods -l app=App1

# Посмотреть метки всех Pods
kubectl get pods --show-labels

# Получить все объекты (не только Pods) в определённом окружении
kubectl get all --selector env=prod
```

**Пример вывода команды `kubectl get pods --selector app=App1`:**
```
NAME            READY   STATUS      RESTARTS   AGE
simple-webapp   0/1     Completed   0          1d
```

---

### Практические примеры фильтрации

Допустим, у нас есть следующие Pods в кластере с разными метками:

| Pod | env | bu | tier |
|-----|-----|----|------|
| pod-1 | dev | finance | frontend |
| pod-2 | dev | finance | backend |
| pod-3 | prod | finance | frontend |
| pod-4 | prod | hr | backend |
| pod-5 | dev | hr | frontend |
| pod-6 | prod | marketing | frontend |
| pod-7 | dev | finance | frontend |

**Посчитать Pods в окружении dev:**
```bash
kubectl get pods --selector env=dev --no-headers | wc -l
# Результат: 4 (pod-1, pod-2, pod-5, pod-7)
```

**Посчитать Pods в финансовом подразделении:**
```bash
kubectl get pods --selector bu=finance --no-headers | wc -l
# Результат: 4 (pod-1, pod-2, pod-3, pod-7)
```

**Найти конкретный Pod (prod + finance + frontend):**
```bash
kubectl get pods --selector env=prod,bu=finance,tier=frontend
# Результат: pod-3
```

**Подсчитать ВСЕ объекты в prod (не только Pods):**
```bash
kubectl get all --selector env=prod --no-headers | wc -l
```

---

## Часть 2: Labels и Selectors в ReplicaSet

Вот где начинается самое интересное — и самое частое место для ошибок у начинающих.

### Как ReplicaSet использует Labels?

ReplicaSet использует Labels для определения того, **какими Pods он управляет**. Это связь между объектами в Kubernetes.

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: simple-webapp
  labels:              # <-- Метки САМОГО ReplicaSet
    app: App1
    function: Front-end
  annotations:
    buildversion: "1.34"
spec:
  replicas: 3
  selector:            # <-- КАК ReplicaSet ищет свои Pods
    matchLabels:
      app: App1        # ReplicaSet управляет Pods с меткой app=App1
  template:            # <-- Шаблон для создания Pods
    metadata:
      labels:          # <-- Метки PODS, которые создаёт ReplicaSet
        app: App1
        function: Front-end
    spec:
      containers:
      - name: simple-webapp
        image: simple-webapp
```

### Три уровня Labels в ReplicaSet — разбираем по частям

**Уровень 1: `metadata.labels` ReplicaSet**
```yaml
metadata:
  name: simple-webapp
  labels:
    app: App1           # Описывает сам объект ReplicaSet
    function: Front-end # Используется, если другой объект ищет этот ReplicaSet
```
Эти метки описывают **сам ReplicaSet** как объект. Если, например, какой-то инструмент мониторинга ищет все ReplicaSet'ы с определённой функцией, он будет использовать эти метки.

**Уровень 2: `spec.selector.matchLabels`**
```yaml
spec:
  selector:
    matchLabels:
      app: App1   # «Я управляю Pods с меткой app=App1»
```
Это «инструкция поиска» для ReplicaSet. Он постоянно мониторит кластер и считает, сколько Pods соответствует этому условию. Если их меньше, чем `replicas` — создаёт новые. Если больше — удаляет лишние.

**Уровень 3: `spec.template.metadata.labels`**
```yaml
  template:
    metadata:
      labels:
        app: App1           # Эти метки будут у созданных Pods
        function: Front-end
```
Это метки, которые ReplicaSet **присваивает Pod'ам при создании**. Они ДОЛЖНЫ совпадать с `selector.matchLabels`, иначе ReplicaSet будет создавать Pods, которые сам же не сможет найти!

### Критическая ошибка: несовпадение selector и template labels

Это самая частая ошибка начинающих:

```yaml
# НЕПРАВИЛЬНО — вызовет ошибку!
spec:
  selector:
    matchLabels:
      tier: front-end   # Ищем Pods с tier=front-end
  template:
    metadata:
      labels:
        tier: nginx      # Но создаём Pods с tier=nginx
```

Kubernetes немедленно откажет в создании такого ReplicaSet с ошибкой:
```
The ReplicaSet "replicaset-1" is invalid: 
spec.template.metadata.labels: Invalid value: 
map[string]string{"tier":"nginx"}: 
selector does not match template labels
```

**Правильный вариант:**
```yaml
# ПРАВИЛЬНО — selector и template labels совпадают
spec:
  selector:
    matchLabels:
      tier: front-end
  template:
    metadata:
      labels:
        tier: front-end  # Совпадает с selector!
```

### Зачем добавлять несколько Labels для точного контроля?

Представьте ситуацию: у вас есть два разных приложения, оба с меткой `env: production`. Если ReplicaSet первого приложения использует только `env: production` как selector, он может случайно «захватить» Pods второго приложения!

**Решение — добавить уточняющие метки:**
```yaml
selector:
  matchLabels:
    app: App1           # Сужаем до конкретного приложения
    env: production     # И конкретного окружения
    version: "2.0"      # Можно добавить ещё больше условий
```

---

## Часть 3: Annotations (Аннотации)

### Чем Annotations отличаются от Labels?

| Характеристика | Labels | Annotations |
|----------------|--------|-------------|
| Используются для выборки | ✅ Да | ❌ Нет |
| Видны в selector | ✅ Да | ❌ Нет |
| Влияют на связи объектов | ✅ Да | ❌ Нет |
| Могут содержать длинные значения | ❌ Ограничены | ✅ Да |
| Назначение | Группировка/выборка | Метаданные/информация |

**Annotations** — это место для хранения произвольной информации об объекте, которая **не влияет на логику Kubernetes**, но полезна для людей или внешних инструментов.

### Примеры использования Annotations

```yaml
metadata:
  name: simple-webapp
  annotations:
    buildversion: "1.34"                          # Версия сборки
    build-date: "2024-01-15T10:30:00Z"            # Дата сборки
    git-commit: "a1b2c3d4e5f6"                    # Хэш коммита
    git-branch: "main"                            # Ветка
    owner: "team-backend@company.com"             # Ответственная команда
    description: "Основной веб-сервер приложения" # Описание
    prometheus.io/scrape: "true"                  # Для интеграции с Prometheus
    prometheus.io/port: "8080"                    # Порт метрик
    kubectl.kubernetes.io/last-applied-configuration: "..." # Kubectl использует это сам
```

### Реальные сценарии использования Annotations

1. **CI/CD системы**: Jenkins, GitLab CI добавляют в аннотации ID пайплайна, номер билда, ссылку на логи
2. **Мониторинг**: Prometheus, Datadog читают аннотации, чтобы понять, как собирать метрики с Pod'а
3. **Ingress контроллеры**: nginx-ingress использует аннотации для настройки маршрутизации
4. **Service Mesh**: Istio читает аннотации для управления трафиком
5. **Аудит**: кто и когда изменил объект, какая версия была задеплоена

```yaml
# Пример аннотаций для Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/rate-limit: "100"
```

---

## Часть 4: Rolling Updates (Постепенное обновление)

### Концепция Rollout и Revision

Когда вы создаёте Deployment, Kubernetes запускает первый **rollout** и создаёт **Revision 1**. При каждом обновлении (изменение образа, переменных окружения, ресурсов) создаётся новый rollout и новая **Revision**.

```
Revision 1: nginx:1.7.0  →  Revision 2: nginx:1.7.1  →  Revision 3: nginx:1.9.1
```

Это позволяет:
- Отслеживать историю изменений
- Откатиться к любой предыдущей версии
- Понять, что именно и когда изменилось

**Команды для работы с rollout:**

```bash
# Посмотреть статус текущего rollout
kubectl rollout status deployment/myapp-deployment

# Посмотреть историю всех revision
kubectl rollout history deployment/myapp-deployment
```

**Пример вывода `kubectl rollout status`:**
```
Waiting for rollout to finish: 0 of 10 updated replicas are available...
Waiting for rollout to finish: 1 of 10 updated replicas are available...
...
Waiting for rollout to finish: 9 of 10 updated replicas are available...
deployment "myapp-deployment" successfully rolled out
```

---

### Стратегия 1: Recreate (Пересоздание)

```
[Pod v1] [Pod v1] [Pod v1] [Pod v1] [Pod v1]
         ↓ ВСЕ УДАЛЯЮТСЯ ОДНОВРЕМЕННО
[      ] [      ] [      ] [      ] [      ]  ← ДАУНТАЙМ!
         ↓ ВСЕ СОЗДАЮТСЯ ЗАНОВО
[Pod v2] [Pod v2] [Pod v2] [Pod v2] [Pod v2]
```

**Алгоритм:**
1. Kubernetes останавливает **все** Pod'ы старой версии
2. Ждёт, пока все они завершатся
3. Создаёт **все** Pod'ы новой версии

**Недостаток:** В период между шагами 1 и 3 приложение **полностью недоступно**.

**Когда использовать:**
- При разработке/тестировании, где даунтайм допустим
- Когда новая версия несовместима со старой и обе не могут работать параллельно
- Когда нужно гарантированно перезапустить все Pod'ы (например, для подхвата новых ConfigMap)

**Настройка в манифесте:**
```yaml
spec:
  strategy:
    type: Recreate
```

---

### Стратегия 2: Rolling Update (Постепенное обновление)

```
Начало:
[Pod v1] [Pod v1] [Pod v1] [Pod v1]

Шаг 1:
[Pod v2] [Pod v1] [Pod v1] [Pod v1]  ← заменили 1

Шаг 2:
[Pod v2] [Pod v2] [Pod v1] [Pod v1]  ← заменили 2

Шаг 3:
[Pod v2] [Pod v2] [Pod v2] [Pod v1]  ← заменили 3

Конец:
[Pod v2] [Pod v2] [Pod v2] [Pod v2]  ← всё обновлено
```

**Это стратегия по умолчанию в Kubernetes.**

**Ключевые параметры:**
- `maxUnavailable` — максимальный процент недоступных Pod'ов в процессе обновления (по умолчанию 25%)
- `maxSurge` — максимальный процент Pod'ов сверх желаемого числа (по умолчанию 25%)

**Полная настройка в манифесте:**
```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 25%   # или абсолютное число: 1
      maxSurge: 25%         # или абсолютное число: 1
```

**Как это работает с цифрами** (4 реплики, 25% maxUnavailable, 25% maxSurge):
- Желаемых Pod'ов: 4
- Максимально недоступных: 1 (25% от 4)
- Максимально Pod'ов сверх лимита: 1 (25% от 4)
- Значит, в процессе обновления может быть от 3 до 5 Pod'ов

---

### Как обновить Deployment?

**Способ 1: Изменить YAML-файл и применить**
```bash
# Редактируем deployment-definition.yml, меняем image
kubectl apply -f deployment-definition.yml
```

**Способ 2: Обновить образ командой**
```bash
kubectl set image deployment/myapp-deployment nginx-container=nginx:1.9.1
#                                              ^ имя контейнера   ^ новый образ
```

⚠️ **Важно:** `kubectl set image` изменяет конфигурацию в кластере, но **не изменяет ваш YAML-файл**. Они становятся рассинхронизированы! Всегда обновляйте файл вручную после такой команды.

**Способ 3: Редактировать напрямую**
```bash
kubectl edit deployment myapp-deployment
# Откроется редактор, изменения применятся сразу после сохранения
```

### Пример: обновление реального приложения

Допустим, у нас есть Deployment с приложением `kodekloud/webapp-color:v1` (синий цвет).

```bash
# Проверяем текущее состояние
kubectl get deployments
# NAME       READY   UP-TO-DATE   AVAILABLE   AGE
# frontend   4/4     4            4           2m41s

# Смотрим детали
kubectl describe deploy frontend
# Image: kodekloud/web-app-color:v1
# StrategyType: RollingUpdate

# Обновляем до v2 (зелёный цвет)
kubectl set image deploy frontend simple-webapp=kodekloud/webapp-color:v2

# Наблюдаем за процессом — видим смесь v1 и v2
# Hello, Application Version: v1 ; Color: blue OK
# Hello, Application Version: v2 ; Color: green OK
# Hello, Application Version: v1 ; Color: blue OK
# Hello, Application Version: v2 ; Color: green OK

# После завершения rollout — только v2
# Hello, Application Version: v2 ; Color: green OK
# Hello, Application Version: v2 ; Color: green OK
```

---

### Что происходит «под капотом» при Rolling Update?

При создании Deployment Kubernetes создаёт **ReplicaSet v1** с нужным числом Pod'ов.

При обновлении:
1. Kubernetes создаёт **новый ReplicaSet v2** с 0 Pod'ами
2. Постепенно увеличивает число Pod'ов в ReplicaSet v2
3. Одновременно уменьшает число Pod'ов в ReplicaSet v1
4. Продолжает до тех пор, пока ReplicaSet v1 не станет 0, а ReplicaSet v2 — не достигнет желаемого числа

```bash
kubectl get replicasets
# В процессе обновления:
# NAME                        DESIRED   CURRENT   READY   AGE
# myapp-deployment-67c749c58c  2         2         2       10m  ← старый, уменьшается
# myapp-deployment-7d57dbd8d   3         3         3       2m   ← новый, растёт

# После завершения:
# NAME                        DESIRED   CURRENT   READY   AGE
# myapp-deployment-67c749c58c  0         0         0       12m  ← старый, пустой
# myapp-deployment-7d57dbd8d   5         5         5       4m   ← новый, полный
```

Старый ReplicaSet **не удаляется** — он сохраняется для возможного отката!

---

## Часть 5: Rollback (Откат)

### Когда нужен откат?

- Новая версия приложения содержит критический баг
- Производительность резко упала
- Ошибки в конфигурации
- Зависимые сервисы не совместимы с новой версией

### Как выполнить откат?

```bash
# Откат к предыдущей версии
kubectl rollout undo deployment/myapp-deployment

# Откат к конкретной revision
kubectl rollout undo deployment/myapp-deployment --to-revision=1

# Посмотреть историю revision перед откатом
kubectl rollout history deployment/myapp-deployment
```

**Что происходит при откате:**

До отката:
```
ReplicaSet v1 (старый):  DESIRED=0,  CURRENT=0,  READY=0
ReplicaSet v2 (новый):   DESIRED=5,  CURRENT=5,  READY=5
```

После отката:
```
ReplicaSet v1 (старый):  DESIRED=5,  CURRENT=5,  READY=5
ReplicaSet v2 (новый):   DESIRED=0,  CURRENT=0,  READY=0
```

Kubernetes просто «разворачивает» процесс: уменьшает Pod'ы в новом ReplicaSet и увеличивает в старом. Тот же механизм rolling update, только в обратном направлении.

```bash
kubectl rollout undo deployment/myapp-deployment
# deployment "myapp-deployment" rolled back
```

---

## Часть 6: Детальный разбор `kubectl describe deployment`

Вывод этой команды содержит критически важную информацию:

### При стратегии Recreate:
```
StrategyType:          Recreate
Events:
  Normal  ScalingReplicaSet  11m  deployment-controller  Scaled up replicaset-OLD to 5
  Normal  ScalingReplicaSet  1m   deployment-controller  Scaled down replicaset-OLD to 0  ← сначала всё удалено
  Normal  ScalingReplicaSet  56s  deployment-controller  Scaled up replicaset-NEW to 5    ← потом всё создано
```

### При стратегии Rolling Update:
```
StrategyType:          RollingUpdate
RollingUpdateStrategy: 25% max unavailable, 25% max surge
Events:
  Normal  ScalingReplicaSet  1m   deployment-controller  Scaled up replicaset-OLD to 5
  Normal  ScalingReplicaSet  15s  deployment-controller  Scaled down replicaset-OLD to 4  ← постепенно
  Normal  ScalingReplicaSet  0s   deployment-controller  Scaled up replicaset-NEW to 3    ← постепенно
  Normal  ScalingReplicaSet  0s   deployment-controller  Scaled down replicaset-OLD to 0  ← завершение
```

---

## Сводная таблица команд

| Задача | Команда |
|--------|---------|
| Фильтр Pods по метке | `kubectl get pods --selector app=App1` |
| Фильтр с несколькими метками | `kubectl get pods -l env=prod,bu=finance` |
| Фильтр всех объектов | `kubectl get all --selector env=prod` |
| Показать метки | `kubectl get pods --show-labels` |
| Подсчёт с фильтром | `kubectl get pods --selector env=dev --no-headers \| wc -l` |
| Создать Deployment | `kubectl create -f deployment-definition.yml` |
| Применить изменения | `kubectl apply -f deployment-definition.yml` |
| Обновить образ | `kubectl set image deployment/myapp nginx=nginx:1.9.1` |
| Статус rollout | `kubectl rollout status deployment/myapp` |
| История rollout | `kubectl rollout history deployment/myapp` |
| Откат | `kubectl rollout undo deployment/myapp` |
| Откат к версии N | `kubectl rollout undo deployment/myapp --to-revision=2` |
| Описание Deployment | `kubectl describe deployment myapp` |
| Список ReplicaSet'ов | `kubectl get replicasets` |

---

## Выводы и ключевые принципы

### По Labels и Selectors:
1. **Labels** — это ярлыки на объектах, **Selectors** — фильтры для поиска объектов по этим ярлыкам
2. В ReplicaSet есть **три разных места** для меток, и их нельзя путать: метки ReplicaSet, selector и метки Pod-шаблона
3. Метки в `spec.selector.matchLabels` и `spec.template.metadata.labels` **обязаны совпадать** — это критическое требование
4. Чем больше меток в selector, тем точнее выборка и меньше риск случайно захватить чужие Pods
5. Для подсчёта объектов используйте `--no-headers | wc -l`

### По Annotations:
1. Annotations **не влияют на логику Kubernetes** — они только для людей и внешних инструментов
2. Annotations могут содержать длинные значения и произвольный текст
3. Используйте аннотации для CI/CD метаданных, мониторинга, документации

### По Rolling Updates:
1. **Rolling Update — стратегия по умолчанию**, она обеспечивает нулевой даунтайм
2. **Recreate** проще, но вызывает даунтайм — используйте только когда он допустим или необходим
3. `kubectl set image` быстрый, но **не обновляет YAML-файл** — не забывайте синхронизировать
4. Старые ReplicaSet'ы **сохраняются** после обновления — именно для откатов
5. **Rollback** — это тот же rolling update, только в обратную сторону
6. Всегда следите за статусом через `kubectl rollout status` и `kubectl describe deployment`

---

# 5.2 - Kubernetes: Blue-Green, Canary, Jobs и CronJobs

Полный разбор тем из документации KodeKloud на русском языке.

---

## Часть 1: Blue-Green Deployment (Сине-зелёное развёртывание)

### Контекст: что было раньше?

Прежде чем разбирать Blue-Green, вспомним уже известные стратегии:

- **Recreate** — всё старое удаляется, потом поднимается новое. Есть даунтайм.
- **Rolling Update** — постепенная замена Pod'ов по одному. Даунтайма нет, но в какой-то момент работают обе версии одновременно.

Blue-Green — принципиально иной подход, который решает проблему иначе.

---

### Что такое Blue-Green Deployment?

Представьте, что у вас есть два абсолютно одинаковых производственных стенда:

- **Blue (синий)** — текущая, стабильная версия. Сейчас на него идёт 100% пользовательского трафика.
- **Green (зелёный)** — новая версия, которую вы подготовили, задеплоили и тестируете в изоляции.

Пока вы тестируете Green, реальные пользователи ничего не замечают — они работают с Blue. Когда вы убедились, что новая версия работает корректно, вы одним действием переключаете весь трафик с Blue на Green.

```
До переключения:
Пользователи → [Service] → [Blue: Pod v1] [Pod v1] [Pod v1] [Pod v1] [Pod v1]
                                           [Green: Pod v2] [Pod v2] (тестируется)

После переключения:
Пользователи → [Service] → [Green: Pod v2] [Pod v2] [Pod v2] [Pod v2] [Pod v2]
                            [Blue: Pod v1] (простаивает, ждёт удаления)
```

---

### Как это реализуется в Kubernetes?

Ключевой механизм — **изменение selector в Kubernetes Service**. Service определяет, на какие Pod'ы направлять трафик, через selector. Изменив selector, мы мгновенно переключаем трафик.

**Шаг 1: Деплоим Blue (текущая версия)**

```yaml
# myapp-blue.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-blue
  labels:
    app: myapp
    type: front-end
spec:
  replicas: 5
  selector:
    matchLabels:
      version: v1      # ReplicaSet управляет Pod'ами с version=v1
  template:
    metadata:
      labels:
        version: v1    # Метка Pod'ов синей версии
    spec:
      containers:
        - name: app-container
          image: myapp-image:1.0
```

```yaml
# service-definition.yaml — направляет трафик на Blue
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    version: v1        # Трафик идёт на Pod'ы с version=v1 (Blue)
```

На этом этапе весь трафик идёт на синюю версию.

**Шаг 2: Деплоим Green (новая версия)**

```yaml
# myapp-green.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-green
  labels:
    app: myapp
    type: front-end
spec:
  replicas: 5
  selector:
    matchLabels:
      version: v2      # Отдельный ReplicaSet для зелёной версии
  template:
    metadata:
      labels:
        version: v2    # Метка Pod'ов зелёной версии
    spec:
      containers:
        - name: app-container
          image: myapp-image:2.0
```

После применения этого манифеста оба Deployment'а работают одновременно, но Service всё ещё отправляет трафик только на Blue (version: v1). Green полностью изолирован от пользователей.

**Шаг 3: Тестируем Green**

Пока Blue обслуживает пользователей, вы тестируете Green внутри кластера: автоматические тесты, ручная проверка, нагрузочное тестирование. Никаких рисков — пользователи ничего не знают.

**Шаг 4: Переключаем трафик**

Когда уверены, что Green работает корректно, меняем один-единственный параметр в Service:

```yaml
# service-definition.yaml — теперь направляет трафик на Green
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    version: v2        # Было v1, стало v2 — весь трафик уходит на Green
```

```bash
kubectl apply -f service-definition.yaml
```

Это происходит **мгновенно** — Kubernetes просто перестаёт отправлять трафик на Pod'ы с version=v1 и начинает на version=v2. Никакого даунтайма.

**Шаг 5: Удаляем Blue (или сохраняем как запасной вариант)**

```bash
kubectl delete deployment myapp-blue
```

Или оставляем Blue некоторое время — как быстрый способ откатиться при обнаружении проблем в production (просто поменять selector обратно на v1).

---

### Преимущества и недостатки Blue-Green

**Преимущества:**
- **Нулевой даунтайм** — переключение мгновенное
- **Полное тестирование перед релизом** — новая версия проверяется в реальной среде, но без реальных пользователей
- **Мгновенный откат** — если что-то пошло не так, достаточно снова изменить selector в Service
- **Чистота переключения** — в каждый момент времени пользователи работают только с одной версией

**Недостатки:**
- **Двойные ресурсы** — нужно поддерживать два полноценных Deployment'а одновременно. Для больших приложений это может быть дорого.
- **Сложность с данными** — если новая версия меняет схему базы данных, переключение трафика становится нетривиальным: база данных одна, а версии приложения — разные.

---

### Расширенный вариант: Istio для Blue-Green

Kubernetes позволяет реализовать Blue-Green только через количество Pod'ов и смену selector. Для более тонкого контроля используют **Istio Service Mesh**, который позволяет:
- Маршрутизировать трафик по HTTP-заголовкам (например, только для пользователей с заголовком `X-Beta: true`)
- Задавать точные веса (50% на Blue, 50% на Green) независимо от числа Pod'ов
- Постепенно переключать трафик (10% → 30% → 60% → 100%) по расписанию

---

## Часть 2: Canary Deployment (Канареечное развёртывание)

### Название и идея

Название пришло из горнодобывающей промышленности: шахтёры спускались в шахты с канарейками. Если птица переставала петь — значит, в воздухе опасный газ. Птица ценой своей жизни предупреждала людей.

В IT «канарейка» — это новая версия приложения, которая обслуживает небольшой процент реальных пользователей. Если что-то идёт не так — проблема затрагивает минимальное число людей.

**Canary — это компромисс между Rolling Update и Blue-Green:**
- Rolling Update постепенно заменяет Pod'ы (нет изоляции)
- Blue-Green переключает всё сразу (требует двойных ресурсов)
- Canary позволяет **постепенно увеличивать процент** трафика на новую версию, сохраняя полный контроль

---

### Как работает Canary в Kubernetes?

**Ключевая идея:** два Deployment'а с разным числом реплик, одним общим Label для Service.

```
[Service: app=front-end]
         ↓ распределяет трафик между всеми Pod'ами с app=front-end
         
[Primary Deployment: 5 Pod'ов, version=v1, app=front-end]  → 83% трафика
[Canary Deployment:  1 Pod,   version=v2, app=front-end]   → 17% трафика
```

Service не знает о том, что Pod'ы принадлежат разным Deployment'ам. Он видит 6 Pod'ов с одинаковой меткой `app: front-end` и равномерно распределяет трафик между ними.

---

### Полная реализация Canary

**Primary Deployment (основная, стабильная версия):**

```yaml
# myapp-primary.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-primary
  labels:
    app: myapp
    type: front-end
spec:
  replicas: 5
  selector:
    matchLabels:
      app: front-end
  template:
    metadata:
      labels:
        version: v1          # Версия для идентификации
        app: front-end       # ОБЩАЯ метка — ключ к работе Canary
    spec:
      containers:
        - name: app-container
          image: myapp-image:1.0
```

**Service (направляет трафик по общей метке):**

```yaml
# service-definition.yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app: front-end           # Выбирает ВСЕ Pod'ы с app=front-end
                             # (и primary, и canary!)
```

**Canary Deployment (новая версия, малое число реплик):**

```yaml
# myapp-canary.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-canary
  labels:
    app: myapp
    type: front-end
spec:
  replicas: 1                # Всего 1 реплика — минимальный трафик
  selector:
    matchLabels:
      app: front-end
  template:
    metadata:
      labels:
        version: v2          # Другая версия
        app: front-end       # Та же общая метка!
    spec:
      containers:
        - name: app-container
          image: myapp-image:2.0
```

---

### Математика распределения трафика

При 5 Pod'ах v1 и 1 Pod'е v2 (итого 6 Pod'ов):
- v1 получает: 5/6 ≈ **83% трафика**
- v2 получает: 1/6 ≈ **17% трафика**

Если хотим ещё меньше трафика на canary:

| Primary | Canary | % на Canary |
|---------|--------|-------------|
| 9 | 1 | 10% |
| 19 | 1 | 5% |
| 99 | 1 | ~1% |

Чем больше Pod'ов в primary, тем меньший процент получает canary.

---

### Процесс Canary Deployment — шаг за шагом

**Этап 1: Деплоим Canary**
```bash
kubectl apply -f myapp-canary.yml
```
Теперь ~17% пользователей видят новую версию.

**Этап 2: Мониторим**

Наблюдаем за метриками: ошибки, время ответа, бизнес-метрики. Если всё хорошо — переходим дальше.

**Этап 3: Постепенно увеличиваем трафик** (опционально)

```bash
# Увеличиваем canary до 2 реплик (2 из 7 ≈ 28%)
kubectl scale deployment myapp-canary --replicas=2

# Потом до 3 из 8 ≈ 37%
kubectl scale deployment myapp-canary --replicas=3
```

**Этап 4: Полное переключение**

```bash
# Обновляем primary Deployment до новой версии
kubectl set image deployment/myapp-primary app-container=myapp-image:2.0

# Удаляем canary — он больше не нужен
kubectl delete deployment myapp-canary
```

**Этап 4 (альтернатива через kubectl scale):**
```bash
# Уменьшаем primary до 0
kubectl scale deployment myapp-primary --replicas=0

# Увеличиваем canary до полного количества
kubectl scale deployment myapp-canary --replicas=5

# Удаляем старый primary
kubectl delete deployment myapp-primary
```

**Откат при проблемах:**
```bash
# Просто удаляем canary — пользователи вернутся на v1
kubectl delete deployment myapp-canary
```

---

### Ограничение Canary в чистом Kubernetes

**Проблема:** трафик распределяется **пропорционально числу Pod'ов**, а не задаётся в процентах явно.

Если хотим ровно 1% на canary — нужно 99 Pod'ов в primary и 1 Pod в canary. Это 100 Pod'ов суммарно. Для большинства реальных систем это неприемлемо.

**Решение:** Istio или другие Service Mesh позволяют задать `weight: 1%` на уровне маршрутизации независимо от числа Pod'ов. Например, в Istio это делается через объект `VirtualService`:

```yaml
# Пример конфигурации Istio (не чистый Kubernetes)
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
spec:
  http:
  - route:
    - destination:
        host: my-service
        subset: v1
      weight: 99       # 99% на stable версию
    - destination:
        host: my-service
        subset: v2
      weight: 1        # Ровно 1% на canary
```

---

### Сравнение Blue-Green и Canary

| Характеристика | Blue-Green | Canary |
|----------------|-----------|--------|
| Переключение трафика | Мгновенное, 100% | Постепенное |
| Ресурсы | 2x (оба полных стенда) | Немного больше (1-2 доп. Pod'а) |
| Риск | Нулевой до переключения | Минимальный, контролируемый |
| Тестирование на реальных пользователях | Нет (только после переключения) | Да (малый процент) |
| Откат | Мгновенный (смена selector) | Мгновенный (удаление canary) |
| Сложность | Средняя | Средняя |
| Подходит для | Крупных, критических релизов | A/B тестирования, осторожных релизов |

---

## Часть 3: Kubernetes Jobs (Задания)

### Два типа рабочих нагрузок в Kubernetes

До сих пор мы говорили о **долгоживущих** приложениях: веб-серверах, базах данных, API — они работают постоянно и никогда не должны завершаться.

Но есть другой класс задач — **разовые или пакетные операции**:
- Математические вычисления
- Обработка изображений
- Отправка отчётов по email
- Миграция базы данных
- Анализ большого объёма данных
- Резервное копирование

Эти задачи запускаются, выполняют свою работу, и **должны завершиться**. Именно для них существуют **Kubernetes Jobs**.

---

### Проблема с обычными Pod'ами для разовых задач

Без Job'а простой Pod выглядит так:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: math-pod
spec:
  containers:
  - name: math-add
    image: ubuntu
    command: ['expr', '3', '+', '2']   # Выполняет 3+2 и завершается
```

Запустим и посмотрим:

```bash
kubectl get pods
NAME       READY   STATUS      RESTARTS   AGE
math-pod   0/1     Completed   3          1d
```

Видите `RESTARTS: 3`? Kubernetes по умолчанию имеет `restartPolicy: Always` — он думает, что завершение контейнера это сбой, и бесконечно его перезапускает. Но нам этого не нужно!

**Костыльное решение — изменить restartPolicy:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: math-pod
spec:
  containers:
  - name: math-add
    image: ubuntu
    command: ['expr', '3', '+', '2']
  restartPolicy: Never    # Не перезапускать после завершения
```

Это работает, но у такого подхода проблемы:
- Нет механизма повтора при ошибке
- Нет способа запустить несколько Pod'ов параллельно
- Нет контроля за «успешным завершением»

Именно поэтому существуют **Jobs**.

---

### Анатомия Kubernetes Job

```yaml
apiVersion: batch/v1        # Специальный API для Jobs
kind: Job
metadata:
  name: math-add-job
spec:
  completions: 3            # Сколько УСПЕШНЫХ завершений нужно
  parallelism: 2            # Сколько Pod'ов можно запускать одновременно
  backoffLimit: 25          # Максимум попыток до признания Job'а провалившимся
  template:                 # Шаблон Pod'а (как в Deployment)
    spec:
      containers:
      - name: math-add
        image: ubuntu
        command: ['expr', '3', '+', '2']
      restartPolicy: Never  # Обязательно! Job управляет перезапусками сам
```

**Разбор ключевых полей:**

`completions` — сколько раз задача должна успешно выполниться. По умолчанию 1.

`parallelism` — сколько Pod'ов могут работать одновременно. По умолчанию 1 (последовательное выполнение).

`backoffLimit` — если Pod завершается с ошибкой, Job создаёт новый. `backoffLimit` ограничивает общее число попыток. Без этого Job мог бы бесконечно пытаться при «вечно ломающейся» задаче.

`restartPolicy` — для Jobs **обязательно** указывать `Never` или `OnFailure`. `Always` запрещён в Job'ах.

---

### Создание и проверка Job'а

```bash
# Создаём Job
kubectl create -f job-definition.yaml

# Смотрим статус
kubectl get jobs
NAME           DESIRED   SUCCESSFUL   AGE
math-add-job   1         1            38s

# Смотрим Pod'ы, которые создал Job
kubectl get pods
NAME                    READY   STATUS      RESTARTS   AGE
math-add-job-25j9p      0/1     Completed   0          38s

# Смотрим вывод задачи
kubectl logs math-add-job-25j9p
5

# Удаляем Job (вместе с Pod'ами)
kubectl delete job math-add-job
```

---

### Последовательное выполнение: completions без parallelism

```yaml
spec:
  completions: 3     # Нужно 3 успешных запуска
                     # parallelism не задан → по умолчанию 1 (последовательно)
```

**Как это работает:**
```
Попытка 1: [Pod-1] → Completed ✅
Попытка 2: [Pod-2] → Completed ✅
Попытка 3: [Pod-3] → Completed ✅
Итог: Job SUCCESSFUL (3/3)
```

Pod'ы создаются **по одному** — следующий запускается только после завершения предыдущего.

**Что происходит при ошибках:**
```
Попытка 1: [Pod-1] → Error ❌  (не считается как completion)
Попытка 2: [Pod-2] → Completed ✅
Попытка 3: [Pod-3] → Error ❌
Попытка 4: [Pod-4] → Completed ✅
Попытка 5: [Pod-5] → Completed ✅
Итог: Job SUCCESSFUL (3/3), всего было 5 попыток
```

Kubernetes продолжает создавать Pod'ы до тех пор, пока не наберётся нужное число успешных завершений.

```bash
kubectl get pods
NAME                     READY   STATUS      RESTARTS
random-error-job-ktmtt   0/1     Completed   0
random-error-job-sdsrf   0/1     Error       0
random-error-job-wwqbn   0/1     Completed   0
random-error-job-xpqmr   0/1     Error       0
random-error-job-ztryp   0/1     Completed   0
```

---

### Параллельное выполнение: completions + parallelism

```yaml
spec:
  completions: 3    # Нужно 3 успешных
  parallelism: 3    # Запускаем по 3 одновременно
```

**Как это работает:**
```
Шаг 1: Запускаем [Pod-1] [Pod-2] [Pod-3] одновременно

Pod-1 → Completed ✅
Pod-2 → Error ❌
Pod-3 → Completed ✅

Нужно ещё 1 успешное завершение, запускаем ещё один Pod:
[Pod-4] → Completed ✅

Итог: Job SUCCESSFUL
```

Kubernetes умно управляет параллелизмом: если часть Pod'ов упала, он создаёт новые до достижения нужного числа успешных завершений.

---

### Практический пример: бросок кубика

Образ `kodekloud/throw-dice` генерирует случайное число от 1 до 6. Шесть — успех, любое другое — провал.

**Базовый Job — сколько попыток нужно для одной шестёрки?**

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: throw-dice-job
spec:
  template:
    spec:
      containers:
      - name: throw-dice-job
        image: kodekloud/throw-dice
      restartPolicy: Never
  backoffLimit: 25    # Даём 25 попыток
```

```bash
kubectl describe job throw-dice-job
# Pods Statuses: 0 Active / 1 Succeeded / 3 Failed
# Значит, потребовалось 4 попытки (3 провала + 1 успех)
```

**Job с требованием 3 успешных результатов:**

```yaml
spec:
  completions: 3    # Нужно три шестёрки
  backoffLimit: 25
```

```bash
# Результат:
# Pods Statuses: 0 Active / 3 Succeeded / 1 Failed
# 4 попытки: 3 успеха и 1 провал
```

**Параллельный Job:**

```yaml
spec:
  completions: 3
  parallelism: 3    # Бросаем 3 кубика одновременно
  backoffLimit: 35  # Увеличили backoffLimit для надёжности
```

Три кубика бросаются одновременно — скорость выше, хотя общее число попыток может быть похожим.

---

## Часть 4: CronJobs (Задания по расписанию)

### Что такое CronJob?

**CronJob** — это Job, который запускается автоматически по расписанию. Аналог `crontab` в Linux.

Примеры задач для CronJob:
- Ежедневная отправка отчётов в 9:00
- Еженедельное резервное копирование базы данных по воскресеньям в 3:00
- Ежечасная очистка временных файлов
- Ежеминутный сбор метрик

---

### Синтаксис расписания (Cron Format)

```
┌─────────── минуты (0-59)
│ ┌───────── часы (0-23)
│ │ ┌─────── день месяца (1-31)
│ │ │ ┌───── месяц (1-12)
│ │ │ │ ┌─── день недели (0-7, где 0 и 7 = воскресенье)
│ │ │ │ │
* * * * *
```

**Примеры расписаний:**

| Расписание | Описание |
|-----------|---------|
| `*/1 * * * *` | Каждую минуту |
| `0 9 * * *` | Каждый день в 9:00 |
| `30 21 * * *` | Каждый день в 21:30 |
| `0 0 * * 0` | Каждое воскресенье в полночь |
| `0 */6 * * *` | Каждые 6 часов |
| `0 9 1 * *` | Первого числа каждого месяца в 9:00 |
| `0 9 * * 1-5` | По будням (пн-пт) в 9:00 |

---

### Структура CronJob — три уровня вложенности

Это важно понять: у CronJob три уровня вложенности YAML:

```
CronJob
  └── jobTemplate (шаблон Job'а)
        └── template (шаблон Pod'а)
              └── containers (контейнеры)
```

**Простой CronJob:**

```yaml
apiVersion: batch/v1           # Начиная с Kubernetes 1.21+
kind: CronJob
metadata:
  name: reporting-cron-job
spec:
  schedule: "*/1 * * * *"      # Каждую минуту
  jobTemplate:                  # Шаблон Job'а (не Pod'а!)
    spec:                       # Это spec Job'а
      completions: 3
      parallelism: 3
      template:                 # Это шаблон Pod'а внутри Job'а
        spec:                   # Это spec Pod'а
          containers:
          - name: reporting-tool
            image: reporting-tool
          restartPolicy: Never
```

**⚠️ Важное замечание по API версии:**

В документации упомянут `apiVersion: batch/v1beta1` — это **устаревшая версия**. Начиная с Kubernetes 1.21, CronJob переведён в стабильный `batch/v1`. Всегда используйте актуальную версию.

---

### Практический пример: CronJob для броска кубика

```yaml
# throw-dice-cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: throw-dice-cron-job
spec:
  schedule: "30 21 * * *"      # Каждый день в 21:30
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: throw-dice
            image: kodekloud/throw-dice
          restartPolicy: Never  # Never с большой N — это критично!
```

```bash
# Создаём CronJob
kubectl apply -f throw-dice-cronjob.yaml
# cronjob.batch/throw-dice-cron-job created

# Проверяем
kubectl get cronjob
NAME                   SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
throw-dice-cron-job    30 21 * * *   False     0        <none>          10s
```

---

### Как управлять CronJob'ами?

```bash
# Список CronJob'ов
kubectl get cronjobs

# Подробная информация
kubectl describe cronjob throw-dice-cron-job

# Посмотреть Job'ы, созданные CronJob'ом
kubectl get jobs

# Посмотреть Pod'ы
kubectl get pods

# Приостановить CronJob (не удалять, просто остановить)
kubectl patch cronjob throw-dice-cron-job -p '{"spec":{"suspend":true}}'

# Возобновить
kubectl patch cronjob throw-dice-cron-job -p '{"spec":{"suspend":false}}'

# Удалить CronJob (вместе со всеми связанными Job'ами и Pod'ами)
kubectl delete cronjob throw-dice-cron-job
```

---

### Расширенные параметры CronJob

```yaml
spec:
  schedule: "*/1 * * * *"
  successfulJobsHistoryLimit: 3     # Хранить N последних успешных Job'ов (по умолчанию 3)
  failedJobsHistoryLimit: 1          # Хранить N последних упавших Job'ов (по умолчанию 1)
  concurrencyPolicy: Forbid          # Что делать, если предыдущий Job ещё не завершился:
                                     # Allow — запускать новый параллельно
                                     # Forbid — пропустить этот запуск
                                     # Replace — убить старый и запустить новый
  startingDeadlineSeconds: 100       # Если Job не запустился в течение N секунд
                                     # от запланированного времени — пропустить
  jobTemplate:
    spec:
      ...
```

---

### Как CronJob, Job и Pod связаны между собой

```
CronJob (расписание)
  ↓ создаёт по расписанию
Job (управляет выполнением)
  ↓ создаёт
Pod(ы) (выполняют задачу)
  ↓ содержит
Container(ы) (запускают код)
```

При выполнении CronJob по расписанию создаётся новый Job-объект. Этот Job создаёт Pod'ы согласно своим настройкам (`completions`, `parallelism`). Pod'ы выполняют задачу и завершаются.

---

## Сводная таблица всех команд

| Задача | Команда |
|--------|---------|
| Создать Job | `kubectl create -f job.yaml` |
| Список Job'ов | `kubectl get jobs` |
| Детали Job'а | `kubectl describe job <name>` |
| Логи Pod'а Job'а | `kubectl logs <pod-name>` |
| Удалить Job | `kubectl delete job <name>` |
| Создать CronJob | `kubectl create -f cronjob.yaml` |
| Список CronJob'ов | `kubectl get cronjobs` |
| Удалить CronJob | `kubectl delete cronjob <name>` |
| Масштабировать Deployment | `kubectl scale deployment <name> --replicas=N` |
| Обновить образ | `kubectl set image deploy/<name> container=image:tag` |

---

## Итоговые выводы

### По стратегиям развёртывания:

**Blue-Green** — лучший выбор, когда нужно:
- Абсолютно чистое переключение без смешивания версий
- Возможность мгновенного отката
- Полное тестирование перед выходом в production
- Ресурсы позволяют держать два стенда

**Canary** — лучший выбор, когда нужно:
- Постепенно выкатывать изменения на реальных пользователях
- Контролировать процент аудитории, который видит новую версию
- Минимизировать влияние возможных ошибок
- Проводить A/B тестирование

### По Jobs и CronJobs:

1. **Обычные Pod'ы не подходят** для разовых задач — Kubernetes будет их перезапускать
2. **Job** — правильный инструмент для задач с конечным результатом; поддерживает повторы при ошибках, параллелизм, несколько необходимых завершений
3. **CronJob** — Job по расписанию; используйте стандартный cron-синтаксис
4. `restartPolicy: Never` в Job'ах — **обязательно**, причём с заглавной буквы
5. `backoffLimit` всегда устанавливайте явно — без него Job может бесконечно перезапускаться при постоянных ошибках
6. Помните иерархию: CronJob → Job → Pod → Container

---

# 6.0 - Сетевые политики и Ingress в Kubernetes

## Часть 1: Основы сетевых политик (Network Policies)

### Что такое трафик в контексте Kubernetes?

Прежде чем говорить о сетевых политиках, важно чётко понять два ключевых понятия:

**Ingress-трафик** — это входящий трафик, то есть тот, который *приходит* на сервер или Pod извне. Например, когда пользователь открывает браузер и заходит на ваш сайт — это ingress для веб-сервера.

**Egress-трафик** — это исходящий трафик, то есть тот, который Pod *отправляет* куда-то. Например, когда веб-сервер делает запрос к API-серверу — это egress для веб-сервера.

Важный нюанс: когда мы говорим о направлении трафика, мы говорим только о *направлении инициации соединения*. Ответный трафик (response) не считается отдельным направлением и автоматически разрешается, если разрешён основной запрос. То есть если вы разрешили входящий запрос к базе данных, ответ базы данных обратно к API-серверу будет разрешён автоматически — вам не нужно писать отдельное правило.

---

### Практический пример: три уровня приложения

Представьте классическую трёхзвенную архитектуру:

```
Пользователь → [Веб-сервер] → [API-сервер] → [База данных]
    :80            :5000           :3306
```

Вот как выглядит таблица трафика для каждого компонента:

| Компонент       | Тип трафика | Порт | Описание                                      |
|-----------------|-------------|------|-----------------------------------------------|
| Веб-сервер      | Ingress     | 80   | Принимает HTTP-запросы от пользователей       |
| Веб-сервер      | Egress      | 5000 | Отправляет запросы к API-серверу              |
| API-сервер      | Ingress     | 5000 | Принимает трафик от веб-сервера               |
| API-сервер      | Egress      | 3306 | Отправляет запросы к базе данных              |
| База данных     | Ingress     | 3306 | Принимает запросы от API-сервера              |

---

### Сетевая безопасность по умолчанию в Kubernetes

По умолчанию Kubernetes работает по принципу **"разрешено всё"** (all-allow). Это означает, что любой Pod может свободно общаться с любым другим Pod в кластере без каких-либо ограничений. Все Pod-ы находятся в общей виртуальной сети и могут обращаться друг к другу по IP-адресу, имени Pod-а или через сервис.

С точки зрения разработки это удобно, но с точки зрения безопасности — серьёзная уязвимость. Например, если злоумышленник каким-то образом получит доступ к веб-серверу, он сможет напрямую обратиться к базе данных. Именно здесь на помощь приходят сетевые политики.

---

### Что такое сетевая политика?

**Сетевая политика (NetworkPolicy)** — это объект Kubernetes, который позволяет контролировать, какой трафик разрешён для тех или иных Pod-ов. Она работает по принципу белого списка: как только вы создаёте политику для Pod-а, весь трафик, не описанный в этой политике, автоматически блокируется.

Политика связывается с Pod-ами через **метки и селекторы** (labels и selectors) — тот же механизм, который используется в ReplicaSet, Service и Deployment.

---

## Часть 2: Создание сетевых политик — от простого к сложному

### Шаг 1: Блокировка всего входящего трафика

Первый шаг — создать политику, которая просто блокирует весь ingress-трафик к Pod-у базы данных. Для этого мы объявляем тип политики `Ingress`, но не добавляем никаких разрешающих правил:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-policy
spec:
  podSelector:
    matchLabels:
      role: db          # Политика применяется к Pod-ам с меткой role=db
  policyTypes:
  - Ingress             # Контролируем только входящий трафик
                        # Правил нет → весь ingress-трафик заблокирован
```

После применения этой политики Pod базы данных перестанет принимать любые входящие соединения. Egress-трафик (исходящий) при этом остаётся незатронутым — база данных по-прежнему сможет сама инициировать исходящие соединения, если понадобится.

---

### Шаг 2: Разрешение трафика от конкретного Pod-а

Теперь нужно разрешить API-серверу обращаться к базе данных на порт 3306. Добавляем секцию `ingress` с правилом:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-policy
spec:
  podSelector:
    matchLabels:
      role: db
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          name: api-pod  # Разрешаем трафик ТОЛЬКО от Pod-ов с меткой name=api-pod
    ports:
    - protocol: TCP
      port: 3306         # И ТОЛЬКО на порт 3306
```

Эта политика означает следующее:
- Pod базы данных принимает ingress-трафик только от Pod-ов с меткой `name: api-pod`
- Только по протоколу TCP на порт 3306
- Любой другой входящий трафик (например, напрямую с веб-сервера) будет заблокирован
- Ответный трафик (ответы базы данных на запросы API-сервера) разрешается автоматически

---

### Шаг 3: Ограничение по неймспейсу (Namespace)

Представьте, что у вас несколько окружений: `dev`, `test`, `prod`. В каждом из них есть свой API-Pod с одинаковой меткой `name: api-pod`. Политика из предыдущего шага разрешила бы доступ к базе данных из *всех* этих окружений, что нежелательно — к production-базе должен иметь доступ только production-API.

Решение — добавить **namespaceSelector**:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-policy
spec:
  podSelector:
    matchLabels:
      role: db
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          name: api-pod
      namespaceSelector:   # ВАЖНО: этот селектор находится на том же уровне,
        matchLabels:       # что и podSelector, без отдельного дефиса!
          name: prod       # Разрешаем только из неймспейса с меткой name=prod
    ports:
    - protocol: TCP
      port: 3306
```

Обратите особое внимание на структуру YAML. `podSelector` и `namespaceSelector` находятся на одном уровне без отдельного дефиса перед `namespaceSelector` — это означает логическое **И** (AND): трафик разрешён, только если Pod имеет нужную метку **И** находится в нужном неймспейсе.

Если бы перед `namespaceSelector` стоял отдельный дефис:

```yaml
  ingress:
  - from:
    - podSelector:        # Первое условие (OR)
        matchLabels:
          name: api-pod
    - namespaceSelector:  # Второе условие (OR) — отдельный дефис!
        matchLabels:
          name: prod
```

Это означало бы **ИЛИ** (OR): разрешён трафик от api-pod из любого неймспейса **ИЛИ** от любого Pod-а из неймспейса prod. Это существенно расширяет доступ и скорее всего нежелательно.

> **Важно:** Чтобы namespaceSelector работал, у самого неймспейса должна быть соответствующая метка. Это нужно настроить отдельно: `kubectl label namespace prod name=prod`

---

### Шаг 4: Разрешение трафика от внешних источников (IP Block)

Иногда к Pod-у должен обращаться сервер, который находится вне кластера Kubernetes — например, сервер резервного копирования с IP-адресом `192.168.5.10`. Поскольку этот сервер не управляется Kubernetes, мы не можем использовать podSelector или namespaceSelector. Для таких случаев используется **ipBlock**:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-policy
spec:
  podSelector:
    matchLabels:
      role: db
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:           # Условие 1: от api-pod в неймспейсе prod
        matchLabels:
          name: api-pod
      namespaceSelector:
        matchLabels:
          name: prod
    - ipBlock:               # Условие 2 (OR): от конкретного внешнего IP
        cidr: 192.168.5.10/32
    ports:
    - protocol: TCP
      port: 3306
```

Здесь два условия разделены дефисами и работают как **ИЛИ**:
- Либо трафик приходит от Pod-а `api-pod` в неймспейсе `prod`
- Либо трафик приходит с IP `192.168.5.10`

---

### Шаг 5: Управление исходящим трафиком (Egress)

По умолчанию egress-трафик (исходящий) не ограничивается, если в политике не указан тип `Egress`. Но бывают случаи, когда нужно ограничить и его. Например, агент на Pod-е базы данных сам отправляет резервные копии на внешний сервер.

Полная политика с контролем и ingress, и egress:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-policy
spec:
  podSelector:
    matchLabels:
      role: db
  policyTypes:
  - Ingress
  - Egress              # Теперь контролируем оба направления
  ingress:
  - from:
    - podSelector:
        matchLabels:
          name: api-pod
    ports:
    - protocol: TCP
      port: 3306
  egress:
  - to:
    - ipBlock:
        cidr: 192.168.5.10/32   # Разрешаем исходящий трафик только к серверу бэкапов
    ports:
    - protocol: TCP
      port: 80
```

Теперь Pod базы данных:
- Принимает входящие соединения только от `api-pod` на порту 3306
- Может инициировать исходящие соединения только к `192.168.5.10` на порту 80
- Любой другой egress-трафик (например, попытка подключиться к интернету) будет заблокирован

---

### Какие сетевые решения поддерживают политики?

Сетевые политики Kubernetes реализуются не самим Kubernetes, а сетевым плагином (CNI plugin). Важно знать, какие из них поддерживают эту функцию:

| Поддерживают | Не поддерживают |
|---|---|
| Calico | Flannel |
| Weave Net | |
| Kube-Router | |
| Romana | |

Если вы используете Flannel, вы можете создать NetworkPolicy-объект — Kubernetes его примет без ошибок. Но правила применяться не будут, трафик останется незащищённым. Поэтому всегда проверяйте документацию используемого CNI-плагина.

---

## Часть 3: Практический пример из лабораторной работы

### Анализ существующих политик

В лабораторной среде развёрнуто несколько Pod-ов:

```bash
$ kubectl get pods
NAME       READY   STATUS    RESTARTS   AGE
external   1/1     Running   0          2m20s
internal   1/1     Running   0          2m19s
mysql      1/1     Running   0          2m19s
payroll    1/1     Running   0          2m19s
```

Чтобы посмотреть существующие сетевые политики:

```bash
$ kubectl get netpol
NAME             POD-SELECTOR   AGE
payroll-policy   name=payroll   3m31s
```

Детали политики:

```bash
$ kubectl describe netpol payroll-policy
Spec:
  PodSelector:     name=payroll
  Allowing ingress traffic:
    To Port: 8080/TCP
    From:
      PodSelector: name=internal
  Not affecting egress traffic
  Policy Types: Ingress
```

Что это означает:
- Политика применяется к Pod-у `payroll`
- Разрешён входящий трафик на порт 8080 только от Pod-а с меткой `name=internal`
- Pod `external` не может достучаться до `payroll` — его запросы будут блокироваться
- Egress-трафик от `payroll` ничем не ограничен

### Создание политики для ограничения исходящего трафика

Задача: ограничить исходящий трафик от Pod-а `internal` так, чтобы он мог обращаться только к сервисам `payroll` и `mysql`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: internal-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      name: internal        # Применяется к Pod-у internal
  policyTypes:
    - Egress                # Контролируем только исходящий трафик
  egress:
    - to:
      - podSelector:
          matchLabels:
            name: payroll   # Разрешаем обращаться к payroll
      ports:
        - protocol: TCP
          port: 8080
    - to:
      - podSelector:
          matchLabels:
            name: mysql     # Разрешаем обращаться к mysql
      ports:
        - protocol: TCP
          port: 3306
```

Применяем:

```bash
$ kubectl create -f internal-policy.yaml
networkpolicy.networking.k8s.io/internal-policy created
```

После этого:
- `internal` → `payroll:8080` — разрешено ✅
- `internal` → `mysql:3306` — разрешено ✅
- `internal` → любой другой Pod — заблокировано ❌
- Входящий трафик к `internal` — по-прежнему не ограничен (мы не указывали тип `Ingress`)

---

## Часть 4: Ingress Networking — единая точка входа в кластер

### Почему стандартных сервисов недостаточно?

Kubernetes предоставляет три типа сервисов для внешнего доступа:

**ClusterIP** — только внутри кластера. Внешние пользователи не могут достучаться.

**NodePort** — открывает порт на каждом узле кластера. Пользователь обращается по адресу `http://NodeIP:38080`. Неудобно — нужно помнить порт, нет SSL, нет балансировки между узлами.

**LoadBalancer** — в облачных средах (GCP, AWS, Azure) автоматически создаёт внешний балансировщик нагрузки. Удобно, но каждый сервис получает отдельный балансировщик — это дорого. Три сервиса = три балансировщика = тройная плата.

Кроме того, с ростом приложения возникают типичные задачи:
- Маршрутизация по URL: `/wear` → одно приложение, `/watch` → другое
- Маршрутизация по хосту: `wear.mystore.com` → одно, `video.mystore.com` → другое
- SSL-терминация в одном месте
- Аутентификация и авторизация на уровне входа

Всё это приходилось настраивать вручную через nginx, HAProxy или Traefik — и поддерживать отдельно от Kubernetes. **Ingress** решает эту проблему, предоставляя нативный Kubernetes-способ управления внешним доступом.

---

### Архитектура Ingress

Ingress состоит из двух частей:

**1. Ingress Controller** — это реальный сервер (nginx, HAProxy, Traefik, GCP HTTP LB и другие), развёрнутый внутри кластера. Он следит за изменениями Ingress-ресурсов и автоматически обновляет свою конфигурацию. **Важно:** Kubernetes не устанавливает контроллер автоматически — вы должны развернуть его самостоятельно.

**2. Ingress Resource** — это YAML-манифест Kubernetes, в котором вы описываете правила маршрутизации: какой URL куда вести, какой SSL-сертификат использовать и т.д.

Схема работы:

```
Интернет → [Внешний LoadBalancer/NodePort] → [Ingress Controller] → [Ingress Rules] → [Сервисы] → [Pod-ы]
```

---

### Развёртывание Ingress Controller (NGINX)

Для работы NGINX Ingress Controller нужно создать несколько объектов:

**1. Deployment — сам контроллер:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-ingress-controller
  namespace: ingress-nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      name: nginx-ingress
  template:
    metadata:
      labels:
        name: nginx-ingress
    spec:
      serviceAccountName: ingress-serviceaccount  # Нужен для доступа к API Kubernetes
      containers:
        - name: nginx-ingress-controller
          image: quay.io/kubernetes-ingress-nginx/controller
          args:
            - /nginx-ingress-controller
            - --configmap=$(POD_NAMESPACE)/nginx-configuration  # Конфиг из ConfigMap
            - --default-backend-service=app-space/default-http-backend
          env:
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
          ports:
            - name: http
              containerPort: 80
            - name: https
              containerPort: 443
```

**2. ConfigMap — конфигурация NGINX:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-configuration
  namespace: ingress-nginx
# Изначально пустой — NGINX использует настройки по умолчанию
# Можно добавить параметры позже без пересборки образа
```

**3. Service — внешний доступ к контроллеру:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-ingress
  namespace: ingress-nginx
spec:
  type: NodePort          # Или LoadBalancer в облаке
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
      name: http
    - port: 443
      targetPort: 443
      protocol: TCP
      name: https
  selector:
    name: nginx-ingress
```

**4. ServiceAccount — права доступа к API:**

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nginx-ingress-serviceaccount
  namespace: ingress-nginx
```

Контроллеру нужен ServiceAccount, потому что он должен читать из API Kubernetes информацию о Ingress-ресурсах, Pod-ах, сервисах и секретах (для SSL).

---

### Создание Ingress Resource

После развёртывания контроллера создаём правила маршрутизации.

**Вариант 1: Весь трафик → один сервис (Default Backend)**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-wear
spec:
  defaultBackend:
    service:
      name: wear-service
      port:
        number: 80
```

**Вариант 2: Маршрутизация по URL-пути**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-wear-watch
  namespace: app-space
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /       # Перезаписываем путь
    nginx.ingress.kubernetes.io/ssl-redirect: "false"   # Отключаем принудительный HTTPS
spec:
  rules:
  - http:
      paths:
      - path: /wear
        pathType: Prefix
        backend:
          service:
            name: wear-service
            port:
              number: 8080
      - path: /watch
        pathType: Prefix
        backend:
          service:
            name: video-service
            port:
              number: 8080
```

Аннотация `rewrite-target: /` важна: без неё запрос к `/wear/something` будет отправлен в сервис как `/wear/something`, но если приложение ожидает запросы на `/`, оно вернёт 404. С этой аннотацией путь перезаписывается в `/`.

**Вариант 3: Маршрутизация по хосту (домену)**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-host-based
spec:
  rules:
  - host: wear.my-online-store.com
    http:
      paths:
      - backend:
          service:
            name: wear-service
            port:
              number: 80
  - host: video.my-online-store.com
    http:
      paths:
      - backend:
          service:
            name: video-service
            port:
              number: 80
```

---

### Важная особенность: Ingress и неймспейсы

Ingress-ресурс находится в конкретном неймспейсе и может маршрутизировать трафик только к сервисам в **том же неймспейсе**. Это важное ограничение.

Если у вас критически важный платёжный сервис в неймспейсе `critical-space`, нужно создать отдельный Ingress в этом неймспейсе:

```bash
# Быстрое создание через kubectl:
kubectl create ingress ingress-pay \
  -n critical-space \
  --rule="/pay=pay-service:8282"
```

Или через YAML:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-pay
  namespace: critical-space   # Тот же неймспейс, что и сервис
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - http:
      paths:
      - path: /pay
        pathType: Exact
        backend:
          service:
            name: pay-service    # Сервис в том же неймспейсе
            port:
              number: 8282
```

---

### Типичная проблема: 308 Redirect (SSL Redirect)

В лабораторной работе описана распространённая проблема: запросы к `/watch` возвращают HTTP 308 и перенаправляют на HTTPS. Это происходит потому, что NGINX Ingress Controller по умолчанию принудительно перенаправляет HTTP на HTTPS.

В логах это выглядит так:

```
"GET /watch HTTP/1.1" 308 171 ...
```

Решение — добавить аннотацию, отключающую это поведение:

```yaml
annotations:
  nginx.ingress.kubernetes.io/ssl-redirect: "false"
```

---

## Выводы и сравнительная таблица

### Network Policies — ключевые выводы:

1. **По умолчанию всё разрешено** — без политик любой Pod может общаться с любым другим.
2. **Политика работает как белый список** — как только вы создаёте политику для Pod-а, блокируется всё, что не разрешено явно.
3. **Ingress и Egress — независимы** — можно контролировать оба направления отдельно. Если тип не указан, это направление не затрагивается.
4. **Ответный трафик разрешается автоматически** — не нужно писать обратные правила.
5. **AND vs OR** — два селектора под одним `-` работают как И, два отдельных `-` — как ИЛИ.
6. **Нужна поддержка CNI** — без поддерживающего плагина (Calico, Weave и т.д.) политики создадутся, но работать не будут.

### Ingress — ключевые выводы:

1. **Контроллер не встроен** — его нужно развернуть отдельно (NGINX, Traefik и т.д.).
2. **Два компонента** — Controller (исполнитель) + Resource (правила).
3. **Один вход для всего** — вместо множества LoadBalancer-сервисов один Ingress управляет маршрутизацией.
4. **Поддерживает SSL** — терминация HTTPS в одном месте.
5. **Неймспейс имеет значение** — Ingress маршрутизирует только к сервисам в своём неймспейсе.
6. **Аннотации управляют поведением** — rewrite-target, ssl-redirect и другие параметры настраиваются через annotations.

### Когда что использовать:

| Задача | Инструмент |
|---|---|
| Запретить прямой доступ к БД | NetworkPolicy (Ingress на Pod БД) |
| Ограничить, куда может ходить Pod | NetworkPolicy (Egress) |
| Разрешить только из конкретного неймспейса | NetworkPolicy с namespaceSelector |
| Разрешить внешний сервер по IP | NetworkPolicy с ipBlock |
| Один URL для нескольких сервисов | Ingress с path-based routing |
| Разные домены → разные сервисы | Ingress с host-based routing |
| SSL-терминация | Ingress с TLS-секретом |
| Кастомная страница 404 | Ingress defaultBackend |

---

# 7.1 - Хранилище в Docker и Kubernetes: полное руководство

Это обширная тема, которая охватывает несколько взаимосвязанных концепций. Разберём всё по порядку — от основ Docker до продвинутых механизмов Kubernetes.

---

## Часть 1: Хранилище в Docker

### 1.1 Где Docker хранит данные на хосте

При установке Docker автоматически создаёт структуру директорий на хосте по пути `/var/lib/docker`. Внутри находятся следующие поддиректории:

- **`aufs`** — данные слоёв файловой системы (при использовании драйвера AUFS)
- **`containers`** — файлы, связанные с запущенными и остановленными контейнерами
- **`images`** — хранимые образы
- **`volumes`** — данные постоянных томов, созданных контейнерами

Это важно понимать, потому что всё, что происходит с данными в Docker — образы, контейнеры, тома — физически находится именно здесь.

---

### 1.2 Два ключевых понятия хранилища в Docker

Docker работает с двумя принципиально разными механизмами хранения:

**1. Storage Drivers (Драйверы хранилища)** — управляют образами и контейнерами, реализуют слоистую архитектуру файловой системы.

**2. Volume Driver Plugins (Плагины драйверов томов)** — управляют персистентными данными (томами), которые живут независимо от контейнеров.

Это разделение очень важно: не путайте их, они решают разные задачи.

---

### 1.3 Слоистая архитектура образов Docker

Это один из самых важных концептов Docker. Каждый образ состоит из набора **слоёв только для чтения (read-only)**. Каждый слой создаётся одной инструкцией в `Dockerfile` и содержит только изменения по сравнению с предыдущим слоем.

**Пример Dockerfile:**

```dockerfile
FROM Ubuntu                                          # Слой 1: базовый образ Ubuntu (~120 MB)

RUN apt-get update && apt-get -y install python      # Слой 2: установка Python (~300 MB)

RUN pip install flask flask-mysql                    # Слой 3: Python-пакеты (несколько MB)

COPY . /opt/source-code                             # Слой 4: исходный код приложения

ENTRYPOINT FLASK_APP=/opt/source-code/app.py flask run  # Слой 5: точка входа
```

**Сборка образа:**

```bash
docker build -t mmumshad/my-custom-app .
```

**Что происходит при сборке:**
- Docker выполняет каждую инструкцию и создаёт новый слой
- Каждый слой содержит только **дельту** (разницу) относительно предыдущего
- Слои сохраняются в кэш

**Ключевое преимущество — повторное использование кэша.** Допустим, вы создаёте второе приложение, похожее на первое:

```dockerfile
FROM Ubuntu                                          # Слой 1: тот же Ubuntu

RUN apt-get update && apt-get -y install python      # Слой 2: тот же Python

RUN pip install flask flask-mysql                    # Слой 3: те же пакеты

COPY app2.py /opt/source-code                       # Слой 4: ДРУГОЙ файл

ENTRYPOINT FLASK_APP=/opt/source-code/app2.py flask run  # Слой 5: другая точка входа
```

```bash
docker build -t mmumshad/my-custom-app-2 .
```

Docker видит, что первые три слоя **идентичны** слоям из первого образа, и **берёт их из кэша**. Пересобираются только слои 4 и 5. Это существенно ускоряет сборку и экономит дисковое пространство.

---

### 1.4 Слои образа и слой контейнера: Copy-on-Write

Когда вы запускаете контейнер из образа:

```bash
docker run mmumshad/my-custom-app
```

Docker **не копирует** образ. Вместо этого поверх read-only слоёв образа создаётся **тонкий слой для записи (writable layer)**. Именно в него попадают:

- Логи приложения
- Временные файлы
- Любые изменения, вносимые во время работы контейнера

Это называется **Copy-on-Write (копирование при записи)**:

- Если процесс в контейнере хочет **читать** файл из образа — он читает напрямую из read-only слоя.
- Если процесс хочет **изменить** файл из образа — Docker сначала **копирует** этот файл в writable layer, и только после этого вносит изменения. Оригинал в образе остаётся нетронутым.

**Что происходит при удалении контейнера:**

> Когда контейнер удаляется, его writable layer уничтожается вместе со всеми изменениями. Оригинальный образ при этом не затрагивается.

Это означает: **данные, записанные только в writable layer контейнера, теряются при его удалении**. Именно поэтому нужны тома.

---

### 1.5 Драйверы хранилища (Storage Drivers)

Storage Driver реализует механику слоистой файловой системы: создание слоёв, их объединение (union mount), операции Copy-on-Write. Доступные драйверы:

| Драйвер | Особенности |
|---|---|
| **AUFS** | Стандартный для Ubuntu, стабильный, зрелый |
| **Overlay / Overlay2** | Современный, быстрый, рекомендуется для новых систем |
| **Device Mapper** | Используется в Fedora/CentOS при отсутствии AUFS |
| **ZFS** | Расширенные возможности, встроенные снапшоты |
| **BTRFS** | Файловая система со снапшотами и подтомами |

Выбор драйвера зависит от операционной системы и требований к производительности. На Ubuntu по умолчанию используется AUFS, на Fedora/CentOS — Device Mapper.

---

### 1.6 Персистентность данных: тома Docker

Поскольку данные в writable layer контейнера исчезают при его удалении, для **персистентного хранения** используются тома.

#### Создание и монтирование тома

```bash
# Шаг 1: создаём том
docker volume create data_volume

# Шаг 2: запускаем контейнер с монтированием тома
docker run -v data_volume:/var/lib/mysql mysql
```

Том `data_volume` создаётся в `/var/lib/docker/volumes/data_volume/`. Даже если контейнер будет удалён, данные в томе останутся.

**Удобная деталь:** если вы укажете имя тома, которого ещё не существует, Docker создаст его автоматически:

```bash
docker run -v new_volume:/var/lib/mysql mysql
# Docker сам создаст new_volume, если его нет
```

#### Bind Mounts (Монтирование директорий хоста)

Если вам нужно использовать конкретную директорию на хосте (например, для хранения данных БД в `/data/mysql`):

```bash
docker run -v /data/mysql:/var/lib/mysql mysql
```

Здесь `/data/mysql` — это путь на хосте, `/var/lib/mysql` — путь внутри контейнера. Данные записываются прямо на файловую систему хоста.

**Разница между volume и bind mount:**
- **Volume** — Docker управляет местом хранения (внутри `/var/lib/docker/volumes`)
- **Bind mount** — вы явно указываете путь на хосте

#### Современный синтаксис: флаг `--mount`

Флаг `-v` считается устаревшим стилем. Современный и более явный способ — использование `--mount`:

```bash
docker run \
  --mount type=bind,source=/data/mysql,target=/var/lib/mysql \
  mysql
```

Параметры:
- `type` — тип монтирования: `bind`, `volume` или `tmpfs`
- `source` — источник (путь на хосте или имя тома)
- `target` — путь внутри контейнера

Этот синтаксис предпочтителен, потому что каждый параметр назван явно и код легче читать.

---

### 1.7 Плагины драйверов томов (Volume Driver Plugins)

Volume drivers — это отдельный слой, занимающийся именно управлением томами. Они не связаны с Storage Drivers.

**Драйвер по умолчанию — `local`:** создаёт тома на Docker-хосте в `/var/lib/docker/volumes`.

Сторонние плагины позволяют использовать внешние системы хранения:

- **Azure File Storage** — облачное хранилище Azure
- **Google Compute Persistent Disks** — диски GCP
- **RexRay** — мощный плагин с поддержкой AWS EBS, S3, EMC Isilon/ScaleIO, Google Persistent Disk, OpenStack Cinder
- **Portworx** — распределённое хранилище для контейнеров
- **NetApp, ClusterFS, Convoy, Blocker, DigitalOcean Block Storage, VMware vSphere** — и многие другие

**Пример: запуск MySQL с томом на AWS EBS через RexRay:**

```bash
docker run -it \
  --name mysql \
  --volume-driver rexray/ebs \
  --mount src=ebs-vol,target=/var/lib/mysql \
  mysql
```

Здесь Docker обращается к плагину RexRay, который в свою очередь работает с AWS EBS API и создаёт/монтирует облачный диск. Даже если контейнер завершится, данные останутся в EBS.

---

## Часть 2: Хранилище в Kubernetes

Kubernetes строится на тех же концепциях Docker, но добавляет собственные абстракции для управления хранилищем в кластере.

---

### 2.1 Почему в Kubernetes нужны тома

Поды в Kubernetes, как и контейнеры в Docker, **эфемерны**: когда под удаляется, все данные внутри него теряются. Чтобы данные сохранялись независимо от жизненного цикла пода, к нему нужно подключать тома.

**Без тома:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: random-number-generator
spec:
  containers:
    - image: alpine
      name: alpine
      command: ["/bin/sh","-c"]
      args: ["shuf -i 0-100 -n 1 >> /opt/number.out;"]
```

Если этот под будет удалён, файл `/opt/number.out` исчезнет навсегда.

**С томом типа hostPath:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: random-number-generator
spec:
  containers:
    - image: alpine
      name: alpine
      command: ["/bin/sh", "-c"]
      args: ["shuf -i 0-100 -n 1 >> /opt/number.out;"]
      volumeMounts:
        - mountPath: /opt         # путь внутри контейнера
          name: data-volume        # имя тома (должно совпадать ниже)
  volumes:
    - name: data-volume
      hostPath:
        path: /data               # путь на ноде хоста
        type: Directory
```

Теперь файл `/opt/number.out` внутри контейнера фактически хранится в `/data/number.out` на ноде. Под можно удалить и пересоздать — данные останутся.

> **Важное ограничение:** `hostPath` работает корректно только на однонодовых кластерах. В многонодовом кластере под может быть запланирован на другую ноду, где директории `/data` либо нет, либо она содержит другие данные. Для многонодовых кластеров нужны сетевые решения.

---

### 2.2 Варианты хранилища для томов в Kubernetes

Kubernetes поддерживает множество бэкендов хранилища:

**Сетевые:**
- NFS (Network File System)
- GlusterFS
- Flocker
- CephFS

**Блочные:**
- Fibre Channel
- ScaleIO

**Облачные:**
- AWS Elastic Block Store (EBS)
- Azure Disk
- Google Persistent Disk

**Пример конфигурации тома с AWS EBS в поде:**

```yaml
volumes:
  - name: data-volume
    awsElasticBlockStore:
      volumeID: <volume-id>
      fsType: ext4
```

---

### 2.3 Проблема прямой конфигурации томов в подах

Когда конфигурация хранилища встроена прямо в определение пода, возникают серьёзные проблемы масштабирования:

1. Каждый разработчик должен знать детали инфраструктуры хранилища (ID томов, типы FS и т.д.)
2. При изменении инфраструктуры нужно обновлять каждый файл пода вручную
3. В больших командах это становится источником ошибок

**Решение** — разделить ответственность: администраторы создают пул хранилища (**Persistent Volumes**), разработчики запрашивают нужное количество из пула (**Persistent Volume Claims**).

---

### 2.4 Persistent Volumes (PV) — Постоянные тома

**Persistent Volume** — это объект Kubernetes, который представляет собой кусок хранилища в кластере. Администратор создаёт PV заранее, независимо от любых подов.

**Пример PV с hostPath (для тестирования):**

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-vol1
spec:
  accessModes:
    - ReadWriteOnce       # режим доступа
  capacity:
    storage: 1Gi          # объём хранилища
  hostPath:
    path: /tmp/data       # путь на ноде (только для тестов!)
```

**Пример PV с AWS EBS (для продакшена):**

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-vol1
spec:
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 1Gi
  awsElasticBlockStore:
    volumeID: <volume-id>
    fsType: ext4
```

**Режимы доступа (accessModes):**

| Режим | Обозначение | Смысл |
|---|---|---|
| `ReadWriteOnce` | RWO | Монтирование для чтения/записи одной нодой |
| `ReadOnlyMany` | ROX | Монтирование только для чтения многими нодами |
| `ReadWriteMany` | RWX | Монтирование для чтения/записи многими нодами |

**Создание и просмотр PV:**

```bash
kubectl create -f pv-definition.yaml

kubectl get persistentvolume
```

Ожидаемый вывод:
```
NAME       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   AGE
pv-vol1    1Gi        RWO            Retain            Available                          3m
```

Статус `Available` означает, что PV создан и ожидает привязки к PVC.

---

### 2.5 Persistent Volume Claims (PVC) — Заявки на постоянные тома

**Persistent Volume Claim** — это запрос на хранилище от имени пользователя/разработчика. PVC описывает, сколько места нужно и с какими параметрами доступа.

**Пример PVC:**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: myclaim
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi    # запрашиваем 500 MB
```

**Создание PVC:**

```bash
kubectl create -f pvc-definition.yaml

kubectl get persistentvolumeclaim
```

---

### 2.6 Как Kubernetes связывает PVC с PV

Когда создаётся PVC, Kubernetes автоматически ищет подходящий PV по следующим критериям:

1. **Режим доступа** — должен совпадать
2. **Объём** — PV должен иметь достаточно места (может быть больше, чем запрошено)
3. **Класс хранилища** — должен совпадать (если указан)
4. **Метки (labels/selectors)** — опционально, для точного указания конкретного PV

**Пример привязки по меткам:**

В PV добавляем метку:
```yaml
metadata:
  labels:
    name: my-pv
```

В PVC указываем селектор:
```yaml
spec:
  selector:
    matchLabels:
      name: my-pv
```

**Важный нюанс:** если PVC запрашивает 500Mi, а единственный доступный PV имеет 1Gi — PVC привяжется к этому PV. Оставшиеся 500Mi просто не будут использоваться и **не могут быть выделены другим PVC**. Каждый PV привязывается ровно к одному PVC.

**Что если нет подходящего PV?**

PVC остаётся в состоянии `Pending`. Как только подходящий PV появится в кластере, Kubernetes автоматически выполнит привязку.

**Пример мисматча режимов доступа (реальная ошибка):**

PV создан с `ReadWriteMany`, PVC запрашивает `ReadWriteOnce` — привязки не произойдёт, PVC будет висеть в `Pending`.

```bash
# Исправляем PVC, меняем accessMode на ReadWriteMany
kubectl replace --force -f pvc.yaml

kubectl get pv
kubectl get pvc
```

После исправления:
```
NAME      CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                 AGE
pv-log    100Mi      RWX            Retain           Bound    default/claim-log-1   5m
```

```
NAME          STATUS   VOLUME   CAPACITY   ACCESS MODES   AGE
claim-log-1   Bound    pv-log   100Mi      RWX            26s
```

---

### 2.7 Использование PVC в поде

После того как PVC создан и привязан к PV, его можно использовать в поде:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: webapp
spec:
  containers:
  - name: event-simulator
    image: kodekloud/event-simulator
    env:
      - name: LOG_HANDLERS
        value: file
    volumeMounts:
      - name: log-volume
        mountPath: /log               # путь внутри контейнера
  volumes:
  - name: log-volume
    persistentVolumeClaim:
      claimName: claim-log-1          # имя нашего PVC
```

Вместо того чтобы указывать `hostPath` или `awsElasticBlockStore` прямо в поде, разработчик просто ссылается на PVC по имени. Детали инфраструктуры скрыты.

---

### 2.8 Политики освобождения (Reclaim Policies)

Когда PVC удаляется, что происходит с PV? Это определяется политикой освобождения (`persistentVolumeReclaimPolicy`).

#### `Retain` (по умолчанию)

```yaml
persistentVolumeReclaimPolicy: Retain
```

PV переходит в состояние `Released` и **остаётся в кластере** до ручного удаления администратором. Данные сохраняются. Новый PVC не может автоматически привязаться к этому PV.

Проверка состояния:
```bash
kubectl get pv pv-log
```

```
NAME      CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS     CLAIM                   AGE
pv-log    100Mi      RWX            Retain           Released   default/claim-log-1     9m
```

#### `Delete`

```yaml
persistentVolumeReclaimPolicy: Delete
```

При удалении PVC автоматически удаляется и сам PV, и хранилище за ним (например, AWS EBS volume). Данные теряются.

#### `Recycle` (устаревший)

```yaml
persistentVolumeReclaimPolicy: Recycle
```

Данные на томе стираются (примерно `rm -rf /volume/*`), после чего PV снова становится доступным для новых PVC. Этот режим считается устаревшим и не рекомендуется.

---

### 2.9 Практический пример: хранение логов приложения

Разберём полный сценарий из лабораторной работы — сохранение логов веб-приложения.

#### Шаг 1: Посмотреть логи и убедиться, что они не персистентны

```bash
kubectl exec webapp -- cat /log/app.log
kubectl describe pod webapp
# Видим: нет дополнительных volume
```

#### Шаг 2: Создать PV для хранения логов

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-log
spec:
  capacity:
    storage: 100Mi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /pv/log
```

```bash
kubectl create -f pv.yaml
kubectl get pv
```

#### Шаг 3: Создать PVC

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: claim-log-1
spec:
  accessModes:
    - ReadWriteMany       # важно: должно совпадать с PV!
  resources:
    requests:
      storage: 50Mi
```

```bash
kubectl create -f pvc.yaml
kubectl get pvc
```

#### Шаг 4: Обновить под для использования PVC

```yaml
volumes:
- name: log-volume
  persistentVolumeClaim:
    claimName: claim-log-1
```

```bash
kubectl replace --force -f webapp-pod.yaml
```

Теперь логи пишутся в `/pv/log/app.log` на ноде и сохраняются независимо от жизненного цикла пода.

#### Шаг 5: Проверить поведение при удалении PVC

```bash
# Удаляем PVC
kubectl delete pvc claim-log-1

# Если PVC завис в Terminating — удаляем под
kubectl delete pod webapp

# Проверяем статус PV
kubectl get pv pv-log
# STATUS: Released (данные сохранены, но PV уже не доступен для новых PVC)
```

> **Внимание:** если вы попытаетесь удалить PVC, пока под ещё использует его, PVC зависнет в состоянии `Terminating`. Kubernetes не позволяет удалить ресурс, пока он используется. Сначала нужно удалить под.

---

## Итоги и выводы

### Ключевые концепции Docker:

1. **Слоистая архитектура** — образы состоят из read-only слоёв; Docker кэширует слои и переиспользует их между образами для экономии времени и места.

2. **Copy-on-Write** — writable layer контейнера содержит только изменения; оригинальный образ всегда остаётся нетронутым.

3. **Тома** — единственный надёжный способ хранить данные за пределами жизненного цикла контейнера.

4. **Storage Drivers** (AUFS, Overlay2 и др.) — управляют слоями файловой системы.

5. **Volume Driver Plugins** (local, RexRay, Portworx и др.) — управляют персистентными томами, включая облачные.

### Ключевые концепции Kubernetes:

1. **Volumes** — базовый механизм, позволяет подключить хранилище к поду. Настраивается прямо в спецификации пода.

2. **Persistent Volumes (PV)** — кластерный ресурс хранилища, созданный администратором заранее. Независим от подов.

3. **Persistent Volume Claims (PVC)** — запрос на хранилище от разработчика. Kubernetes автоматически находит и привязывает подходящий PV.

4. **Разделение ответственности** — администратор управляет PV (инфраструктурой), разработчик работает только с PVC (абстракцией).

5. **Reclaim Policies** — определяют судьбу PV после удаления PVC: `Retain` (сохранить), `Delete` (удалить), `Recycle` (очистить и переиспользовать).

### Практические рекомендации:

- `hostPath` — только для разработки и одной ноды, никогда в продакшен с несколькими нодами
- Для продакшена используйте облачные тома (AWS EBS, GCP PD, Azure Disk) или сетевые хранилища (NFS, Ceph)
- Всегда явно задавайте `accessMode` и следите за его совпадением между PV и PVC
- Помните: один PV — один PVC, даже если объём PV больше запрошенного
- При удалении PVC сначала удалите поды, которые его используют, иначе PVC зависнет в `Terminating`

---

# 7.2 - Storage Classes, StatefulSets и Headless Services в Kubernetes: полное руководство

Эта тема является логическим продолжением того, что мы разобрали раньше. Теперь мы поднимаемся на уровень выше: от ручного управления хранилищем к автоматическому, и от простых подов к сложным stateful-приложениям.

---

## Часть 1: Storage Classes (Классы хранилища)

### 1.1 Проблема статического провизионирования

В предыдущей теме мы разбирали, как создавать PV и PVC вручную. Этот подход называется **статическим провизионированием (static provisioning)**. Давайте разберём его ограничения на конкретном примере.

Допустим, вы хотите использовать диск Google Cloud Persistent Disk. Вам нужно:

**Шаг 1 — Создать диск в Google Cloud вручную:**

```bash
gcloud beta compute disks create \
  --size 1GB \
  --region us-east1 \
  pd-disk
```

**Шаг 2 — Создать PV, который описывает этот диск:**

```yaml
# pv-definition.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-vol1
spec:
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 500Mi
  gcePersistentDisk:
    pdName: pd-disk      # должно совпадать с именем диска из шага 1
    fsType: ext4
```

**Шаг 3 — Создать PVC:**

```yaml
# pvc-definition.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: myclaim
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
```

**Шаг 4 — Использовать PVC в поде:**

```yaml
# pod-definition.yaml
apiVersion: v1
kind: Pod
metadata:
  name: random-number-generator
spec:
  containers:
    - image: alpine
      name: alpine
      command: ["/bin/sh", "-c"]
      args: ["shuf -i 0-100 -n 1 >> /opt/number.out;"]
      volumeMounts:
        - mountPath: /opt
          name: data-volume
  volumes:
    - name: data-volume
      persistentVolumeClaim:
        claimName: myclaim
```

**Проблемы этого подхода:**

1. Каждый раз нужно вручную создавать облачный диск через CLI или веб-консоль
2. Затем создавать PV, который ссылается на этот конкретный диск
3. Если у вас десятки или сотни приложений — это превращается в огромную операционную нагрузку
4. Легко допустить ошибку: указать неправильный ID диска, не совпадающий объём и т.д.
5. Разработчики зависят от администраторов на каждый деплой

Именно эту проблему и решают **Storage Classes**.

---

### 1.2 Динамическое провизионирование с Storage Classes

**Storage Class** — это объект Kubernetes, который описывает **как** создавать хранилище. Он задаёт провизионер (provisioner) — плагин, который умеет автоматически создавать диски на конкретной платформе.

Когда PVC ссылается на Storage Class, Kubernetes:
1. Вызывает провизионер
2. Провизионер создаёт реальный диск в облаке (или другом хранилище)
3. Kubernetes автоматически создаёт PV для этого диска
4. PV привязывается к PVC

**Минимальное определение Storage Class для Google Cloud:**

```yaml
# sc-definition.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: google-storage
provisioner: kubernetes.io/gce-pd
```

**PVC, ссылающийся на Storage Class:**

```yaml
# pvc-definition.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: myclaim
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: google-storage    # ← ключевое поле
  resources:
    requests:
      storage: 500Mi
```

**Под остаётся таким же — он по-прежнему использует PVC:**

```yaml
# pod-definition.yaml
apiVersion: v1
kind: Pod
metadata:
  name: random-number-generator
spec:
  containers:
    - image: alpine
      name: alpine
      command: ["/bin/sh", "-c"]
      args: ["shuf -i 0-100 -n 1 >> /opt/number.out;"]
      volumeMounts:
        - mountPath: /opt
          name: data-volume
  volumes:
    - name: data-volume
      persistentVolumeClaim:
        claimName: myclaim
```

Теперь **не нужно** вручную создавать диск в Google Cloud и PV в Kubernetes. Как только PVC создаётся, провизионер делает всё автоматически.

---

### 1.3 Параметры Storage Class

Storage Class можно настраивать с помощью блока `parameters`, который специфичен для каждого провизионера. Для Google Cloud Persistent Disk доступны:

- `type` — тип диска: `pd-standard` (HDD) или `pd-ssd` (SSD)
- `replication-type` — режим репликации: `none` (обычный) или `regional-pd` (региональная репликация, высокая доступность)

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: google-storage
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-standard
  replication-type: none
```

---

### 1.4 Многоуровневые классы хранилища

Реальная мощь Storage Classes проявляется, когда вы создаёте несколько классов с разными характеристиками. Это позволяет предоставить разработчикам выбор уровня обслуживания без знания деталей инфраструктуры.

**Три уровня для Google Cloud:**

| Класс | Тип диска | Репликация | Назначение |
|---|---|---|---|
| Silver | pd-standard (HDD) | Нет | Разработка, тестирование |
| Gold | pd-ssd | Нет | Продакшен, стандартный |
| Platinum | pd-ssd | regional-pd | Продакшен, критические данные |

```yaml
# Класс Silver — стандартный HDD
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: silver
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-standard
  replication-type: none
```

```yaml
# Класс Gold — SSD без репликации
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gold
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-ssd
  replication-type: none
```

```yaml
# Класс Platinum — SSD с региональной репликацией
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: platinum
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-ssd
  replication-type: regional-pd
```

Разработчик просто указывает нужный класс в PVC:

```yaml
spec:
  storageClassName: gold     # хочу SSD для продакшена
  resources:
    requests:
      storage: 10Gi
```

Или:

```yaml
spec:
  storageClassName: silver   # хватит HDD для тестовой среды
  resources:
    requests:
      storage: 1Gi
```

---

### 1.5 Популярные провизионеры

Список провизионеров не ограничивается Google Cloud:

| Провизионер | Платформа |
|---|---|
| `kubernetes.io/gce-pd` | Google Cloud Persistent Disk |
| `kubernetes.io/aws-ebs` | Amazon EBS |
| `kubernetes.io/azure-disk` | Azure Disk |
| `kubernetes.io/azure-file` | Azure File |
| `kubernetes.io/no-provisioner` | Локальные тома (без автопровизионирования) |
| `kubernetes.io/nfs` | NFS |

Также существуют сторонние провизионеры (Portworx, Rook-Ceph, Longhorn и др.).

---

### 1.6 Вывод по Storage Classes

**Статическое провизионирование:** администратор вручную создаёт диск → вручную создаёт PV → разработчик создаёт PVC. Много ручного труда, медленно, легко ошибиться.

**Динамическое провизионирование:** администратор создаёт Storage Class один раз → разработчик создаёт PVC с указанием класса → всё остальное происходит автоматически. Быстро, масштабируемо, меньше ошибок.

---

## Часть 2: Зачем нужны StatefulSets

### 2.1 Жизненный сценарий: репликация MySQL

Чтобы понять, зачем существуют StatefulSets, рассмотрим реальную задачу — развёртывание кластера MySQL с одним мастером и несколькими репликами.

**Физическая топология (вне Kubernetes):**

В типичной конфигурации MySQL используется схема **один мастер — несколько слейвов (single master / multi slave)**:

- **Мастер** — принимает все операции записи (INSERT, UPDATE, DELETE)
- **Слейвы** — обслуживают операции чтения (SELECT); реплицируют данные с мастера

**Процесс настройки (упрощённо):**

1. Запускаем мастер-сервер
2. Клонируем базу данных с мастера на первый слейв
3. Включаем непрерывную репликацию с мастера на первый слейв
4. Как только первый слейв готов — клонируем его данные на второй слейв
5. Включаем репликацию на втором слейве (он также читает с мастера)

**Ключевое требование:** каждый слейв должен знать **стабильный адрес** мастера. Если мастер упадёт и поднимется снова с другим IP — репликация сломается. Именно поэтому нужно использовать стабильное DNS-имя, а не IP-адрес.

---

### 2.2 Почему Deployment не подходит

На первый взгляд, кажется логичным запустить MySQL-кластер как Deployment с тремя репликами. Но здесь есть несколько фундаментальных проблем:

**Проблема 1: Порядок запуска**

Deployment создаёт все поды **одновременно**. В нашем случае мастер должен быть запущен и готов **до** того, как любой слейв начнёт работу. Слейв 1 должен стартовать раньше слейва 2, потому что слейв 2 будет клонировать данные со слейва 1.

С Deployment это невозможно гарантировать.

**Проблема 2: Нестабильные имена подов**

Deployment создаёт поды со случайными суффиксами в именах:
- `mysql-7d8f9c-xkq2p`
- `mysql-7d8f9c-mnb4t`
- `mysql-7d8f9c-rtz8w`

Если мастер-под упадёт и будет пересоздан — он получит **новое случайное имя**. Слейвы, настроенные ссылаться на `MASTER_HOST=mysql-7d8f9c-xkq2p`, потеряют соединение и репликация сломается.

**Проблема 3: Невозможно различить роли**

С Deployment нет предсказуемого способа определить, какой под является мастером, а какой — слейвом. Все поды выглядят одинаково с точки зрения именования.

---

### 2.3 StatefulSet решает все эти проблемы

**StatefulSet** — это Kubernetes-контроллер, похожий на Deployment, но с ключевыми отличиями, специально разработанными для stateful-приложений (приложений с состоянием).

**Что делает StatefulSet:**

1. **Упорядоченный запуск** — поды создаются строго по одному, следующий запускается только когда предыдущий перешёл в состояние `Running and Ready`

2. **Стабильные предсказуемые имена** — поды получают имена вида `<имя-statefulset>-<порядковый номер>`:
   - `mysql-0` (первый под — всегда мастер)
   - `mysql-1` (второй под — первый слейв)
   - `mysql-2` (третий под — второй слейв)

3. **Sticky identity** — если под `mysql-0` упадёт и будет пересоздан, он снова получит имя `mysql-0`. Стабильность имён гарантирована.

4. **Упорядоченное масштабирование вниз** — при уменьшении числа реплик поды удаляются в обратном порядке (последний первым)

Теперь конфигурация слейвов может содержать надёжную ссылку:

```
MASTER_HOST=mysql-0
```

Это имя никогда не изменится, независимо от перезапусков.

---

## Часть 3: StatefulSets — создание и управление

### 3.1 Определение StatefulSet

StatefulSet очень похож на Deployment. Разница в двух вещах:

1. `kind: StatefulSet` вместо `kind: Deployment`
2. Обязательное поле `serviceName` — ссылка на headless service

**Deployment (для сравнения):**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
  labels:
    app: mysql
spec:
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql
```

**StatefulSet (те же данные, другой тип):**

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
  labels:
    app: mysql
spec:
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  serviceName: mysql-h          # ← обязательное дополнительное поле
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql
```

---

### 3.2 Управление StatefulSet

```bash
# Создание
kubectl create -f statefulset-definition.yml

# Масштабирование вверх
kubectl scale statefulset mysql --replicas=5

# Масштабирование вниз
kubectl scale statefulset mysql --replicas=3

# Удаление
kubectl delete statefulset mysql
```

**Поведение при масштабировании вверх (например, с 3 до 5 реплик):**
- Kubernetes создаёт `mysql-3`, ждёт его готовности
- Затем создаёт `mysql-4`

**Поведение при масштабировании вниз (например, с 3 до 1 реплики):**
- Удаляется `mysql-2`, ждём его удаления
- Затем удаляется `mysql-1`
- `mysql-0` остаётся

Это безопасная стратегия: первым удаляется тот, кто был создан последним и имеет наименьшее значение для кластера.

---

### 3.3 Parallel Pod Management Policy

По умолчанию StatefulSet создаёт и удаляет поды последовательно. Если порядок для вашего приложения не важен, но вам всё равно нужны стабильные имена — можно использовать `Parallel` режим:

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
  labels:
    app: mysql
spec:
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  serviceName: mysql-h
  podManagementPolicy: Parallel    # ← все поды стартуют одновременно
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql
```

**Когда использовать `Parallel`:** если у вас есть stateless-приложение, которому просто нужны стабильные сетевые идентификаторы, но порядок инициализации не критичен.

**Когда оставить стандартный `OrderedReady`:** для баз данных, кластеров с репликацией, любых систем где порядок запуска имеет значение.

---

## Часть 4: Headless Services

### 4.1 Проблема с обычными сервисами

Обычный Kubernetes Service работает как балансировщик нагрузки: он получает запрос и случайным образом перенаправляет его на один из подходящих подов.

```
mysql.default.svc.cluster.local → случайный под (mysql-0, mysql-1 или mysql-2)
```

Для HTTP-сервисов это отлично. Но для MySQL-кластера это катастрофа:

- Операции **чтения** можно слать на любой под — это нормально
- Операции **записи** должны идти **только** на мастер (`mysql-0`)

Если балансировщик перенаправит запись на слейв — произойдёт ошибка или, что хуже, рассинхронизация данных.

Нам нужен способ обращаться к **конкретному поду** по имени.

---

### 4.2 Headless Service — решение

**Headless Service** — это обычный Service, у которого в поле `clusterIP` стоит значение `None`. Без Cluster IP он не балансирует трафик, а вместо этого создаёт индивидуальные DNS-записи для каждого пода.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql-h
spec:
  ports:
    - port: 3306
  selector:
    app: mysql
  clusterIP: None      # ← вот и весь секрет headless service
```

**Формат DNS-записей, создаваемых headless service:**

```
<имя-пода>.<имя-сервиса>.<неймспейс>.svc.cluster.local
```

Для нашего MySQL-кластера:
```
mysql-0.mysql-h.default.svc.cluster.local   → всегда мастер
mysql-1.mysql-h.default.svc.cluster.local   → первый слейв
mysql-2.mysql-h.default.svc.cluster.local   → второй слейв
```

Теперь приложения могут обращаться к мастеру напрямую и надёжно.

---

### 4.3 Headless Service с обычными подами (проблема)

Если вы попробуете использовать headless service с обычным Pod или Deployment, возникнет проблема.

**Вариант 1: Под без `hostname` и `subdomain`** — DNS-запись для пода вообще не создаётся.

**Вариант 2: Под с `subdomain` но без `hostname`** — создаётся только запись для сервиса целиком, но не для конкретного пода.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
  labels:
    app: mysql
spec:
  containers:
    - name: mysql
      image: mysql
  subdomain: mysql-h     # ← указываем subdomain
```

**Вариант 3: Под с `hostname` и `subdomain`** — создаётся DNS-запись:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
  labels:
    app: mysql
spec:
  containers:
    - name: mysql
      image: mysql
  subdomain: mysql-h
  hostname: mysql-pod
```

Это создаст запись `mysql-pod.mysql-h.default.svc.cluster.local`.

**Но при использовании Deployment возникает новая проблема:** если вы добавите `hostname: mysql-pod` в шаблон пода Deployment, **все три реплики** получат одинаковое имя `mysql-pod`. Все три будут доступны по одному адресу, а уникальной адресации не будет.

---

### 4.4 StatefulSet + Headless Service = идеальное сочетание

StatefulSet автоматически решает проблему уникальных DNS-имён. Вам не нужно вручную указывать `hostname` и `subdomain` в шаблоне пода — достаточно указать `serviceName` в спецификации StatefulSet:

```yaml
# Headless Service
apiVersion: v1
kind: Service
metadata:
  name: mysql-h
spec:
  ports:
    - port: 3306
  selector:
    app: mysql
  clusterIP: None
```

```yaml
# StatefulSet, ссылающийся на headless service
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql-deployment
  labels:
    app: mysql
spec:
  serviceName: mysql-h        # ← имя headless service
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
        - name: mysql
          image: mysql
```

Kubernetes автоматически создаёт уникальные DNS-записи для каждого пода:

```
mysql-0.mysql-h.default.svc.cluster.local
mysql-1.mysql-h.default.svc.cluster.local
mysql-2.mysql-h.default.svc.cluster.local
```

Каждый под получает стабильный, уникальный, предсказуемый адрес. Конфигурация репликации не сломается никогда.

---

## Часть 5: Хранилище в StatefulSets

### 5.1 Проблема общего тома

Казалось бы, можно просто добавить PVC в StatefulSet так же, как в обычный под. Рассмотрим такой подход:

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
        - name: mysql
          image: mysql
          volumeMounts:
            - mountPath: /var/lib/mysql
              name: data-volume
      volumes:
        - name: data-volume
          persistentVolumeClaim:
            claimName: data-volume   # все поды используют один и тот же PVC!
```

**Что произойдёт:** все три пода (`mysql-0`, `mysql-1`, `mysql-2`) будут смонтировать **один и тот же том**. Они будут писать данные в одно место, перезаписывая друг друга. Это не репликация — это хаос.

Для работы это может быть допустимо только если:
- Хранилище поддерживает конкурентный доступ (`ReadWriteMany`)
- Поды только читают данные из общего хранилища (например, общий датасет)
- Вы намеренно хотите shared storage (например, для общего логирования)

Для базы данных с репликацией это **неприемлемо**: каждый экземпляр MySQL должен иметь свою независимую копию данных.

---

### 5.2 VolumeClaimTemplates — индивидуальное хранилище для каждого пода

Решение — **volumeClaimTemplates**. Это шаблон PVC, встроенный прямо в спецификацию StatefulSet. Kubernetes автоматически создаёт отдельный PVC (и соответственно отдельный PV) для каждого пода.

**Полная конфигурация:**

**Шаг 1: Storage Class (создаётся один раз):**

```yaml
# sc-definition.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: google-storage
provisioner: kubernetes.io/gce-pd
```

**Шаг 2: StatefulSet с volumeClaimTemplates:**

```yaml
# statefulset-definition.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
  labels:
    app: mysql
spec:
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
        - name: mysql
          image: mysql
          volumeMounts:
            - mountPath: /var/lib/mysql
              name: data-volume
  volumeClaimTemplates:             # ← шаблон PVC (не volumes!)
    - metadata:
        name: data-volume
      spec:
        accessModes:
          - ReadWriteOnce
        storageClassName: google-storage
        resources:
          requests:
            storage: 500Mi
```

**Что происходит при создании этого StatefulSet:**

1. Kubernetes создаёт `mysql-0`
2. Для `mysql-0` автоматически создаётся PVC с именем `data-volume-mysql-0`
3. Storage Class `google-storage` автоматически провизионирует GCP-диск
4. PV привязывается к `data-volume-mysql-0`
5. Под `mysql-0` монтирует этот PVC
6. `mysql-0` переходит в `Running`
7. Kubernetes создаёт `mysql-1`
8. Для `mysql-1` автоматически создаётся PVC `data-volume-mysql-1`
9. И так далее...

В итоге получается:

| Под | PVC | PV | Диск GCP |
|---|---|---|---|
| mysql-0 | data-volume-mysql-0 | pv-xxx-0 | pd-disk-0 |
| mysql-1 | data-volume-mysql-1 | pv-xxx-1 | pd-disk-1 |
| mysql-2 | data-volume-mysql-2 | pv-xxx-2 | pd-disk-2 |

Каждый под полностью изолирован в отношении хранилища. Это именно то, что нужно для MySQL-репликации.

---

### 5.3 Стабильность хранилища при перезапуске подов

Одно из важнейших свойств StatefulSet: **PVC не удаляется при перезапуске или пересоздании пода**.

Представьте, что `mysql-1` упал. StatefulSet пересоздаст его. Новый `mysql-1` автоматически получит тот же PVC `data-volume-mysql-1` с теми же данными. Ничего не потеряно, репликация не сломана.

Это поведение принципиально отличается от ephemeral storage обычных подов. StatefulSet гарантирует, что **конкретный под всегда получит своё конкретное хранилище**.

> **Важное замечание:** PVC не удаляется автоматически даже при удалении самого StatefulSet. Это сделано намеренно для защиты данных. Для очистки нужно удалять PVC вручную.

---

### 5.4 Сравнение подходов к хранилищу в StatefulSet

| Подход | Использование | Пример |
|---|---|---|
| Без тома | Stateless-под | Веб-сервер без данных |
| `volumes` с общим PVC | Все поды читают одни данные | Общий датасет для ML-воркеров |
| `volumeClaimTemplates` | Каждому поду своё хранилище | MySQL, Kafka, Elasticsearch |

---

## Общая архитектура: всё вместе

Соберём все концепции в одну картину. Полный стек для MySQL-кластера с репликацией в Kubernetes:

```
Storage Class (google-storage, pd-ssd)
         ↓ автоматически создаёт
PV для каждого пода (pv-0, pv-1, pv-2)
         ↑ автоматически провизионирует
PVC для каждого пода (data-volume-mysql-0, data-volume-mysql-1, data-volume-mysql-2)
         ↑ создаётся через volumeClaimTemplates
StatefulSet (mysql-0 → mysql-1 → mysql-2, строго по порядку)
         ↑ уникальные DNS-записи
Headless Service (mysql-h, clusterIP: None)
```

**Клиентское приложение:**
- Запись: обращается к `mysql-0.mysql-h.default.svc.cluster.local` (всегда мастер)
- Чтение: обращается к `mysql.default.svc.cluster.local` через обычный Service (любой под)

---

## Итоги и ключевые выводы

### Storage Classes

- Решают проблему ручного создания дисков и PV (статическое провизионирование)
- Провизионер автоматически создаёт хранилище при создании PVC
- Позволяют создавать уровни обслуживания (Silver/Gold/Platinum) с разными характеристиками
- PVC просто указывает `storageClassName` — всё остальное автоматически

### StatefulSets

- Нужны когда приложению важен **порядок запуска**, **стабильные имена** и **персистентные идентичности**
- Поды получают имена `<statefulset-name>-0`, `<statefulset-name>-1` и т.д.
- Запуск строго последовательный: следующий под стартует только когда предыдущий готов
- При пересоздании под всегда получает то же имя
- `podManagementPolicy: Parallel` — для случаев когда порядок не важен, но нужны стабильные имена

### Headless Services

- Обычный Service с `clusterIP: None`
- Не балансирует нагрузку, создаёт индивидуальные DNS-записи для каждого пода
- Формат: `<pod>.<service>.<namespace>.svc.cluster.local`
- Со StatefulSet работает автоматически через поле `serviceName`
- С Deployment все поды получат одинаковый DNS-адрес — это проблема

### Хранилище в StatefulSets

- `volumes` с общим PVC — все поды читают/пишут в одно место (только при необходимости)
- `volumeClaimTemplates` — для каждого пода автоматически создаётся свой PVC и PV
- При перезапуске пода его PVC сохраняется и переподключается автоматически
- PVC не удаляется при удалении StatefulSet — требует ручной очистки

### Практические рекомендации

- Для stateless-приложений (HTTP-сервисы, API) — используйте Deployment
- Для stateful-приложений с репликацией (MySQL, PostgreSQL, Kafka, Elasticsearch, Zookeeper) — используйте StatefulSet
- Всегда комбинируйте StatefulSet с Headless Service
- Для индивидуального хранилища каждого пода используйте `volumeClaimTemplates` вместо `volumes`
- Для production используйте Storage Classes с динамическим провизионированием вместо ручного создания PV

---

# 8.1 - Безопасность в Kubernetes: Аутентификация, Авторизация и Управление доступом

---

## Часть 1: Аутентификация (Authentication)

### Что такое аутентификация и зачем она нужна?

Kubernetes-кластер — это сложная система, к которой обращаются самые разные участники:

- **Администраторы** — управляют узлами, конфигурацией, сетью
- **Разработчики** — деплоят приложения, работают с подами
- **Сторонние приложения (боты)** — автоматизированные процессы, CI/CD системы
- **Конечные пользователи** — взаимодействуют с уже задеплоенными приложениями

Аутентификация — это процесс подтверждения личности: *кто ты такой?* Прежде чем выполнить любой запрос, **kube-apiserver** проверяет, действительно ли ты тот, за кого себя выдаёшь.

Важный момент: Kubernetes **не управляет учётными записями пользователей самостоятельно**. Он интегрируется с внешними источниками:
- CSV-файлы с паролями или токенами
- Центры сертификации (CA)
- Сторонние провайдеры идентификации: LDAP, Kerberos, OIDC

Сервисные аккаунты (Service Accounts) — исключение: ими Kubernetes управляет напрямую через API.

---

### Механизм 1: Статический файл паролей (Static Password File)

Это самый простой, но и самый небезопасный способ. Создаётся CSV-файл с четырьмя полями:

```
пароль, имя_пользователя, идентификатор_пользователя, [группа — опционально]
```

**Пример файла `user-details.csv`:**

```csv
password123,user1,u0001
password123,user2,u0002,group1
password123,user3,u0003,group1
password123,user4,u0004,group2
password123,user5,u0005
```

Четвёртая колонка (группа) необязательна, но позволяет группировать пользователей для удобства управления правами.

Чтобы kube-apiserver использовал этот файл, нужно передать флаг `--basic-auth-file`:

**Вариант 1 — через systemd-сервис:**

```bash
ExecStart=/usr/local/bin/kube-apiserver \
    --advertise-address=${INTERNAL_IP} \
    --allow-privileged=true \
    --authorization-mode=Node,RBAC \
    --etcd-servers=https://127.0.0.1:2379 \
    --service-cluster-ip-range=10.32.0.0/24 \
    --basic-auth-file=user-details.csv   # <-- добавляем этот флаг
```

**Вариант 2 — через манифест kubeadm (`/etc/kubernetes/manifests/kube-apiserver.yaml`):**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kube-apiserver
  namespace: kube-system
spec:
  containers:
  - name: kube-apiserver
    image: k8s.gcr.io/kube-apiserver-amd64:v1.11.3
    command:
    - kube-apiserver
    - --authorization-mode=Node,RBAC
    - --basic-auth-file=user-details.csv   # <-- добавляем
```

В kubeadm-кластере после изменения манифеста kube-apiserver перезапускается автоматически.

**Как использовать такую аутентификацию в запросах:**

```bash
curl -v -k https://master-node-ip:6443/api/v1/pods \
  -u "user1:password123"
```

---

### Механизм 2: Статический файл токенов (Static Token File)

Работает аналогично файлу паролей, но вместо пароля используется токен — длинная случайная строка.

**Пример файла `user-token-details.csv`:**

```csv
KpjCvB7rcFAHYPKByTIZRb7gulcUc4B,user10,u0010,group1
rJJncHmvtxHc6M1WQddhtvNyhgTdxSC,user11,u0011,group1
mjpOFTEiFOKL9toikaRNTt59ePtczZSq,user12,u0012,group2
PG411Xhs7QjqWKmBkvgGT9glOyUqZij,user13,u0013,group2
```

Флаг для kube-apiserver:

```bash
--token-auth-file=user-token-details.csv
```

**Как использовать токен в HTTP-запросе:**

```bash
curl -v -k https://master-node-ip:6443/api/v1/pods \
  --header "Authorization: Bearer KpjCvB7rcFAHYPKByTIZRb7gulcUc4B"
```

Токен передаётся в заголовке `Authorization` с префиксом `Bearer`.

---

### Механизм 3: Сертификаты (Certificates)

Это рекомендуемый способ аутентификации. Каждый пользователь получает клиентский сертификат, подписанный центром сертификации кластера. При запросе передаётся:
- `--key` — приватный ключ пользователя
- `--cert` — сертификат пользователя
- `--cacert` — сертификат CA для проверки сервера

```bash
curl https://my-kube-playground:6443/api/v1/pods \
  --key admin.key \
  --cert admin.crt \
  --cacert ca.crt
```

---

### ⚠️ Важное предупреждение о статических файлах

Статические файлы паролей и токенов **категорически не рекомендуются для продакшн-сред**, потому что:

1. Пароли и токены хранятся в **открытом виде** (plain text)
2. Для изменения прав нужно **перезапускать kube-apiserver**
3. Нет поддержки ротации паролей
4. Нет аудит-лога попыток входа

---

## Часть 2: KubeConfig — управление конфигурацией подключения

### Проблема, которую решает kubeconfig

Представь, что каждый раз при вызове `kubectl` тебе нужно вводить:

```bash
kubectl get pods \
  --server my-kube-playground:6443 \
  --client-key admin.key \
  --client-certificate admin.crt \
  --certificate-authority ca.crt
```

Это утомительно и ведёт к ошибкам. Kubeconfig — это файл конфигурации, который хранит все эти параметры, позволяя запускать просто:

```bash
kubectl get pods
```

По умолчанию kubectl ищет файл `~/.kube/config`.

---

### Структура kubeconfig

Файл состоит из трёх секций:

#### 1. `clusters` — описание кластеров

Здесь перечислены все кластеры, к которым ты можешь подключаться: продакшн, разработка, тестирование, облачные провайдеры.

#### 2. `users` — описание пользователей

Здесь хранятся учётные данные (сертификаты, ключи) различных пользователей.

#### 3. `contexts` — связь между кластерами и пользователями

Контекст — это именованная пара «пользователь + кластер». Например, `admin@production` означает: подключаться к кластеру `production` с учётными данными пользователя `admin`.

---

### Полный пример kubeconfig

```yaml
apiVersion: v1
kind: Config
current-context: my-kube-admin@my-kube-playground  # активный контекст

clusters:
- name: my-kube-playground
  cluster:
    certificate-authority: /etc/kubernetes/pki/ca.crt
    server: https://172.17.0.5:6443
- name: development
  cluster:
    certificate-authority: /etc/kubernetes/pki/ca.crt
    server: https://dev-server:6443
- name: production
  cluster:
    certificate-authority: /etc/kubernetes/pki/ca.crt
    server: https://prod-server:6443

contexts:
- name: my-kube-admin@my-kube-playground
  context:
    cluster: my-kube-playground
    user: my-kube-admin
- name: dev-user@development
  context:
    cluster: development
    user: dev-user
- name: prod-user@production
  context:
    cluster: production
    user: prod-user
    namespace: finance   # опционально: namespace по умолчанию

users:
- name: my-kube-admin
  user:
    client-certificate: /etc/kubernetes/pki/admin.crt
    client-key: /etc/kubernetes/pki/admin.key
- name: dev-user
  user:
    client-certificate: /etc/kubernetes/pki/users/dev-user/dev-user.crt
    client-key: /etc/kubernetes/pki/users/dev-user/dev-user.key
- name: prod-user
  user:
    client-certificate: /etc/kubernetes/pki/users/prod-user/prod-user.crt
    client-key: /etc/kubernetes/pki/users/prod-user/prod-user.key
```

---

### Основные операции с kubeconfig

**Просмотр текущего конфига:**

```bash
kubectl config view
```

**Просмотр конкретного файла:**

```bash
kubectl config view --kubeconfig=/root/my-kube-config
```

**Переключение контекста:**

```bash
kubectl config use-context prod-user@production
```

После этой команды поле `current-context` в файле изменится на `prod-user@production`.

**Переключение контекста в конкретном файле (не затрагивая дефолтный):**

```bash
kubectl config use-context research --kubeconfig /root/my-kube-config
```

**Сделать кастомный конфиг дефолтным:**

```bash
mv /root/my-kube-config /root/.kube/config
```

**Обновить учётные данные пользователя:**

```bash
kubectl config set-credentials dev-user \
  --client-certificate=/etc/kubernetes/pki/users/dev-user/dev-user.crt \
  --client-key=/etc/kubernetes/pki/users/dev-user/dev-user.key
```

---

### Namespace в контексте

Если в контексте указан namespace, то при переключении на этот контекст все команды kubectl будут выполняться в указанном namespace автоматически:

```yaml
contexts:
- name: admin@production
  context:
    cluster: production
    user: admin
    namespace: finance   # теперь kubectl get pods покажет поды из namespace finance
```

---

### Два способа хранить сертификаты в kubeconfig

**Способ 1 — путь к файлу (рекомендуется):**

```yaml
clusters:
- name: production
  cluster:
    certificate-authority: /etc/kubernetes/pki/ca.crt
    server: https://prod:6443
```

**Способ 2 — встроенные данные в base64:**

```yaml
clusters:
- name: production
  cluster:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0t...
    server: https://prod:6443
```

Для получения base64-строки из файла:

```bash
cat ca.crt | base64 -w 0
```

Для декодирования:

```bash
echo "LS0tLS1CRUdJTiBDRVJU..." | base64 --decode
```

---

### Диагностика: ошибка client-certificate mismatch

Распространённая проблема — kubeconfig ссылается на файл сертификата с одним именем, а на диске файл называется иначе.

**Ошибка:**

```
error: unable to read client-cert /etc/kubernetes/pki/users/dev-user/developer-user.crt
for dev-user due to open .../developer-user.crt: no such file or directory
```

**Диагностика:**

```bash
ls /etc/kubernetes/pki/users/dev-user/
# Вывод: dev-user.crt  dev-user.csr  dev-user.key
```

Файл называется `dev-user.crt`, а не `developer-user.crt`. Исправляем:

```bash
kubectl config set-credentials dev-user \
  --client-certificate=/etc/kubernetes/pki/users/dev-user/dev-user.crt \
  --client-key=/etc/kubernetes/pki/users/dev-user/dev-user.key
```

---

## Часть 3: API Groups — организация Kubernetes API

### Зачем нужны API Groups?

Kubernetes API огромен. Чтобы управлять этим масштабом, все ресурсы разбиты на группы. Это помогает:
- Версионировать разные части API независимо
- Масштабировать и расширять API через CRD
- Логически группировать связанные ресурсы

Точкой входа является kube-apiserver, обычно на порту **6443**.

---

### Проверка версии кластера:

```bash
curl https://kube-master:6443/version
```

```json
{
  "major": "1",
  "minor": "13",
  "gitVersion": "v1.13.0",
  "gitCommit": "ddd47ac13c1a9483ea035a79cd7c1005ff21a6d",
  "goVersion": "go1.11.2",
  "platform": "linux/amd64"
}
```

---

### Служебные эндпоинты API

| Эндпоинт | Назначение |
|----------|-----------|
| `/version` | Версия кластера |
| `/metrics` | Метрики для мониторинга |
| `/healthz` | Проверка здоровья кластера |
| `/logs` | Интеграция с системами логирования |
| `/api` | Core API Group |
| `/apis` | Named API Groups |

---

### Core API Group (`/api/v1`)

Содержит фундаментальные ресурсы Kubernetes:

- `namespaces`
- `pods`
- `replicationcontrollers`
- `events`
- `endpoints`
- `nodes`
- `bindings`
- `persistentvolumes`
- `persistentvolumeclaims`
- `configmaps`
- `secrets`
- `services`

Пример запроса к Core API:

```bash
curl https://kube-master:6443/api/v1/pods
```

---

### Named API Groups (`/apis`)

Более новые ресурсы организованы в именованные группы:

| Группа | Ресурсы |
|--------|---------|
| `apps` | Deployments, ReplicaSets, StatefulSets, DaemonSets |
| `networking.k8s.io` | NetworkPolicies, Ingresses |
| `storage.k8s.io` | StorageClasses, VolumeAttachments |
| `rbac.authorization.k8s.io` | Roles, RoleBindings, ClusterRoles |
| `batch` | Jobs, CronJobs |
| `autoscaling` | HorizontalPodAutoscaler |
| `certificates.k8s.io` | CertificateSigningRequests |

---

### Verbs (действия над ресурсами)

Каждый ресурс поддерживает набор операций — **verbs**:

| Verb | Описание |
|------|----------|
| `list` | Получить список ресурсов |
| `get` | Получить конкретный ресурс |
| `create` | Создать ресурс |
| `update` | Обновить ресурс |
| `patch` | Частично обновить ресурс |
| `delete` | Удалить ресурс |
| `watch` | Подписаться на изменения |

---

### Доступ к API

**С сертификатами:**

```bash
curl https://localhost:6443 -k \
  --key admin.key \
  --cert admin.crt \
  --cacert ca.crt
```

**Через kubectl proxy (удобнее — использует учётные данные из kubeconfig):**

```bash
# Запускаем прокси
kubectl proxy
# Вывод: Starting to serve on 127.0.0.1:8001

# Теперь обращаемся без сертификатов
curl http://localhost:8001/apis/apps/v1
```

---

### ⚠️ Не путать kubectl proxy и kube-proxy!

| | kubectl proxy | kube-proxy |
|---|---|---|
| **Что делает** | Проксирует запросы к API-серверу | Управляет сетевыми правилами между подами |
| **Где работает** | На машине пользователя | На каждом узле кластера |
| **Порт** | 8001 (локально) | Нет фиксированного порта |
| **Зачем** | Удобный доступ к API без сертификатов | Networking между сервисами |

---

## Часть 4: Authorization — авторизация

### Аутентификация vs Авторизация

- **Аутентификация** — *кто ты?* (проверка личности)
- **Авторизация** — *что тебе можно делать?* (проверка прав)

После того как kube-apiserver убедился, что пользователь — это действительно тот, за кого себя выдаёт, начинается авторизация: может ли этот пользователь выполнить запрошенное действие?

---

### Механизмы авторизации в Kubernetes

#### 1. Node Authorization

Специальный механизм для **kubelet'ов** (агентов на узлах). Kubelet'ы регулярно отправляют данные о состоянии узлов и подов на kube-apiserver.

Правило: если запрос приходит от пользователя с именем вида `system:node:node-name`, принадлежащего группе `system:nodes`, он обрабатывается Node Authorizer'ом.

#### 2. ABAC (Attribute-Based Access Control)

Разрешения описываются в JSON-файле политик и привязываются к конкретным пользователям или группам:

```json
{"kind": "Policy", "spec": {"user": "dev-user", "namespace": "*", "resource": "pods", "apiGroup": "*"}}
{"kind": "Policy", "spec": {"user": "dev-user-2", "namespace": "*", "resource": "pods", "apiGroup": "*"}}
{"kind": "Policy", "spec": {"group": "dev-users", "namespace": "*", "resource": "pods", "apiGroup": "*"}}
```

**Минусы ABAC:**
- При изменении прав нужно редактировать файл и **перезапускать kube-apiserver**
- Плохо масштабируется
- Трудно управлять при большом числе пользователей

#### 3. RBAC (Role-Based Access Control) — рекомендуемый способ

Вместо привязки прав напрямую к пользователям создаются **роли** (наборы разрешений), которые затем назначаются пользователям. Это гибко и масштабируемо.

#### 4. Webhook

Авторизация делегируется **внешнему сервису**. Kubernetes отправляет запрос с данными пользователя и действия во внешний сервис (например, Open Policy Agent), который отвечает: разрешить или запретить.

```
Пользователь → kube-apiserver → Webhook (OPA) → Разрешить/Запретить
```

#### 5. AlwaysAllow / AlwaysDeny

- `AlwaysAllow` — разрешает **все** запросы без проверки (дефолт, если режим не указан)
- `AlwaysDeny` — запрещает **все** запросы

Полезны только для тестирования, никогда не используются в продакшне.

---

### Настройка режима авторизации

Режим задаётся флагом `--authorization-mode` при запуске kube-apiserver:

**Один режим:**

```bash
--authorization-mode=AlwaysAllow
```

**Несколько режимов (цепочка):**

```bash
--authorization-mode=Node,RBAC,Webhook
```

При цепочке запрос проходит через механизмы **последовательно** слева направо. Как только один из них **одобряет** запрос — обработка останавливается и доступ предоставляется. Если все **отклоняют** — запрос запрещается.

```
Запрос → Node authorizer → RBAC → Webhook → Результат
          (отклонил)     (одобрил) (не дошло)
```

---

## Часть 5: RBAC — Role-Based Access Control

### Концепция RBAC

RBAC — это система управления доступом, основанная на ролях. Вместо того чтобы назначать права каждому пользователю индивидуально, создаются **роли** с наборами разрешений, а потом эти роли назначаются пользователям через **RoleBinding**.

**Преимущества:**
- Изменение роли мгновенно применяется ко всем пользователям с этой ролью
- Нет нужды перезапускать kube-apiserver
- Легко аудировать: видно, какие права есть у каждой роли
- Масштабируется на большие организации

---

### Создание Role

Role — это namespace-scoped объект. Он действует только внутри одного namespace.

**Файл `developer-role.yaml`:**

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer
  namespace: default     # если не указать — используется current namespace
rules:
- apiGroups: [""]        # "" означает core API group (pods, services, configmaps...)
  resources: ["pods"]
  verbs: ["list", "get", "create", "update", "delete"]

- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["create"]

- apiGroups: ["apps"]    # Named API group для deployments
  resources: ["deployments"]
  verbs: ["list", "get", "create", "update"]
```

**Применение:**

```bash
kubectl create -f developer-role.yaml
```

**Или через команду (без YAML):**

```bash
kubectl create role developer \
  --verb=list,create,delete \
  --resource=pods
```

---

### Создание RoleBinding

RoleBinding связывает роль с конкретным пользователем (или группой, или service account).

**Файл `devuser-developer-binding.yaml`:**

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: devuser-developer-binding
  namespace: default
subjects:
- kind: User                          # тип субъекта: User, Group или ServiceAccount
  name: dev-user                      # имя пользователя
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role                          # ссылаемся на Role (не ClusterRole)
  name: developer                     # имя роли
  apiGroup: rbac.authorization.k8s.io
```

**Применение:**

```bash
kubectl create -f devuser-developer-binding.yaml
```

**Или через команду:**

```bash
kubectl create rolebinding dev-user-binding \
  --role=developer \
  --user=dev-user
```

---

### Просмотр и описание ролей

**Список ролей в текущем namespace:**

```bash
kubectl get roles
# NAME        AGE
# developer   4s
```

**Список ролей во всех namespace:**

```bash
kubectl get roles -A --no-headers | wc -l
# 12
```

**Детали роли:**

```bash
kubectl describe role developer
# Name:         developer
# PolicyRule:
#   Resources    Verbs
#   --------     -----
#   configmaps   [create]
#   pods         [get watch list create delete]
```

**Список RoleBinding:**

```bash
kubectl get rolebindings
```

**Детали RoleBinding:**

```bash
kubectl describe rolebinding devuser-developer-binding
# Subjects:
#   Kind   Name       Namespace
#   ----   ----       ---------
#   User   dev-user
```

---

### Проверка прав доступа

**Проверка своих прав:**

```bash
kubectl auth can-i create deployments
# yes

kubectl auth can-i delete nodes
# no
```

**Проверка прав другого пользователя (от имени администратора):**

```bash
kubectl auth can-i create pods --as dev-user
# yes

kubectl auth can-i delete nodes --as dev-user
# no

kubectl auth can-i create deployments --as dev-user
# no
```

**Проверка прав в конкретном namespace:**

```bash
kubectl auth can-i get pods --as dev-user --namespace blue
```

---

### Ограничение доступа до конкретных ресурсов (resourceNames)

Если нужно разрешить доступ не ко всем подам, а только к конкретным (например, только к поду `blue` и поду `orange`):

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "create", "update"]
  resourceNames: ["blue", "orange"]   # только эти два пода!
```

Теперь `dev-user` сможет делать get/create/update только для подов с именами `blue` и `orange`. Попытка получить любой другой под будет отклонена.

---

### Реальный пример: настройка прав в namespace `blue`

Допустим, `dev-user` пытается получить под `dark-blue-app` в namespace `blue`:

```bash
kubectl --as dev-user get pod dark-blue-app -n blue
# Error from server (Forbidden): pods "dark-blue-app" is forbidden:
# User "dev-user" cannot get resource "pods" in API group ""
# in the namespace "blue"
```

Текущая роль `developer` в namespace `blue` не имеет нужных прав. Обновляем:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer
  namespace: blue
rules:
- apiGroups: [""]
  resources: ["pods"]
  resourceNames: ["dark-blue-app"]    # только этот под
  verbs: ["get", "watch", "create", "delete"]

- apiGroups: ["apps"]                 # разрешаем управление deployments
  resources: ["deployments"]
  verbs: ["get", "watch", "create", "delete"]
```

Применяем и проверяем:

```bash
kubectl --as dev-user create deployment nginx --image=nginx -n blue
# deployment.apps/nginx created   ✓
```

---

### Роль kube-proxy: пример минимальных прав

Это хороший пример принципа наименьших привилегий:

```bash
kubectl describe role kube-proxy -n kube-system
# PolicyRule:
#   Resources    Resource Names   Verbs
#   ---------    --------------   -----
#   configmaps   [kube-proxy]     [get]
```

`kube-proxy` может только **читать** (`get`) **один конкретный** ConfigMap с именем `kube-proxy`. Ничего больше. Это именно тот минимум, который нужен для работы.

---

## Итоги и выводы

### Общая картина безопасности Kubernetes

```
Запрос → kube-apiserver
           ↓
      Аутентификация (кто ты?)
      [пароль / токен / сертификат / LDAP]
           ↓
      Авторизация (что тебе можно?)
      [Node → RBAC → Webhook]
           ↓
      Admission Controllers (дополнительные проверки)
           ↓
      Выполнение запроса
```

### Рекомендации по безопасности

1. **Никогда не используй статические файлы паролей/токенов в продакшне** — только сертификаты или внешние провайдеры идентификации

2. **Используй RBAC** — это стандарт де-факто для управления доступом в Kubernetes

3. **Принцип наименьших привилегий** — давай пользователям и сервисам только те права, которые им действительно нужны

4. **Ограничивай namespace** — используй namespace-scoped роли там, где это возможно, вместо ClusterRole

5. **Используй `resourceNames`** — если пользователю нужен доступ к конкретным ресурсам, а не ко всему типу

6. **Регулярно аудируй права** — используй `kubectl auth can-i` и `kubectl describe rolebinding` для проверки

7. **Храни kubeconfig безопасно** — ограничь права на чтение файла `~/.kube/config`, там хранятся ключи доступа

8. **Используй `kubectl proxy` вместо прямых curl-запросов** — это безопаснее, чем хранить флаги с путями к сертификатам в истории командной строки

---

# 8.2 - Cluster Roles, Admission Controllers и Webhook-контроллеры в Kubernetes

---

## Часть 1: Cluster Roles и ClusterRoleBindings

### Namespace-scoped vs Cluster-scoped ресурсы

Прежде чем разбираться с Cluster Roles, нужно понять фундаментальное различие между двумя категориями ресурсов в Kubernetes.

**Namespace-scoped ресурсы** — существуют внутри конкретного namespace:
- Pods
- ReplicaSets
- Deployments
- Services
- Secrets
- ConfigMaps
- PersistentVolumeClaims
- Roles
- RoleBindings

**Cluster-scoped ресурсы** — существуют на уровне всего кластера, вне namespace:
- Nodes (узлы)
- PersistentVolumes (не Claims, а сами тома)
- Namespaces (сами объекты namespace)
- CertificateSigningRequests
- ClusterRoles
- ClusterRoleBindings
- StorageClasses

Чтобы увидеть полный список ресурсов по категориям, используй команды:

```bash
# Namespace-scoped ресурсы
kubectl api-resources --namespaced=true

# Cluster-scoped ресурсы
kubectl api-resources --namespaced=false
```

---

### Почему нельзя обойтись обычными Role?

Обычная `Role` — namespace-scoped объект. Это означает:

- Она даёт права только внутри одного конкретного namespace
- Она **не может** управлять cluster-scoped ресурсами (например, Nodes)

Если пользователю нужно управлять узлами или persistent volumes, которые существуют на уровне всего кластера, обычная Role просто не подходит. Для этого и нужны **ClusterRole** и **ClusterRoleBinding**.

---

### ClusterRole — что это и как создаётся

ClusterRole по структуре идентична обычной Role, но:
- Она существует на уровне кластера (нет поля `namespace` в metadata)
- Она может управлять cluster-scoped ресурсами
- Применённая через ClusterRoleBinding — даёт права во **всех** namespace сразу

**Пример: ClusterRole для администратора кластера**

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-administrator
rules:
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["list", "get", "create", "delete"]
```

**Пример: ClusterRole для администратора хранилища**

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: storage-admin
rules:
- apiGroups: [""]
  resources: ["persistentvolumes"]
  verbs: ["list", "create", "get", "watch"]
- apiGroups: ["storage.k8s.io"]
  resources: ["storageclasses"]
  verbs: ["list", "create", "get", "watch"]
```

Обрати внимание: `persistentvolumes` — в core API group (пустая строка), а `storageclasses` — в группе `storage.k8s.io`. Kubernetes автоматически разобьёт это на два правила, что видно в YAML-выводе после создания.

---

### ClusterRoleBinding — привязка роли к пользователю

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-admin-role-binding
subjects:
- kind: User
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-administrator
  apiGroup: rbac.authorization.k8s.io
```

Применяем оба объекта:

```bash
kubectl create -f cluster-role.yaml
kubectl create -f cluster-role-binding.yaml
```

Или через одну команду (поместив оба объекта в один файл через `---`):

```bash
kubectl create -f combined.yaml
```

---

### Императивный способ создания (без YAML)

**Создать ClusterRole:**

```bash
kubectl create clusterrole michelle-role \
  --verb=get,list,watch \
  --resource=nodes
```

**Создать ClusterRoleBinding:**

```bash
kubectl create clusterrolebinding michelle-role-binding \
  --clusterrole=michelle-role \
  --user=michelle
```

**Создать ClusterRole для хранилища:**

```bash
kubectl create clusterrole storage-admin \
  --resource=persistentvolumes,storageclasses \
  --verb=list,create,get,watch
```

**Привязать роль хранилища к пользователю:**

```bash
kubectl create clusterrolebinding michelle-storage-admin \
  --user=michelle \
  --clusterrole=storage-admin
```

---

### Полный сценарий: создание прав для пользователя Michelle

**Шаг 1: Проверяем начальное состояние — Michelle не может работать с узлами:**

```bash
kubectl get nodes --as michelle
# Error from server (Forbidden): nodes is forbidden:
# User "michelle" cannot list resource "nodes" in API group ""
# at the cluster scope
```

**Шаг 2: Создаём ClusterRole:**

```bash
kubectl create clusterrole michelle-role --verb=get,list,watch --resource=nodes
```

**Шаг 3: Проверяем созданную роль:**

```bash
kubectl describe clusterrole michelle-role
# PolicyRule:
#   Resources   Verbs
#   ---------   -----
#   nodes       [get list watch]
```

**Шаг 4: Создаём ClusterRoleBinding:**

```bash
kubectl create clusterrolebinding michelle-role-binding \
  --clusterrole=michelle-role \
  --user=michelle
```

**Шаг 5: Проверяем привязку:**

```bash
kubectl describe clusterrolebinding michelle-role-binding
# Role:
#   Kind:  ClusterRole
#   Name:  michelle-role
# Subjects:
#   Kind   Name
#   ----   ----
#   User   michelle
```

**Шаг 6: Проверяем доступ:**

```bash
kubectl get nodes --as michelle
# NAME           STATUS   ROLES                  AGE   VERSION
# controlplane   Ready    control-plane,master   16m   v1.23.3+k3s1
```

---

### Встроенные ClusterRoles в Kubernetes

Kubernetes при установке автоматически создаёт десятки ClusterRoles. Посмотрим на них:

```bash
kubectl get clusterroles --no-headers | wc -l
# 69 (количество может отличаться)

kubectl get clusterrolebindings --no-headers | wc -l
# 54
```

Наиболее важные из них:

| ClusterRole | Назначение |
|-------------|-----------|
| `cluster-admin` | Полный доступ ко всему в кластере |
| `system:node` | Права для kubelet'ов на узлах |
| `system:kube-scheduler` | Права для планировщика |
| `system:monitoring` | Права для мониторинга |
| `system:discovery` | Права для обнаружения API |
| `view` | Только чтение всех ресурсов |
| `edit` | Чтение и изменение ресурсов |
| `admin` | Полный доступ в namespace |

**Самая мощная роль — `cluster-admin`:**

```bash
kubectl describe clusterrolebinding cluster-admin
# Role:
#   Kind:  ClusterRole
#   Name:  cluster-admin
# Subjects:
#   Kind    Name
#   ----    ----
#   Group   system:masters
```

Группа `system:masters` автоматически получает права `[*]` — то есть **все возможные действия над всеми ресурсами**. Именно поэтому пользователи с сертификатом, принадлежащим к этой группе (как правило, это `kubernetes-admin`), могут делать всё что угодно.

---

### Важный нюанс: ClusterRole для namespace-ресурсов

ClusterRole можно применять не только к cluster-scoped ресурсам, но и к namespace-scoped. Разница с обычной Role в том, что ClusterRole через ClusterRoleBinding даёт права **во всех namespace одновременно**:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pod-reader-all-namespaces
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```

Если привязать эту роль через ClusterRoleBinding — пользователь сможет читать поды во **всех** namespace кластера. Если привязать через обычный RoleBinding в конкретном namespace — доступ будет ограничен этим namespace.

---

### Просмотр и управление ClusterRoles

```bash
# Список всех cluster roles
kubectl get clusterroles

# Описание конкретной роли
kubectl describe clusterrole cluster-admin

# Поиск ролей, связанных с конкретным пользователем
kubectl get clusterrolebindings | grep michelle

# Проверить права
kubectl auth can-i list nodes --as michelle
# yes

kubectl auth can-i delete nodes --as michelle
# no
```

---

## Часть 2: Admission Controllers

### Что такое Admission Controllers и зачем они нужны?

После того как запрос прошёл **аутентификацию** (кто ты?) и **авторизацию** (что тебе можно?), он попадает к **Admission Controllers** — третьему рубежу безопасности.

Admission Controllers — это плагины, которые перехватывают запросы к kube-apiserver **до** того, как объект будет сохранён в etcd. Они позволяют реализовать политики, которые невозможно выразить через RBAC.

**Полный поток обработки запроса:**

```
kubectl / API-запрос
        ↓
  kube-apiserver
        ↓
  Аутентификация (кто ты?)
        ↓
  Авторизация / RBAC (что тебе можно?)
        ↓
  Admission Controllers (дополнительные проверки и мутации)
        ↓
  Сохранение в etcd
        ↓
  Создание объекта
```

---

### Что RBAC не может сделать?

RBAC работает на уровне: "может ли пользователь X выполнить операцию Y над ресурсом Z". Но RBAC не может проверить **содержимое** запроса. Примеры ограничений:

- RBAC не может запретить использование образов из Docker Hub (только из внутреннего реестра)
- RBAC не может запретить тег `latest` у образов
- RBAC не может запретить запуск контейнеров от root
- RBAC не может автоматически добавлять labels к создаваемым объектам
- RBAC не может проверить, что у PVC указан storage class

Именно для таких сценариев и нужны Admission Controllers.

---

### Встроенные Admission Controllers

**Always Pull Images**
Гарантирует, что при каждом создании пода образ будет заново скачан из реестра. Полезно для обеспечения актуальности образов и проверки прав доступа к приватным реестрам.

**Default Storage Class**
Если PVC создаётся без указания `storageClassName`, этот контроллер автоматически добавляет дефолтный storage class. Пример:

```yaml
# Запрос (без storageClassName)
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: myclaim
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
```

После обработки контроллером объект будет содержать:

```yaml
spec:
  storageClassName: default   # добавлено автоматически!
```

**Event Rate Limit**
Ограничивает количество запросов к API-серверу, предотвращая его перегрузку.

**NamespaceLifecycle** (заменил устаревшие NamespaceExists и NamespaceAutoProvision)
- Отклоняет создание ресурсов в несуществующих namespace
- Защищает системные namespace (`default`, `kube-system`, `kube-public`) от удаления

**NodeRestriction**
Ограничивает, какие labels и аннотации kubelet может устанавливать на узлах. Предотвращает kubelet'у изменять метаданные других узлов.

**LimitRanger**
Автоматически устанавливает дефолтные requests/limits для контейнеров, если они не указаны.

**ServiceAccount**
Автоматически монтирует service account токен в поды.

**ResourceQuota**
Следит за тем, чтобы суммарное потребление ресурсов в namespace не превышало квоту.

---

### Пример: проверка существования namespace

```bash
kubectl run nginx --image nginx --namespace blue
# Error from server (NotFound): namespaces "blue" not found
```

Запрос прошёл аутентификацию и авторизацию — у пользователя есть право создавать поды. Но Admission Controller `NamespaceLifecycle` (или устаревший `NamespaceExists`) проверил, что namespace `blue` не существует, и отклонил запрос.

---

### Просмотр активных Admission Controllers

**Получить список дефолтно включённых плагинов:**

```bash
# Если kube-apiserver запущен как binary
kube-apiserver -h | grep enable-admission-plugins

# Если kube-apiserver запущен как под (kubeadm)
kubectl exec -it kube-apiserver-controlplane -n kube-system \
  -- kube-apiserver -h | grep enable-admission-plugins
```

Дефолтно включённые плагины (в типичном кластере):
- `NamespaceLifecycle`
- `LimitRanger`
- `ServiceAccount`
- `TaintNodesByCondition`
- `Priority`
- `DefaultTolerationSeconds`
- `DefaultStorageClass`
- `StorageObjectInUseProtection`
- `PersistentVolumeClaimResize`
- `MutatingAdmissionWebhook`
- `ValidatingAdmissionWebhook`
- `ResourceQuota`

**Посмотреть, какие включены в конкретном кластере:**

```bash
grep 'enable-admission-plugins' /etc/kubernetes/manifests/kube-apiserver.yaml
```

---

### Настройка Admission Controllers

Admission Controllers настраиваются через флаги kube-apiserver.

**Включить дополнительные контроллеры:**

В файле `/etc/kubernetes/manifests/kube-apiserver.yaml`:

```yaml
spec:
  containers:
  - command:
    - kube-apiserver
    - --authorization-mode=Node,RBAC
    - --enable-admission-plugins=NodeRestriction,NamespaceAutoProvision
```

**Отключить конкретный контроллер:**

```yaml
    - --enable-admission-plugins=NodeRestriction,NamespaceAutoProvision
    - --disable-admission-plugins=DefaultStorageClass
```

После изменения манифеста в kubeadm-кластере kube-apiserver перезапускается автоматически (это статичный под).

---

### Пример: NamespaceAutoProvision

Включаем автоматическое создание namespace:

```yaml
- --enable-admission-plugins=NodeRestriction,NamespaceAutoProvision
```

Теперь:

```bash
kubectl run nginx --image nginx --namespace blue
# pod/nginx created   ← namespace создан автоматически!

kubectl get namespaces
# NAME              STATUS   AGE
# blue              Active   7s    ← появился сам!
# default           Active   50m
# kube-system       Active   50m
```

> **Важно:** `NamespaceAutoProvision` и старый `NamespaceExists` **устарели** и заменены на `NamespaceLifecycle`, который умеет делать обе функции сразу.

---

### Проверка после изменений

```bash
ps -ef | grep kube-apiserver | grep admission
```

Эта команда покажет текущие флаги kube-apiserver, включая все включённые и отключённые Admission Controllers.

---

## Часть 3: Validating и Mutating Admission Controllers

### Два типа Admission Controllers

Все Admission Controllers делятся на два принципиально разных типа:

#### Validating Admission Controllers (Валидирующие)

Эти контроллеры **проверяют** запрос и либо **разрешают**, либо **отклоняют** его. Они не изменяют сам запрос.

Примеры:
- `NamespaceLifecycle` — проверяет существование namespace, отклоняет если не найден
- `ResourceQuota` — проверяет, не превышает ли запрос квоту
- `LimitRanger` — проверяет лимиты ресурсов
- `PodSecurity` — проверяет security context пода

#### Mutating Admission Controllers (Мутирующие)

Эти контроллеры **изменяют** запрос перед его сохранением. Они могут добавлять, изменять или удалять поля объекта.

Примеры:
- `DefaultStorageClass` — добавляет `storageClassName` в PVC
- `NamespaceAutoProvision` — создаёт отсутствующий namespace (воздействует на кластер)
- `LimitRanger` — добавляет дефолтные resource requests/limits
- `ServiceAccount` — монтирует токен service account

---

### Порядок выполнения

**Критически важно:** мутирующие контроллеры всегда вызываются **раньше** валидирующих.

```
Запрос
  ↓
Mutating Controllers (изменяют запрос)
  ↓
Validating Controllers (проверяют изменённый запрос)
  ↓
Сохранение в etcd
```

Это логично: сначала нужно привести объект в корректный вид (мутация), а потом проверять, соответствует ли он политикам (валидация). Если бы порядок был обратным, мутация могла бы нарушить уже пройденную валидацию.

---

### External Admission Controllers — Webhooks

Встроенных контроллеров может не хватать для сложных бизнес-правил. Kubernetes позволяет подключить **внешние** контроллеры через механизм Webhook.

Работает так:

1. Запрос проходит через все встроенные контроллеры
2. Kubernetes отправляет **HTTP-запрос** на внешний сервер (Webhook сервер) в формате JSON
3. Webhook сервер анализирует запрос и возвращает ответ: разрешить/отклонить (и опционально — изменения)
4. Kubernetes принимает решение на основе ответа

Есть два типа webhook:

- **MutatingAdmissionWebhook** — для мутирующих контроллеров
- **ValidatingAdmissionWebhook** — для валидирующих контроллеров

---

### Формат запроса к Webhook

Kubernetes отправляет на webhook-сервер объект типа **AdmissionReview**:

```json
{
  "apiVersion": "admission.k8s.io/v1",
  "kind": "AdmissionReview",
  "request": {
    "uid": "705ab4f5-6393-11e8-b7cc-42010aa80002",
    "kind": {"group": "apps", "version": "v1", "kind": "Deployment"},
    "resource": {"group": "apps", "version": "v1", "resource": "deployments"},
    "operation": "CREATE",
    "userInfo": {
      "username": "dev-user",
      "groups": ["developers"]
    },
    "object": {
      "metadata": {"name": "my-deployment"},
      "spec": { ... }
    }
  }
}
```

---

### Формат ответа от Webhook

**Разрешить запрос (validating):**

```json
{
  "apiVersion": "admission.k8s.io/v1",
  "kind": "AdmissionReview",
  "response": {
    "uid": "705ab4f5-6393-11e8-b7cc-42010aa80002",
    "allowed": true
  }
}
```

**Отклонить запрос (validating):**

```json
{
  "response": {
    "uid": "705ab4f5-...",
    "allowed": false,
    "status": {
      "message": "Pods cannot run as root user"
    }
  }
}
```

**Мутировать запрос (mutating) — добавить label:**

```json
{
  "response": {
    "uid": "705ab4f5-...",
    "allowed": true,
    "patch": "W3sib3AiOiAiYWRkIiwgInBhdGgiOiAiL21ldGFkYXRhL2xhYmVscy91c2VyIiwgInZhbHVlIjogImRldi11c2VyIn1d",
    "patchType": "JSONPatch"
  }
}
```

Поле `patch` — это base64-закодированный массив JSON Patch операций:

```json
[
  {
    "op": "add",
    "path": "/metadata/labels/user",
    "value": "dev-user"
  }
]
```

---

### Реализация Webhook-сервера

Webhook-сервер — это обычный HTTP-сервер (с поддержкой TLS), который принимает POST-запросы. Его можно написать на любом языке.

**Пример на Go (фрагмент):**

```go
package main

import (
    "encoding/json"
    "net/http"
    "k8s.io/api/admission/v1beta1"
)

func serve(w http.ResponseWriter, r *http.Request, admit admitFunc) {
    var body []byte
    if r.Body != nil {
        data, _ := ioutil.ReadAll(r.Body)
        body = data
    }

    // Декодируем AdmissionReview
    var admissionReview v1beta1.AdmissionReview
    json.Unmarshal(body, &admissionReview)

    // Вызываем функцию-обработчик
    admissionResponse := admit(admissionReview)

    // Формируем ответ
    response := v1beta1.AdmissionReview{
        Response: &admissionResponse,
    }

    json.NewEncoder(w).Encode(response)
}
```

**Пример на Python (Flask) — валидирующий webhook:**

```python
from flask import Flask, request, jsonify
import base64
import json

app = Flask(__name__)

@app.route("/validate", methods=["POST"])
def validate():
    admission_review = request.json
    object_name = admission_review["request"]["object"]["metadata"]["name"]
    user_name = admission_review["request"]["userInfo"]["username"]

    allowed = True
    message = ""

    # Политика: нельзя создавать объект с именем, совпадающим с именем пользователя
    if object_name == user_name:
        allowed = False
        message = f"Нельзя создавать объекты с именем пользователя ({user_name})"

    return jsonify({
        "response": {
            "uid": admission_review["request"]["uid"],
            "allowed": allowed,
            "status": {"message": message}
        }
    })
```

**Пример на Python — мутирующий webhook:**

```python
@app.route("/mutate", methods=["POST"])
def mutate():
    admission_review = request.json
    user_name = admission_review["request"]["userInfo"]["username"]

    # Добавляем label с именем пользователя
    patch = [
        {
            "op": "add",
            "path": "/metadata/labels/created-by",
            "value": user_name
        }
    ]

    # Патч должен быть закодирован в base64
    encoded_patch = base64.b64encode(json.dumps(patch).encode()).decode()

    return jsonify({
        "response": {
            "uid": admission_review["request"]["uid"],
            "allowed": True,
            "patch": encoded_patch,
            "patchType": "JSONPatch"
        }
    })

if __name__ == "__main__":
    # Webhook обязательно должен работать по HTTPS!
    app.run(
        host="0.0.0.0",
        port=443,
        ssl_context=("tls.crt", "tls.key")
    )
```

---

### Деплой Webhook-сервера в кластере

**Шаг 1: Создать TLS-секрет (webhook обязан работать по HTTPS):**

```bash
kubectl -n webhook-demo create secret tls webhook-server-tls \
  --cert "/root/keys/webhook-server-tls.crt" \
  --key "/root/keys/webhook-server-tls.key"
```

**Шаг 2: Создать Deployment с webhook-сервером:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webhook-server
  namespace: webhook-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webhook-server
  template:
    metadata:
      labels:
        app: webhook-server
    spec:
      containers:
      - name: webhook-server
        image: my-webhook-server:latest
        ports:
        - containerPort: 443
        volumeMounts:
        - name: tls-certs
          mountPath: /etc/tls
          readOnly: true
      volumes:
      - name: tls-certs
        secret:
          secretName: webhook-server-tls
```

**Шаг 3: Создать Service для доступа к webhook:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webhook-service
  namespace: webhook-demo
spec:
  selector:
    app: webhook-server
  ports:
  - port: 443
    targetPort: 443
```

---

### Регистрация Webhook в Kubernetes

После деплоя сервера нужно сообщить Kubernetes, что он должен обращаться к нему для определённых запросов.

**ValidatingWebhookConfiguration:**

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: "pod-policy.example.com"
webhooks:
- name: "pod-policy.example.com"
  clientConfig:
    service:
      namespace: "webhook-demo"
      name: "webhook-service"
    caBundle: "Ci0tLS0tQk..."   # base64 CA сертификат
  rules:
  - apiGroups: [""]
    apiVersions: ["v1"]
    operations: ["CREATE"]     # только на создание
    resources: ["pods"]        # только для подов
    scope: "Namespaced"
  failurePolicy: Fail          # что делать если webhook недоступен
```

**MutatingWebhookConfiguration:**

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  name: "pod-mutator.example.com"
webhooks:
- name: "pod-mutator.example.com"
  clientConfig:
    service:
      namespace: "webhook-demo"
      name: "webhook-service"
    caBundle: "Ci0tLS0tQk..."
  rules:
  - apiGroups: [""]
    apiVersions: ["v1"]
    operations: ["CREATE", "UPDATE"]
    resources: ["pods"]
    scope: "Namespaced"
```

---

### Практический пример: webhook для управления runAsNonRoot

Рассмотрим реальный сценарий: webhook, который:
1. **Мутирует** поды без securityContext — добавляет `runAsNonRoot: true` и `runAsUser: 1234`
2. **Валидирует** поды — отклоняет конфликтующие конфигурации

**Случай 1: Pod без securityContext**

```yaml
# pod-with-defaults.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-defaults
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["sh", "-c", "echo Запущен как пользователь $(id -u)"]
```

После применения webhook мутирует под:

```bash
kubectl apply -f pod-with-defaults.yaml
kubectl get pod pod-with-defaults -o yaml
```

В YAML пода появится:

```yaml
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1234   # добавлено webhook'ом!
```

**Случай 2: Pod с явным переопределением (разрешить root)**

```yaml
# pod-with-override.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-override
spec:
  securityContext:
    runAsNonRoot: false   # явно разрешаем root
  containers:
  - name: busybox
    image: busybox
```

Webhook видит явное указание и не мутирует под.

**Случай 3: Pod с конфликтующей конфигурацией**

```yaml
# pod-with-conflict.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-conflict
spec:
  securityContext:
    runAsNonRoot: true   # запрещаем root
  containers:
  - name: busybox
    image: busybox
    securityContext:
      runAsUser: 0       # но user 0 — это root! Конфликт!
```

```bash
kubectl apply -f pod-with-conflict.yaml
# Error from server: admission webhook "webhook-server.webhook-demo.svc"
# denied the request:
# runAsNonRoot specified, but runAsUser set to 0 (the root user)
```

Webhook валидирует конфигурацию и отклоняет запрос, потому что `runAsNonRoot: true` и `runAsUser: 0` противоречат друг другу.

---

### failurePolicy — что делать если webhook недоступен?

Параметр `failurePolicy` определяет поведение при недоступности webhook-сервера:

```yaml
webhooks:
- name: "pod-policy.example.com"
  failurePolicy: Fail    # отклонить запрос (default)
  # или
  failurePolicy: Ignore  # разрешить запрос, игнорировать ошибку
  ...
```

- `Fail` — безопаснее, но если webhook упал — никто не сможет создавать поды
- `Ignore` — менее безопасно, но кластер продолжает работать даже без webhook

---

## Итоги и выводы

### Сравнительная таблица: Role vs ClusterRole

| Характеристика | Role | ClusterRole |
|----------------|------|-------------|
| Область действия | Один namespace | Весь кластер |
| Cluster-scoped ресурсы | ❌ Нет | ✅ Да |
| Привязка объектом | RoleBinding | ClusterRoleBinding |
| Можно использовать с RoleBinding | ✅ Да | ✅ Да (только для одного namespace) |

### Сравнительная таблица: Validating vs Mutating

| Характеристика | Validating | Mutating |
|----------------|-----------|---------|
| Изменяет запрос | ❌ Нет | ✅ Да |
| Порядок выполнения | После mutating | До validating |
| Может отклонить запрос | ✅ Да | ✅ Да |
| Примеры | NamespaceLifecycle, ResourceQuota | DefaultStorageClass, LimitRanger |

### Общая архитектура безопасности запроса

```
kubectl apply -f pod.yaml
        ↓
  kube-apiserver
        ↓
  1. Аутентификация
     (сертификат / токен)
        ↓
  2. Авторизация / RBAC
     (Role / ClusterRole)
        ↓
  3. Mutating Admission Controllers
     (встроенные + webhooks)
        ↓
  4. Validating Admission Controllers
     (встроенные + webhooks)
        ↓
  5. Сохранение в etcd
        ↓
  6. Объект создан
```

### Ключевые рекомендации

1. **ClusterRole** нужна только для cluster-scoped ресурсов (Nodes, PV, Namespaces) или когда нужен доступ сразу во все namespace

2. **Admission Controllers** — это третий рубеж защиты после аутентификации и авторизации; используй их для политик, которые RBAC не может выразить

3. **Mutating webhooks** должны вызываться до валидирующих — это фундаментальный принцип Kubernetes

4. **Webhook-серверы обязаны работать по HTTPS** — Kubernetes не будет обращаться к незащищённому endpoint

5. **failurePolicy: Fail** безопаснее, но требует высокой доступности webhook-сервера

6. **Не путай** встроенные Admission Controllers с Webhook-контроллерами: первые — это код внутри kube-apiserver, вторые — внешние HTTP-серверы

---

# 8.3 - API Versions, Deprecations, CRD, Custom Controllers и Operator Framework в Kubernetes

---

## Часть 1: API Versions — версионирование API в Kubernetes

### Зачем нужно версионирование?

Kubernetes — живая система, которая постоянно развивается. Новые возможности добавляются регулярно, старые улучшаются, некоторые переосмысливаются. При этом кластеры работают в продакшне годами, и тысячи пользователей имеют YAML-файлы, написанные под конкретные версии API.

Версионирование API решает фундаментальную проблему: **как добавлять новые возможности и исправлять ошибки, не ломая существующие конфигурации пользователей?**

Ответ Kubernetes — поддерживать несколько версий одного API одновременно, при этом чётко маркируя стадию зрелости каждой версии.

---

### Организация API в Kubernetes

Вся система API Kubernetes организована иерархически:

```
Kubernetes API
    ├── API Groups (группы)
    │   ├── core (/api/v1)
    │   ├── apps (/apis/apps)
    │   ├── batch (/apis/batch)
    │   ├── networking.k8s.io
    │   ├── rbac.authorization.k8s.io
    │   └── ...
    │
    └── Каждая группа имеет версии
        ├── v1alpha1
        ├── v1alpha2
        ├── v1beta1
        ├── v1beta2
        └── v1 (GA)
```

Каждая API-группа может поддерживать **несколько версий одновременно**. Это ключевой момент: пользователь может написать манифест с `apps/v1beta1`, и он будет работать, даже если уже существует `apps/v1`.

---

### Три стадии жизненного цикла API

#### Стадия 1: Alpha (α)

Alpha-версия — это самая ранняя публичная форма API. Обозначается суффиксом `alpha` в имени: `v1alpha1`, `v1alpha2`, `v2alpha1` и т.д.

**Характеристики:**

| Свойство | Значение |
|----------|---------|
| Включена по умолчанию | ❌ Нет |
| End-to-end тесты | ❌ Отсутствуют или неполные |
| Наличие багов | ✅ Вероятны |
| Стабильность API | ❌ Может измениться в любой момент |
| Поддержка | ❌ Только до следующего релиза |
| Целевая аудитория | Эксперты, тестировщики, ранние последователи |

Пример реального alpha-ресурса:

```yaml
apiVersion: internal.apiserver.k8s.io/v1alpha1
kind: StorageVersion
metadata:
  name: sv-1
spec:
```

Если попытаться создать этот объект без явного включения alpha API, kube-apiserver отклонит запрос — API просто не включена.

**Почему alpha API не включены по умолчанию?** Потому что они могут содержать баги, их интерфейс может кардинально измениться в следующем релизе, и Kubernetes не хочет, чтобы продакшн-кластеры случайно зависели от нестабильного функционала.

---

#### Стадия 2: Beta (β)

Beta-версия появляется после того, как alpha прошла основные испытания, критические баги исправлены, добавлены end-to-end тесты. Обозначается: `v1beta1`, `v1beta2`, `v2beta1`.

**Характеристики:**

| Свойство | Значение |
|----------|---------|
| Включена по умолчанию | ✅ Да |
| End-to-end тесты | ✅ Есть |
| Наличие багов | ⚠️ Возможны незначительные |
| Стабильность API | ⚠️ Относительно стабильна, но может измениться |
| Поддержка после deprecation | Минимум 9 месяцев или 3 релиза |
| Целевая аудитория | Широкая аудитория, включая нагрузочное тестирование |

Beta означает: сообщество Kubernetes берёт на себя обязательство довести этот API до GA. Кардинальных изменений не будет, но небольшие могут быть.

---

#### Стадия 3: GA (Generally Available) — Stable

GA (или Stable) — это финальная, production-ready версия API. Обозначается просто числом без суффиксов: `v1`, `v2`.

**Характеристики:**

| Свойство | Значение |
|----------|---------|
| Включена по умолчанию | ✅ Да, всегда |
| End-to-end тесты | ✅ Полное покрытие |
| Наличие багов | ✅ Минимальны, быстро исправляются |
| Стабильность API | ✅ Гарантирована обратная совместимость |
| Поддержка после deprecation | Минимум 12 месяцев или 3 релиза |
| Целевая аудитория | Все, включая продакшн |

GA входит в conformance-тесты Kubernetes — это стандарт, которому должны соответствовать все сертифицированные дистрибутивы Kubernetes.

Примеры API-групп в GA состоянии: `apps`, `authentication`, `authorization`, `certificates`, `coordination`.

---

### Preferred Version и Storage Version

Когда API-группа поддерживает несколько версий, возникают два важных понятия:

#### Preferred Version (предпочтительная версия)

Это версия, которую использует kubectl по умолчанию при запросах `kubectl get` и `kubectl explain`. Если ты запрашиваешь `kubectl get deployment` — ответ придёт в preferred version.

Узнать preferred version для группы можно через API:

```bash
# Запускаем прокси
kubectl proxy --port=8001 &

# Запрашиваем информацию о группе batch
curl localhost:8001/apis/batch
```

```json
{
  "kind": "APIGroup",
  "apiVersion": "v1",
  "name": "batch",
  "versions": [
    {
      "groupVersion": "batch/v1",
      "version": "v1"
    },
    {
      "groupVersion": "batch/v1beta1",
      "version": "v1beta1"
    }
  ],
  "preferredVersion": {
    "groupVersion": "batch/v1",
    "version": "v1"
  }
}
```

Поле `preferredVersion` чётко указывает, что при запросах без явного указания версии будет использоваться `batch/v1`.

Аналогично для `authorization.k8s.io`:

```bash
curl localhost:8001/apis/authorization.k8s.io
```

```json
{
  "kind": "APIGroup",
  "name": "authorization.k8s.io",
  "versions": [
    {
      "groupVersion": "authorization.k8s.io/v1",
      "version": "v1"
    }
  ],
  "preferredVersion": {
    "groupVersion": "authorization.k8s.io/v1",
    "version": "v1"
  }
}
```

#### Storage Version (версия хранения)

Storage version — это версия, в которой объект **физически хранится в etcd**. Это внутренняя деталь реализации. Даже если ты создаёшь объект через `apps/v1alpha1`, Kubernetes автоматически конвертирует его в storage version перед сохранением.

Узнать storage version нельзя через обычный kubectl — нужно обращаться к etcd напрямую:

```bash
ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  get "/registry/deployments/default/blue" --print-value-only
```

Вывод содержит строку `apps/v1` — это и есть storage version:

```
apps/v1
Deployment

bluedefault"*${cf8dcd55-8819-4be2-85e7-bb71665c2ddf2ZB
successfully progressed8"2
```

**Важный вывод:** preferred version и storage version — это **не обязательно одно и то же**, хотя на практике для GA-версий они совпадают. В переходный период (например, когда только что выпустили v1, но старая v1beta1 ещё поддерживается) storage version уже может быть v1, а preferred тоже v1, но YAML с v1beta1 всё ещё принимается.

---

### Как создавать объекты с разными версиями API

Все три YAML-файла ниже создают **один и тот же объект**:

```yaml
# Вариант 1: через alpha API
apiVersion: apps/v1alpha1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
```

```yaml
# Вариант 2: через beta API
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 3
  # ...
```

```yaml
# Вариант 3: через GA API (рекомендуется)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 3
  # ...
```

После создания любого из них:

```bash
kubectl explain deployment
# KIND:     Deployment
# VERSION:  apps/v1   ← всегда показывает preferred version
```

---

### Включение и отключение API версий

По умолчанию alpha API **отключены**. Чтобы включить конкретную версию, используется флаг `--runtime-config` у kube-apiserver.

**Включить alpha API для RBAC:**

```bash
# Редактируем манифест kube-apiserver
# /etc/kubernetes/manifests/kube-apiserver.yaml

# Перед изменением — обязательно делаем бэкап!
cp /etc/kubernetes/manifests/kube-apiserver.yaml /root/kube-apiserver.yaml.backup
```

Добавляем в список аргументов:

```yaml
spec:
  containers:
  - command:
    - kube-apiserver
    # ... другие флаги ...
    - --runtime-config=rbac.authorization.k8s.io/v1alpha1
```

**Включить все API (включая alpha):**

```bash
--runtime-config=api/all
```

**Включить несколько конкретных:**

```bash
--runtime-config=batch/v2alpha1,rbac.authorization.k8s.io/v1alpha1
```

**Отключить конкретную версию:**

```bash
--runtime-config=batch/v1beta1=false
```

После изменения манифеста kube-apiserver перезапустится автоматически (в kubeadm-кластере). Проверяем:

```bash
kubectl get pod -n kube-system
# kube-apiserver-controlplane   0/1   Pending   0   5s
# ... через некоторое время ...
# kube-apiserver-controlplane   1/1   Running   0   15s
```

---

### Краткие имена ресурсов (Short Names)

При работе с API полезно знать сокращённые имена ресурсов:

```bash
kubectl api-resources
```

Наиболее используемые:

| Ресурс | Короткое имя | API группа |
|--------|-------------|-----------|
| deployments | deploy | apps |
| replicasets | rs | apps |
| services | svc | core |
| namespaces | ns | core |
| nodes | no | core |
| pods | po | core |
| persistentvolumes | pv | core |
| persistentvolumeclaims | pvc | core |
| configmaps | cm | core |
| serviceaccounts | sa | core |
| cronjobs | cj | batch |
| customresourcedefinitions | crd, crds | apiextensions.k8s.io |
| horizontalpodautoscalers | hpa | autoscaling |
| ingresses | ing | networking.k8s.io |

Определить API-группу конкретного ресурса:

```bash
kubectl explain job
# KIND:    Job
# VERSION: batch/v1
# ↑ группа "batch", версия "v1"
```

---

## Часть 2: API Deprecations — управление устареванием API

### Четыре правила политики deprecation

Kubernetes имеет формальную политику, которая определяет, как именно должны устаревать API. Эти правила — не рекомендации, а обязательные требования для разработчиков Kubernetes.

---

#### Правило 1: Элементы API удаляются только через инкрементацию версии

Нельзя удалить ресурс или поле из существующей версии API. Можно только убрать его в **следующей версии**.

**Пример:** представь, что ты создаёшь API-группу `kodekloud.com` с ресурсами `Course` и `Webinar`. После тестирования выясняется, что `Webinar` не нужен.

Нельзя: просто удалить `Webinar` из `v1alpha1`.

Нужно: выпустить `v1alpha2` без `Webinar`, при этом `v1alpha1` с `Webinar` продолжает работать.

```yaml
# v1alpha1 — оба ресурса
apiVersion: kodekloud.com/v1alpha1
kind: Course
---
apiVersion: kodekloud.com/v1alpha1
kind: Webinar   # существует

# v1alpha2 — только Course
apiVersion: kodekloud.com/v1alpha2
kind: Course    # существует
# Webinar — отсутствует
```

---

#### Правило 2: Объекты API должны поддерживать round-trip конвертацию без потери данных

**Round-trip** — это конвертация объекта из версии A в версию B и обратно в версию A, при которой данные не теряются.

Представь: в `v1alpha1` есть поле `type: video`. В `v1alpha2` добавили новое поле `duration`. При конвертации из v1alpha1 в v1alpha2 поле `duration` получит пустое значение. Но при конвертации **обратно** в v1alpha1 это поле должно куда-то сохраниться — иначе произойдёт потеря данных.

```yaml
# v1alpha1 объект
apiVersion: kodekloud.com/v1alpha1
kind: Course
spec:
  type: video
  # duration отсутствует, но нужен placeholder для round-trip

# v1alpha2 объект
apiVersion: kodekloud.com/v1alpha2
kind: Course
spec:
  type: video
  duration: ""    # новое поле, может быть пустым
```

Для обеспечения round-trip совместимости в v1alpha1 тоже нужно добавить поле `duration` (пусть и как необязательное), чтобы при конвертации туда-обратно ничего не терялось.

---

#### Правило 3: Версия API не может быть deprecated, пока не появится эквивалентная или более стабильная версия

Нельзя объявить GA-версию (`v1`) устаревшей, если на её замену предлагается только alpha (`v2alpha1`). Замена должна быть **как минимум такого же уровня стабильности**.

```
v1 (GA) → deprecated только когда появится v2 (GA)
v1beta1 → deprecated когда появится v1beta2 или v1 (GA)
v1alpha1 → deprecated когда появится v1alpha2
```

---

#### Правило 4: Минимальные периоды поддержки после deprecation

Даже после объявления версии устаревшей, она должна продолжать работать определённое время:

| Стадия | Минимальный период поддержки |
|--------|------------------------------|
| GA (v1, v2...) | 12 месяцев **или** 3 релиза (что больше) |
| Beta | 9 месяцев **или** 3 релиза (что больше) |
| Alpha | До следующего релиза — нет гарантий |

---

### Жизненный цикл API на примере

Проследим полный путь гипотетического API `kodekloud.com` через серию релизов Kubernetes (X, X+1, X+2...):

**Релиз X:** Выходит `v1alpha1`. Это первая публичная версия.

```
Релиз X:   v1alpha1 [CURRENT]
```

**Релиз X+1:** Выходит `v1alpha2`. Поскольку alpha не имеет длительной поддержки, `v1alpha1` сразу удаляется. Пользователи должны обновить манифесты.

```
Релиз X+1: v1alpha1 [REMOVED]
            v1alpha2 [CURRENT]
```

**Релиз X+2:** Выходит первая beta-версия `v1beta1`.

```
Релиз X+2: v1alpha2 [CURRENT]
            v1beta1  [CURRENT, PREFERRED]
```

**Релиз X+3:** Выходит `v1beta2`. `v1beta1` объявляется deprecated, но ещё работает (9 месяцев / 3 релиза).

```
Релиз X+3: v1beta1  [DEPRECATED - ещё работает]
            v1beta2  [CURRENT, PREFERRED]
```

**Релиз X+4:** `v1beta1` продолжает работать в период поддержки.

```
Релиз X+4: v1beta1  [DEPRECATED - ещё работает]
            v1beta2  [CURRENT, PREFERRED]
```

**Релиз X+5:** Выходит GA-версия `v1`. Beta-версии объявляются deprecated.

```
Релиз X+5: v1beta1  [DEPRECATED]
            v1beta2  [DEPRECATED]
            v1       [CURRENT, PREFERRED, GA]
```

**Релиз X+6:** `v1beta1` был deprecated в X+3, прошло 3 релиза — удаляется.

```
Релиз X+6: v1beta1  [REMOVED]
            v1beta2  [DEPRECATED - ещё работает]
            v1       [CURRENT, PREFERRED, GA]
```

**Релиз X+8:** `v1beta2` был deprecated в X+5, прошло 3 релиза — удаляется.

```
Релиз X+8: v1beta2  [REMOVED]
            v1       [CURRENT, PREFERRED, GA]
```

**Ключевой вывод:** между объявлением deprecation и фактическим удалением всегда есть период, в течение которого старые манифесты продолжают работать. Это даёт пользователям время на миграцию.

---

### kubectl convert — инструмент миграции

При обновлении кластера старые манифесты могут использовать уже удалённые версии API. Конвертировать их вручную при большом количестве файлов крайне неудобно. Для этого существует плагин `kubectl convert`.

**Установка kubectl-convert:**

```bash
# Скачать бинарник
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl-convert"

# Скачать checksum для проверки целостности
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl-convert.sha256"

# Проверить целостность
echo "$(<kubectl-convert.sha256) kubectl-convert" | sha256sum --check

# Сделать исполняемым и переместить в PATH
chmod +x kubectl-convert
mv kubectl-convert /usr/local/bin/

# Проверить установку
kubectl convert --help
```

**Использование:**

Предположим, у тебя есть старый файл `ingress-old.yaml` с устаревшим API:

```yaml
# ingress-old.yaml — устаревший формат
apiVersion: extensions/v1beta1   # ← устаревший!
kind: Ingress
metadata:
  name: ingress-space
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        backend:
          serviceName: my-service
          servicePort: 80
```

Конвертируем в актуальный формат:

```bash
kubectl convert -f ingress-old.yaml --output-version networking.k8s.io/v1 > ingress-new.yaml
```

Результирующий файл `ingress-new.yaml`:

```yaml
# ingress-new.yaml — актуальный формат
apiVersion: networking.k8s.io/v1   # ← обновлено!
kind: Ingress
metadata:
  name: ingress-space
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix           # ← добавлено автоматически
        backend:
          service:
            name: my-service       # ← новый формат backend
            port:
              number: 80
```

Применяем:

```bash
kubectl apply -f ingress-new.yaml
# ingress.networking.k8s.io/ingress-space created
```

**Другие примеры конвертации:**

```bash
# Конвертировать Deployment из beta в stable
kubectl convert -f deployment-old.yaml --output-version apps/v1

# Конвертировать и сразу применить
kubectl convert -f old-manifest.yaml --output-version apps/v1 | kubectl apply -f -

# Конвертировать директорию с манифестами
kubectl convert -f ./old-manifests/ --output-version apps/v1
```

---

## Часть 3: Custom Resource Definitions (CRD)

### Как работают стандартные ресурсы Kubernetes

Чтобы понять CRD, нужно сначала понять механику обычных ресурсов.

Когда ты создаёшь `Deployment`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: nginx
        image: nginx
```

Происходит следующее:

1. kubectl отправляет YAML на kube-apiserver
2. kube-apiserver сохраняет объект в **etcd**
3. **Deployment Controller** (встроенный контроллер) замечает новый объект
4. Контроллер создаёт ReplicaSet
5. ReplicaSet Controller создаёт поды
6. Kubernetes следит за тем, чтобы реальное состояние (running pods) соответствовало желаемому (replicas: 3)

Это паттерн **control loop** (цикл управления):

```
Желаемое состояние (etcd) ←→ Контроллер ←→ Реальное состояние (кластер)
```

---

### Что такое CRD и зачем они нужны?

CRD (Custom Resource Definition) — это механизм расширения Kubernetes API собственными типами ресурсов. С помощью CRD можно научить Kubernetes понимать совершенно новые объекты, специфичные для твоих нужд.

**Реальные примеры использования CRD:**

- **cert-manager** — ресурс `Certificate` для автоматического получения TLS-сертификатов
- **Prometheus Operator** — ресурсы `ServiceMonitor`, `PrometheusRule`
- **Istio** — ресурсы `VirtualService`, `DestinationRule`, `Gateway`
- **ArgoCD** — ресурсы `Application`, `AppProject`
- **Knative** — ресурсы `Service`, `Route`, `Configuration`

---

### Создание CRD: пример FlightTicket

Представь, что ты хочешь управлять бронированием авиабилетов прямо из Kubernetes. Создадим ресурс `FlightTicket`.

**Шаг 1: Попытка создать объект без CRD**

```yaml
# flightticket.yaml
apiVersion: flights.com/v1
kind: FlightTicket
metadata:
  name: my-flight-ticket
spec:
  from: Mumbai
  to: London
  number: 2
```

```bash
kubectl create -f flightticket.yaml
# Error from server (NotFound):
# error when creating "flightticket.yaml":
# no matches for kind "FlightTicket" in version "flights.com/v1"
```

Kubernetes не знает, что такое `FlightTicket`. Нужно сначала зарегистрировать этот тип.

**Шаг 2: Создаём CRD**

```yaml
# flightticket-crd.yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: flighttickets.flights.com   # ВАЖНО: plural.group
spec:
  group: flights.com                # API группа
  scope: Namespaced                 # или Cluster
  names:
    plural: flighttickets           # kubectl get flighttickets
    singular: flightticket          # в сообщениях об ошибках
    kind: FlightTicket              # в YAML-файлах
    shortNames:
      - ft                          # kubectl get ft
  versions:
    - name: v1
      served: true                  # эта версия принимает запросы
      storage: true                 # в этой версии хранится в etcd
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                from:
                  type: string
                to:
                  type: string
                number:
                  type: integer
                  minimum: 1        # валидация: минимум 1 билет
                  maximum: 10       # можно добавить максимум
```

Разберём ключевые поля CRD:

**`metadata.name`** — должен строго соответствовать формату `{plural}.{group}`. В нашем случае: `flighttickets.flights.com`. Это обязательное требование, нарушение вызовет ошибку.

**`spec.scope`** — определяет, является ли ресурс namespace-scoped или cluster-scoped:
- `Namespaced` — как обычные поды/сервисы, привязан к namespace
- `Cluster` — как Nodes/PV, существует на уровне всего кластера

**`spec.versions[].served`** — включает/выключает обработку этой версии API-сервером. Если `false` — запросы к этой версии будут отклонены.

**`spec.versions[].storage`** — указывает версию для хранения в etcd. Ровно одна версия должна иметь `storage: true`.

**`spec.versions[].schema.openAPIV3Schema`** — схема валидации, основанная на OpenAPI v3. Kubernetes будет проверять все создаваемые объекты на соответствие схеме.

**Шаг 3: Применяем CRD**

```bash
kubectl create -f flightticket-crd.yaml
# customresourcedefinition.apiextensions.k8s.io/flighttickets.flights.com created
```

**Шаг 4: Проверяем регистрацию**

```bash
kubectl api-resources | grep flight
# flighttickets   ft   flights.com   true   FlightTicket
```

**Шаг 5: Создаём объект FlightTicket**

```bash
kubectl create -f flightticket.yaml
# flightticket.flights.com/my-flight-ticket created

kubectl get flightticket
# NAME               AGE
# my-flight-ticket   5s

# Или используем короткое имя
kubectl get ft
# NAME               AGE
# my-flight-ticket   5s

kubectl describe flightticket my-flight-ticket
# Name:         my-flight-ticket
# Namespace:    default
# API Version:  flights.com/v1
# Kind:         FlightTicket
# Spec:
#   From:    Mumbai
#   Number:  2
#   To:      London
```

**Шаг 6: Проверяем валидацию**

CRD с OpenAPI-схемой отклоняет некорректные объекты:

```yaml
# invalid-ticket.yaml
apiVersion: flights.com/v1
kind: FlightTicket
metadata:
  name: bad-ticket
spec:
  from: Delhi
  to: Paris
  number: 0      # нарушение: minimum: 1
```

```bash
kubectl create -f invalid-ticket.yaml
# Error from server (BadRequest):
# spec.number: Invalid value: 0: spec.number in body should be >= 1
```

---

### Расширенная валидация в CRD-схеме

OpenAPI v3 позволяет задавать гибкие правила валидации:

```yaml
versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        required: ["spec"]          # spec обязателен
        properties:
          spec:
            type: object
            required: ["from", "to", "number"]   # все поля обязательны
            properties:
              from:
                type: string
                minLength: 3       # минимум 3 символа
                maxLength: 100
              to:
                type: string
                minLength: 3
                maxLength: 100
              number:
                type: integer
                minimum: 1
                maximum: 10
              class:
                type: string
                enum: ["economy", "business", "first"]  # только эти значения
          status:
            type: object
            properties:
              bookingId:
                type: string
              confirmed:
                type: boolean
```

---

### Добавление status subresource в CRD

Стандартные Kubernetes-ресурсы имеют отдельную секцию `status`, которая обновляется контроллером независимо от `spec`. CRD тоже может иметь такую возможность:

```yaml
versions:
  - name: v1
    served: true
    storage: true
    subresources:
      status: {}                    # включаем status subresource
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            # ... поля spec ...
          status:
            type: object
            properties:
              bookingId:
                type: string
              confirmed:
                type: boolean
              message:
                type: string
```

С включённым `status` subresource:
- `kubectl edit flightticket` не даёт изменить `status` — это делает только контроллер
- Контроллер использует отдельный endpoint `/status` для обновления

---

### Поддержка нескольких версий в CRD

CRD может поддерживать несколько версий одновременно, как встроенные ресурсы:

```yaml
spec:
  versions:
    - name: v1alpha1
      served: true
      storage: false
    - name: v1beta1
      served: true
      storage: false
    - name: v1
      served: true
      storage: true     # только одна версия может быть storage
```

---

## Часть 4: Custom Controllers

### Зачем нужен контроллер?

CRD позволяет Kubernetes **хранить** твои объекты в etcd и отвечать на запросы через API. Но сами по себе объекты ничего не делают — они лишь пассивные записи данных.

Без контроллера `FlightTicket` существует в etcd как строка данных. Никаких билетов никто не бронирует. Контроллер — это **активная сторона**: он следит за объектами и выполняет реальные действия.

```
Без контроллера:           С контроллером:
CRD + FlightTicket         CRD + FlightTicket + Controller
       ↓                          ↓
 Запись в etcd             Запись в etcd
 (ничего не происходит)    + Controller видит новый объект
                           + Controller вызывает booking API
                           + Реальный авиабилет забронирован!
```

---

### Принцип работы контроллера: Control Loop

Любой Kubernetes-контроллер реализует паттерн **reconciliation loop** (цикл согласования):

```
┌─────────────────────────────────────────┐
│           RECONCILIATION LOOP           │
│                                         │
│  1. Получить желаемое состояние из etcd │
│  2. Получить текущее реальное состояние │
│  3. Сравнить их                         │
│  4. Если есть расхождение — исправить   │
│  5. Вернуться к шагу 1                  │
└─────────────────────────────────────────┘
```

Для нашего FlightTicket:

```
Желаемое состояние: FlightTicket "my-ticket" {from: Mumbai, to: London, number: 2}
Текущее состояние:  Нет реального бронирования
Расхождение:        Нужно забронировать 2 билета Mumbai → London
Действие:           Вызвать booking API
```

---

### Технология реализации: client-go

Контроллеры рекомендуется писать на **Go** с использованием библиотеки `client-go`. Главная причина — встроенные механизмы **Informers** и **WorkQueues**.

**Informer** — это механизм подписки на события Kubernetes с кешированием:
- Вместо постоянных HTTP-запросов к API, Informer подписывается на поток событий (Watch)
- Локально кеширует состояние объектов
- При изменении объекта вызывает handler-функции (OnAdd, OnUpdate, OnDelete)

**WorkQueue** — очередь задач, которые нужно обработать:
- Обеспечивает rate limiting (предотвращает перегрузку)
- Гарантирует, что каждый объект обрабатывается по одному разу
- Поддерживает retry при ошибках

---

### Структура кастомного контроллера на Go

```go
package flightticket

import (
    "context"
    "fmt"
    "time"

    "k8s.io/apimachinery/pkg/util/wait"
    "k8s.io/client-go/tools/cache"
    "k8s.io/client-go/util/workqueue"
)

// FlightTicketController — основная структура контроллера
type FlightTicketController struct {
    // Клиент для обращения к Kubernetes API
    kubeClient kubernetes.Interface

    // Lister для чтения FlightTicket объектов из кеша
    flightTicketLister FlightTicketLister

    // Informer синхронизирован?
    flightTicketsSynced cache.InformerSynced

    // Очередь задач на обработку
    workqueue workqueue.RateLimitingInterface
}

// Run запускает контроллер
func (c *FlightTicketController) Run(threadCount int, stopCh <-chan struct{}) {
    // Ждём синхронизации кеша
    if !cache.WaitForCacheSync(stopCh, c.flightTicketsSynced) {
        return
    }

    // Запускаем воркеры
    for i := 0; i < threadCount; i++ {
        go wait.Until(c.runWorker, time.Second, stopCh)
    }

    <-stopCh
}

// runWorker обрабатывает очередь задач
func (c *FlightTicketController) runWorker() {
    for c.processNextItem() {
    }
}

// processNextItem берёт задачу из очереди и обрабатывает её
func (c *FlightTicketController) processNextItem() bool {
    key, quit := c.workqueue.Get()
    if quit {
        return false
    }
    defer c.workqueue.Done(key)

    err := c.reconcile(key.(string))
    if err != nil {
        c.workqueue.AddRateLimited(key)   // retry при ошибке
        return true
    }

    c.workqueue.Forget(key)
    return true
}

// reconcile — основная логика контроллера
func (c *FlightTicketController) reconcile(key string) error {
    namespace, name, err := cache.SplitMetaNamespaceKey(key)

    // Получаем FlightTicket из кеша
    ticket, err := c.flightTicketLister.FlightTickets(namespace).Get(name)
    if err != nil {
        return err
    }

    // Проверяем, забронирован ли билет уже
    if ticket.Status.BookingId != "" {
        return nil  // уже обработан
    }

    // Бронируем билет через внешний API
    bookingId, err := c.callBookFlightAPI(ticket.Spec.From, ticket.Spec.To, ticket.Spec.Number)
    if err != nil {
        return fmt.Errorf("booking failed: %v", err)
    }

    // Обновляем статус объекта
    ticketCopy := ticket.DeepCopy()
    ticketCopy.Status.BookingId = bookingId
    ticketCopy.Status.Confirmed = true

    _, err = c.flightTicketClient.FlightTickets(namespace).UpdateStatus(
        context.TODO(),
        ticketCopy,
        metav1.UpdateOptions{},
    )
    return err
}

// callBookFlightAPI вызывает внешний API бронирования
func (c *FlightTicketController) callBookFlightAPI(from, to string, count int) (string, error) {
    // HTTP-запрос к внешнему сервису
    // В реальности здесь будет код вызова REST API авиакомпании
    return "BOOKING-123456", nil
}
```

---

### Сборка и запуск контроллера

**Способ 1: Запуск локально (для разработки)**

```bash
# Клонируем шаблон контроллера
git clone https://github.com/kubernetes/sample-controller.git
cd sample-controller

# Адаптируем под наш FlightTicket
# Редактируем controller.go

# Собираем
go build -o flight-controller .

# Запускаем локально
./flight-controller --kubeconfig=$HOME/.kube/config
# I1013 02:11:07 controller.go:115 Setting up event handlers
# I1013 02:11:07 controller.go:156 Starting FlightTicket controller
# I1013 02:11:07 controller.go:159 Waiting for informer caches to sync
# I1013 02:11:07 controller.go:164 Starting workers
```

**Способ 2: Деплой в кластер (для продакшна)**

```dockerfile
# Dockerfile
FROM golang:1.21 AS builder
WORKDIR /app
COPY . .
RUN go build -o flight-controller .

FROM alpine:latest
COPY --from=builder /app/flight-controller /flight-controller
ENTRYPOINT ["/flight-controller"]
```

```bash
docker build -t my-registry/flight-controller:v1.0 .
docker push my-registry/flight-controller:v1.0
```

```yaml
# flight-controller-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flight-controller
  namespace: flights-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: flight-controller
  template:
    metadata:
      labels:
        app: flight-controller
    spec:
      serviceAccountName: flight-controller   # нужны права на чтение FlightTicket
      containers:
      - name: controller
        image: my-registry/flight-controller:v1.0
        args:
        - --kubeconfig=/etc/kubernetes/config
```

---

## Часть 5: Operator Framework

### Что такое Operator?

**Operator** — это паттерн Kubernetes, который объединяет CRD и Custom Controller в одну пакетируемую единицу. Концепция была введена командой CoreOS в 2016 году.

Идея проста: операционные знания о том, как управлять конкретным приложением (деплой, масштабирование, бэкап, восстановление, обновление), кодируются в контроллере. Пользователь описывает **желаемое состояние** через CRD, а оператор **реализует** это состояние автоматически.

**Аналогия:** Оператор — это как опытный системный администратор, знающий всё о конкретном приложении (например, etcd), закодированный в программный код.

---

### Operator vs. Manual CRD + Controller

**Без оператора (ручной подход):**

```bash
# 1. Создаём CRD вручную
kubectl create -f flightticket-crd.yaml

# 2. Создаём RBAC для контроллера вручную
kubectl create -f controller-rbac.yaml

# 3. Деплоим контроллер вручную
kubectl create -f controller-deployment.yaml

# 4. Теперь можем создавать объекты
kubectl create -f flightticket.yaml
```

**С оператором (автоматизированный подход):**

```bash
# Один манифест делает всё
kubectl create -f flight-operator.yaml

# Оператор автоматически:
# - Создаёт CRD
# - Настраивает RBAC
# - Деплоит контроллер
# Всё готово!
kubectl create -f flightticket.yaml
```

---

### Реальный пример: etcd Operator

etcd Operator — один из первых и наиболее известных операторов. Он управляет кластером etcd внутри Kubernetes.

**Что умеет etcd Operator:**

| Операция | Без оператора | С оператором |
|----------|--------------|-------------|
| Деплой кластера | Создать 3 StatefulSet вручную | Создать EtcdCluster объект |
| Масштабирование | Изменить StatefulSet + настройки etcd | Изменить `size` в EtcdCluster |
| Бэкап | Написать скрипт | Создать EtcdBackup объект |
| Восстановление | Сложная ручная процедура | Создать EtcdRestore объект |
| Обновление версии | Сложная ролинг-процедура | Изменить `version` в EtcdCluster |

**CRD, которые создаёт etcd Operator:**

```yaml
# EtcdCluster — описывает желаемый кластер etcd
apiVersion: etcd.database.coreos.com/v1beta2
kind: EtcdCluster
metadata:
  name: example
spec:
  size: 3           # количество узлов
  version: "3.5.0"  # версия etcd

---
# EtcdBackup — описывает задачу бэкапа
apiVersion: etcd.database.coreos.com/v1beta2
kind: EtcdBackup
metadata:
  name: example-backup
spec:
  etcdEndpoints:
    - "http://example-client:2379"
  storageType: S3
  s3:
    path: "my-bucket/etcd-backup"

---
# EtcdRestore — описывает задачу восстановления
apiVersion: etcd.database.coreos.com/v1beta2
kind: EtcdRestore
metadata:
  name: example-restore
spec:
  etcdCluster:
    name: example
  backupStorageType: S3
  s3:
    path: "my-bucket/etcd-backup"
```

---

### Operator Lifecycle Manager (OLM)

OLM — это мета-оператор: оператор для управления операторами. Он упрощает установку, обновление и управление операторами в кластере.

**Установка OLM:**

```bash
curl -sL https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.19.1/install.sh \
  | bash -s v0.19.1
```

**Установка оператора через OLM:**

```bash
# Установить etcd оператор из OperatorHub
kubectl create -f https://operatorhub.io/install/etcd.yaml

# Проверить статус установки
kubectl get csv -n my-etcd
# NAME                  DISPLAY   VERSION   PHASE
# etcdoperator.v0.9.4   etcd      0.9.4     Succeeded
```

**OperatorHub (operatorhub.io)** — каталог готовых операторов:
- Prometheus Operator
- Kafka Operator (Strimzi)
- PostgreSQL Operator (Zalando)
- MySQL Operator
- MongoDB Enterprise Operator
- Vault Operator (HashiCorp)
- ArgoCD Operator
- Cert-Manager Operator
- И сотни других

---

### Структура типичного Operator

```
flight-operator/
├── deploy/
│   ├── crds/
│   │   └── flighttickets.flights.com_crd.yaml   # CRD
│   ├── operator.yaml                             # Deployment контроллера
│   ├── role.yaml                                 # RBAC Role
│   ├── role_binding.yaml                         # RBAC RoleBinding
│   └── service_account.yaml                      # ServiceAccount
└── pkg/
    └── controller/
        └── flightticket/
            └── controller.go                     # Логика контроллера
```

Пользователь применяет один файл:

```bash
kubectl apply -f deploy/
```

Или упаковывает в Helm chart / OLM Bundle для распространения.

---

## Итоги и сводная таблица

### Жизненный цикл Kubernetes API

```
Разработка → Alpha → Beta → GA → Deprecated → Removed
               ↓       ↓     ↓
           v1alpha1  v1beta1  v1
           (не включён  (включён  (включён
            по умолч.)  по умолч.) по умолч.)
```

### Сравнение CRD, Custom Controller и Operator

| Компонент | Что делает | Без чего другого работает? |
|-----------|-----------|--------------------------|
| CRD | Регистрирует новый тип ресурса в API | Без контроллера — только хранит данные |
| Custom Controller | Следит за объектами и выполняет логику | Без CRD — некого наблюдать |
| Operator | Пакетирует CRD + Controller | Включает оба компонента |

### Рекомендации по практике

1. **Используй только GA-версии API в продакшне** — никогда не деплой с alpha или beta в реальных кластерах

2. **Следи за announcements о deprecation** — Kubernetes заранее (за 3+ релиза) объявляет об удалении API

3. **Используй `kubectl convert`** при обновлении кластера для массовой конвертации манифестов

4. **При создании CRD обязательно описывай схему** — OpenAPI v3 валидация предотвращает создание некорректных объектов

5. **Контроллер — обязательная часть CRD** в большинстве реальных сценариев; без него объекты мертвы

6. **Операторы — это правильный способ распространять CRD + Controllers** для других команд или open source

7. **Не пиши оператор с нуля** — используй Operator SDK (Go, Ansible, или Helm-based), который генерирует шаблонный код

---

# 9.0 - Helm: Полное руководство по пакетному менеджеру для Kubernetes

---

## 1. Зачем нужен Helm — проблема, которую он решает

Kubernetes — мощный инструмент оркестрации контейнеров, но у него есть существенный недостаток: он работает с объектами **по отдельности**. Каждый объект — это отдельный YAML-файл, и при развёртывании реального приложения их может быть очень много.

Возьмём для примера **WordPress**. Чтобы развернуть его в Kubernetes, вам понадобится создать и поддерживать как минимум следующие объекты:

| Объект Kubernetes | Назначение |
|---|---|
| `Deployment` | Запускает поды с веб-сервером и/или базой данных |
| `PersistentVolume (PV)` | Постоянное хранилище для базы данных |
| `PersistentVolumeClaim (PVC)` | Запрос на использование PV |
| `Service` | Открывает доступ к веб-серверу снаружи |
| `Secret` | Хранит пароль администратора в зашифрованном виде |

Каждый из этих объектов — отдельный YAML-файл. Вот как это выглядит на практике:

```yaml
# secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: wordpress-admin-password
data:
  key: CajnHWVUxSdzIZQzg0SERXhBQTvQ1FzN2JE9PQ==
---
# persistent-volume.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: wordpress-pv
spec:
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteOnce
  gcePersistentDisk:
    pdName: wordpress-2
    fsType: ext4
```

### Какие проблемы возникают при таком подходе?

**Проблема 1: Обновление конфигурации.** Представьте, что вам нужно увеличить размер хранилища с 20 ГБ до 50 ГБ. Вам придётся вручную найти и отредактировать все файлы, где упоминается этот размер: `pv.yaml`, `pvc.yaml`, возможно ещё где-то. Легко что-то пропустить и получить несогласованную конфигурацию.

**Проблема 2: Установка приложения.** Нужно применить все файлы по порядку:
```bash
kubectl apply -f secret.yaml
kubectl apply -f pv.yaml
kubectl apply -f pvc.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```
Если файлов 10–20, это превращается в рутину. Порядок применения важен, и его легко нарушить.

**Проблема 3: Удаление приложения.** Нужно не забыть удалить каждый из созданных объектов. Если что-то пропустить — в кластере остаётся «мусор».

**Проблема 4: Откат.** Если после обновления что-то сломалось, возврат к предыдущей версии требует ручной работы с каждым файлом.

---

## 2. Что такое Helm и как он решает эти проблемы

**Helm** — это пакетный менеджер для Kubernetes. Аналогия проста: если `apt` (в Ubuntu) позволяет установить сложную программу одной командой `apt install nginx`, то Helm позволяет установить сложное Kubernetes-приложение одной командой `helm install`.

Ключевая идея Helm: он **рассматривает всё приложение как единый пакет**, а не как набор разрозненных YAML-файлов.

Другая аналогия из документации — компьютерная игра. Игра состоит из тысяч файлов: исполняемые файлы, графика, звук, конфигурация. Вы не копируете их вручную — вы запускаете **установщик**, который сам разбирается, что куда положить. Helm — это такой установщик для Kubernetes.

### Что умеет Helm

Весь жизненный цикл приложения управляется простыми командами:

```bash
# Установить приложение
helm install wordpress bitnami/wordpress

# Обновить приложение (например, новая версия или изменение конфигурации)
helm upgrade wordpress bitnami/wordpress

# Откатиться к предыдущей версии
helm rollback wordpress

# Полностью удалить приложение
helm uninstall wordpress
```

Одна команда — и Helm сам разберётся со всеми объектами внутри пакета.

---

## 3. Структура Helm-чарта — анатомия пакета

Пакет в терминологии Helm называется **чарт (chart)**. Чарт — это директория с определённой структурой файлов.

### Из чего состоит чарт

```
wordpress/
├── Chart.yaml          # Метаданные чарта
├── values.yaml         # Значения по умолчанию для шаблонов
└── templates/          # Папка с шаблонами Kubernetes-манифестов
    ├── deployment.yaml
    ├── service.yaml
    ├── pv.yaml
    ├── pvc.yaml
    └── secret.yaml
```

Рассмотрим каждый компонент подробно.

---

### 3.1. Chart.yaml — паспорт чарта

Этот файл содержит метаданные о чарте: его название, версию, описание, авторов и т.д.

```yaml
apiVersion: v2
name: wordpress
version: 9.0.3
description: Web publishing platform for building blogs and websites.
keywords:
  - wordpress
  - cms
  - blog
  - http
  - web
  - application
  - php
home: http://www.wordpress.com/
sources:
  - https://github.com/bitnami/bitnami-docker-wordpress
maintainers:
  - email: containers@bitnami.com
    name: Bitnami
```

**Важные поля:**
- `name` — имя чарта
- `version` — версия **самого чарта** (не приложения)
- `description` — текстовое описание
- `maintainers` — список авторов и их контакты

---

### 3.2. values.yaml — центральный файл конфигурации

Это ключевой файл с точки зрения удобства. Все настраиваемые параметры вынесены сюда. Вместо того чтобы редактировать множество YAML-файлов, вы меняете значения в одном месте.

```yaml
# values.yaml для WordPress
image: wordpress:4.8-apache
storage: 20Gi
passwordEncoded: CajhWVUxSdzIZQzg0
```

Позже вы увидите, как эти значения подставляются в шаблоны.

---

### 3.3. templates/ — шаблоны Kubernetes-манифестов

Это обычные Kubernetes YAML-файлы, но с особенностью: вместо конкретных значений в них используются **переменные** в синтаксисе **Go template** (шаблонизатор, встроенный в язык Go).

Синтаксис переменной: `{{ .Values.имяПеременной }}`

Значение `.Values.имяПеременной` берётся из файла `values.yaml`.

#### templates/deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
  labels:
    app: wordpress
spec:
  selector:
    matchLabels:
      app: wordpress
      tier: frontend
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: wordpress
        tier: frontend
    spec:
      containers:
        - name: wordpress
          image: {{ .Values.image }}   # <-- переменная! Значение из values.yaml
```

Когда Helm рендерит этот шаблон, он подставляет `{{ .Values.image }}` → `wordpress:4.8-apache` (из values.yaml).

#### templates/pv.yaml

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: wordpress-pv
spec:
  capacity:
    storage: {{ .Values.storage }}   # <-- берётся из values.yaml
  accessModes:
    - ReadWriteOnce
  gcePersistentDisk:
    pdName: wordpress-2
    fsType: ext4
```

#### templates/pvc.yaml

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: wp-pv-claim
  labels:
    app: wordpress
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: {{ .Values.storage }}   # <-- то же значение, что и в pv.yaml
```

Обратите внимание: и `pv.yaml`, и `pvc.yaml` используют `{{ .Values.storage }}`. Когда вы меняете `storage: 20Gi` на `storage: 50Gi` в `values.yaml`, **оба файла автоматически получат новое значение**. Никакого ручного редактирования нескольких файлов.

#### templates/service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: wordpress
  labels:
    app: wordpress
spec:
  ports:
    - port: 80
  selector:
    app: wordpress
    tier: frontend
  type: LoadBalancer
```

#### templates/secret.yaml

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: wordpress-admin-password
data:
  password: {{ .Values.passwordEncoded }}
```

**Важный момент про секреты:** поле `data` в Kubernetes Secret требует значений в кодировке **base64**. Поэтому в `values.yaml` пароль уже должен быть закодирован. Однако Helm предлагает более удобный вариант с использованием встроенной функции `b64enc`:

```yaml
# Вариант 1: Helm сам кодирует пароль в base64
data:
  password: {{ .Values.password | b64enc }}
```

```yaml
# Вариант 2: использовать stringData (Kubernetes сам закодирует)
stringData:
  password: "{{ .Values.password }}"
```

Второй вариант удобнее: можно хранить пароль в читаемом виде в `values.yaml`, а Kubernetes сам выполнит кодирование.

---

### 3.4. Как Helm рендерит шаблоны

Процесс работы Helm можно представить так:

```
values.yaml          templates/*.yaml
     |                      |
     +----------+-----------+
                |
           Helm Engine
           (Go Template)
                |
                v
   Готовые Kubernetes манифесты
                |
                v
       kubectl apply (внутри Helm)
                |
                v
         Kubernetes кластер
```

Helm берёт шаблоны, подставляет в них значения из `values.yaml` и применяет результат к кластеру. Вы можете увидеть, что получится, без реального применения командой `helm template`:

```bash
helm template my-release bitnami/wordpress
```

Эта команда выведет финальные YAML-манифесты в консоль, не отправляя их в кластер.

---

## 4. Установка Helm

### Предварительные требования

Перед установкой Helm необходимо:
1. Иметь работающий кластер Kubernetes
2. Установить и настроить `kubectl`
3. Иметь файл `kubeconfig` с учётными данными для доступа к кластеру

Helm использует тот же `kubeconfig`, что и `kubectl`, для подключения к кластеру.

### Установка на Linux через Snap

Если ваш дистрибутив поддерживает Snap (Ubuntu 16.04+, Fedora и многие другие):

```bash
sudo snap install helm --classic
```

Флаг `--classic` важен: он даёт Helm доступ к файловой системе за пределами sandbox, что необходимо для чтения `kubeconfig` из домашней директории (`~/.kube/config`).

### Установка на Ubuntu/Debian через APT

Это предпочтительный способ для APT-based дистрибутивов:

```bash
# Шаг 1: Добавить GPG-ключ для проверки подлинности пакетов
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -

# Шаг 2: Установить поддержку HTTPS-репозиториев
sudo apt-get install apt-transport-https --yes

# Шаг 3: Добавить репозиторий Helm в список источников APT
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | \
  sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

# Шаг 4: Обновить список пакетов и установить Helm
sudo apt-get update
sudo apt-get install helm
```

### Современный вариант установки через APT (с gpg)

В более новых версиях Ubuntu рекомендуется использовать `gpg --dearmor` вместо устаревшего `apt-key`:

```bash
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | \
  sudo tee /usr/share/keyrings/helm.gpg > /dev/null

sudo apt-get install apt-transport-https --yes

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] \
  https://baltocdn.com/helm/stable/debian/ all main" | \
  sudo tee /etc/apt/sources.list.d/helm.list

sudo apt-get update
sudo apt-get install helm
```

### Проверка установки

После установки убедитесь, что Helm работает:

```bash
helm version
```

Ожидаемый вывод:
```
version.BuildInfo{Version:"v3.9.2", GitCommit:"1addefbfe665c30f4daf868a9adc5600cc064fd", GitTreeState:"clean", GoVersion:"go1.17.12"}
```

Чтобы увидеть список всех доступных команд:

```bash
helm help
```

### Флаг --debug для диагностики

При возникновении проблем добавляйте флаг `--debug` к любой команде для получения подробного вывода:

```bash
helm install my-release bitnami/wordpress --debug
```

Это покажет, какие запросы отправляются в кластер, какие шаблоны рендерятся и т.д.

---

## 5. Репозитории чартов и Artifact Hub

### Что такое Artifact Hub

**Artifact Hub** (artifacthub.io) — это централизованный реестр чартов Helm и других Kubernetes-пакетов от сообщества. Тысячи готовых чартов для популярных приложений: WordPress, MySQL, Redis, Nginx, Prometheus, Grafana и многих других.

Искать чарты можно двумя способами:
1. Через веб-интерфейс на artifacthub.io
2. Через Helm CLI

### Поиск чартов через CLI

```bash
# Поиск на Artifact Hub (глобальный поиск по всем репозиториям)
helm search hub wordpress
```

Пример вывода:
```
URL                                                    CHART VERSION  APP VERSION  DESCRIPTION
https://hub.helm.sh/charts/kube-wordpress/wordp...    0.1.0          1.1          this is my wordpress package
https://hub.helm.sh/charts/groundhog2k/wordpress      0.4.1          5.8.0-apache A Helm chart for Wordpress on Kubernetes
https://hub.helm.sh/charts/bitnami-aks/wordpress      12.1.1         5.8.0        Web publishing platform for Wordpress...
```

### Работа с конкретными репозиториями

Чтобы использовать чарты из конкретного репозитория (например, Bitnami — один из самых популярных), сначала добавьте его:

```bash
# Добавить репозиторий Bitnami
helm repo add bitnami https://charts.bitnami.com/bitnami
```

После этого можно искать чарты внутри этого репозитория:

```bash
helm search repo wordpress
```

Вывод:
```
NAME                CHART VERSION  APP VERSION  DESCRIPTION
bitnami/wordpress   12.1.14        5.8.1        Web publishing platform for building blogs and ...
```

Разница между `helm search hub` и `helm search repo`:
- `helm search hub` — поиск по всему Artifact Hub (нужен интернет)
- `helm search repo` — поиск только в локально добавленных репозиториях (быстрее)

### Управление репозиториями

```bash
# Посмотреть список добавленных репозиториев
helm repo list
```

Пример вывода:
```
NAME      URL
bitnami   https://charts.bitnami.com/bitnami
puppet    https://puppetlabs.github.io/puppetserver-helm-chart
hashicorp https://helm.releases.hashicorp.com
```

```bash
# Обновить индексы репозиториев (как apt-get update)
helm repo update

# Удалить репозиторий
helm repo remove bitnami
```

---

## 6. Установка и управление релизами

### Понятие «релиз»

Каждая установка чарта в Helm называется **релизом (release)**. Один и тот же чарт можно установить несколько раз под разными именами — каждый экземпляр будет независимым релизом.

Это как запустить одну и ту же программу несколько раз: каждый запуск независим, у каждого своё состояние.

### Установка чарта

```bash
# Синтаксис: helm install <имя-релиза> <чарт>
helm install my-release bitnami/wordpress
```

Можно установить тот же чарт несколько раз:

```bash
helm install release-1 bitnami/wordpress
helm install release-2 bitnami/wordpress
helm install release-3 bitnami/wordpress
```

Каждый из этих релизов создаёт отдельный набор Kubernetes-объектов. Полезно, например, для разворачивания одного приложения в нескольких окружениях (dev, staging, production) в одном кластере.

### Просмотр установленных релизов

```bash
helm list
```

Пример вывода:
```
NAME    NAMESPACE  REVISION  UPDATED                      STATUS    CHART                   APP VERSION
bravo   default    1         2022-08-04 18:50:12 +0000 UTC deployed  drupal-12.3.3           9.4.4
```

Колонки:
- `NAME` — имя релиза
- `NAMESPACE` — пространство имён Kubernetes
- `REVISION` — номер версии (увеличивается при каждом `helm upgrade`)
- `STATUS` — статус (deployed, failed, pending и т.д.)
- `CHART` — имя и версия чарта
- `APP VERSION` — версия самого приложения

### Удаление релиза

```bash
helm uninstall bravo
```

Вывод:
```
release "bravo" uninstalled
```

Helm удалит **все** Kubernetes-объекты, связанные с этим релизом. Никакого ручного перечисления объектов для удаления.

### Обновление и откат

```bash
# Обновить релиз (новая версия чарта или новые значения)
helm upgrade my-release bitnami/wordpress

# Посмотреть историю изменений релиза
helm history my-release

# Откатиться к предыдущей версии
helm rollback my-release

# Откатиться к конкретной версии
helm rollback my-release 1
```

Когда вы делаете `helm upgrade`, REVISION увеличивается. `helm rollback` возвращает к предыдущему состоянию.

---

## 7. Скачивание и модификация чартов

Иногда готовый чарт не полностью соответствует вашим требованиям, и нужно его модифицировать. Helm позволяет скачать чарт локально, изменить его и установить из локальной директории.

### Скачать чарт без установки

```bash
# Скачать и распаковать чарт в текущую директорию
helm pull --untar bitnami/apache

# Проверить содержимое
ls
# apache/

cd apache/
ls
# Chart.lock  Chart.yaml  README.md  templates/  values.yaml  ci/  values.schema.json
```

### Модифицировать values.yaml

Допустим, нам нужно:
1. Установить количество реплик веб-сервера = 2
2. Настроить NodePort 30080 для HTTP

Открываем `values.yaml` и вносим изменения в соответствующие секции. Например:

```yaml
# В values.yaml Apache чарта
replicaCount: 2

service:
  type: NodePort
  port: 80
  nodePorts:
    http: "30080"
```

### Установить из локальной директории

```bash
# Точка (.) означает "текущая директория"
helm install mywebapp .
```

Helm возьмёт чарт из текущей директории `apache/` и установит его под именем `mywebapp`.

```bash
helm list
# NAME      NAMESPACE  REVISION  ...  CHART          APP VERSION
# mywebapp  default    1         ...  apache-X.X.X   X.X.X
```

После установки можно получить URL сервиса:

```bash
export SERVICE_IP=$(kubectl get svc --namespace default mywebapp-apache \
  --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
echo URL: http://$SERVICE_IP/
```

---

## 8. Полная таблица команд Helm

| Команда | Описание |
|---|---|
| `helm search hub <keyword>` | Поиск чартов на Artifact Hub |
| `helm search repo <keyword>` | Поиск чартов в локальных репозиториях |
| `helm repo add <name> <url>` | Добавить репозиторий |
| `helm repo list` | Показать список репозиториев |
| `helm repo update` | Обновить индексы репозиториев |
| `helm repo remove <name>` | Удалить репозиторий |
| `helm install <release> <chart>` | Установить чарт как релиз |
| `helm list` | Показать список релизов |
| `helm upgrade <release> <chart>` | Обновить релиз |
| `helm rollback <release> [revision]` | Откатить релиз |
| `helm history <release>` | История версий релиза |
| `helm uninstall <release>` | Удалить релиз |
| `helm pull --untar <chart>` | Скачать и распаковать чарт локально |
| `helm template <release> <chart>` | Отрендерить шаблоны без установки |
| `helm status <release>` | Статус релиза |
| `helm show values <chart>` | Показать values.yaml чарта |
| `helm version` | Версия Helm |
| `helm help` | Справка по командам |

---

## 9. Практический сквозной пример

Давайте пройдём полный цикл работы с Helm на примере из документации — установка Drupal и Apache.

### Шаг 1: Проверка системы

```bash
cat /etc/*release*
# Убеждаемся, что это Ubuntu
```

### Шаг 2: Установка Helm (если ещё не установлен)

```bash
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | \
  sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] \
  https://baltocdn.com/helm/stable/debian/ all main" | \
  sudo tee /etc/apt/sources.list.d/helm.list
sudo apt-get update && sudo apt-get install helm
helm version  # Проверяем
```

### Шаг 3: Добавить репозиторий Bitnami

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
# "bitnami" has been added to your repositories
```

### Шаг 4: Поиск чартов

```bash
helm search hub wordpress
helm search repo joomla
# NAME           CHART VERSION  APP VERSION  DESCRIPTION
# bitnami/joomla 13.2.16        4.1.5        Joomla! is an award winning open source CMS...
```

### Шаг 5: Установка Drupal

```bash
helm install bravo bitnami/drupal
helm list
# NAME   NAMESPACE  REVISION  STATUS    CHART          APP VERSION
# bravo  default    1         deployed  drupal-12.3.3  9.4.4
```

### Шаг 6: Удаление Drupal

```bash
helm uninstall bravo
# release "bravo" uninstalled
```

### Шаг 7: Скачать и модифицировать Apache

```bash
helm pull --untar bitnami/apache
cd apache/
# Редактируем values.yaml: replicaCount: 2, NodePort: 30080
helm install mywebapp .
helm list
# NAME      STATUS    CHART
# mywebapp  deployed  apache-X.X.X
```

---

## 10. Итоги и выводы

**Helm решает реальную проблему:** управление сложными Kubernetes-приложениями, состоящими из множества объектов, без него превращается в ручную рутину, чреватую ошибками.

**Три ключевые концепции Helm:**
1. **Чарт** — пакет с шаблонами, values.yaml и метаданными. Это «рецепт» приложения.
2. **values.yaml** — единая точка конфигурации. Меняешь здесь — меняется везде.
3. **Релиз** — конкретная установка чарта. Один чарт можно установить несколько раз.

**Главные преимущества:**
- Установка/обновление/откат/удаление одной командой
- Централизованная конфигурация в `values.yaml`
- Огромная экосистема готовых чартов на Artifact Hub
- Версионирование и история изменений
- Повторяемость: один и тот же чарт даёт предсказуемый результат в любом кластере

Helm существенно снижает операционную нагрузку и позволяет разработчикам сосредоточиться на приложении, а не на деталях управления Kubernetes-объектами.

---

# 10.1 - Kustomize: Полное руководство на русском языке

Это развёрнутое руководство охватывает всё, что описано в документации: установку, базовое использование, управление директориями, трансформеры и сравнение с Helm.

---

## Часть 1. Что такое Kustomize и зачем он нужен?

Когда вы работаете с Kubernetes, у вас есть YAML-файлы, описывающие ваши ресурсы: Deployment, Service, ConfigMap и так далее. Проблема возникает, когда нужно развернуть одно и то же приложение в нескольких окружениях — разработке (dev), тестировании (staging) и продакшне (prod). В каждом окружении будут небольшие отличия: количество реплик, теги образов, названия namespace и прочее.

**Kustomize** — это инструмент, который позволяет управлять этими отличиями без дублирования YAML-файлов и без введения сложного синтаксиса шаблонов. Вы пишете базовые конфигурации один раз, а затем описываете только отличия для каждого окружения. Kustomize встроен в `kubectl` начиная с версии 1.14, что делает его доступным без дополнительной установки.

---

## Часть 2. Установка Kustomize

Прежде чем начать, убедитесь, что у вас есть:

- Работающий кластер Kubernetes
- Установленный и настроенный `kubectl`
- Linux, macOS или Windows

### Установка через скрипт

```bash
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
```

Этот скрипт автоматически определит вашу операционную систему и скачает подходящую версию Kustomize.

### Проверка установки

```bash
kustomize version --short
```

Ожидаемый вывод:

```bash
{kustomize/v4.4.1 2021-11-11T23:36:27Z}
```

**Важно:** Если вывод не появляется, попробуйте закрыть и снова открыть терминал — переменные окружения могут не обновиться сразу. Если проблема сохраняется, запустите скрипт установки повторно.

---

## Часть 3. Как работает вывод Kustomize

Это один из ключевых моментов, который часто вызывает путаницу у новичков.

Команда `kustomize build` **не применяет** конфигурации к кластеру — она только генерирует финальный YAML и выводит его в консоль. Это удобно для предварительного просмотра того, что будет создано.

```bash
kustomize build k8s/
```

Вы увидите результирующий YAML в терминале, но в кластере ничего не изменится. Команды `kubectl get pods` или `kubectl get deployments` ничего нового не покажут.

### Применение конфигураций

**Способ 1 — через pipe:**

```bash
kustomize build k8s/ | kubectl apply -f -
```

Здесь оператор `|` (pipe) передаёт вывод `kustomize build` на вход команде `kubectl apply -f -`. Символ `-` означает "читать из стандартного ввода".

**Способ 2 — встроенная поддержка в kubectl:**

```bash
kubectl apply -k k8s/
```

Флаг `-k` говорит kubectl использовать Kustomize для обработки директории. Оба способа дают одинаковый результат.

Пример успешного вывода:

```bash
service/nginx-loadbalancer-service created
deployment.apps/nginx-deployment created
```

### Удаление конфигураций

Аналогично, но вместо `apply` используется `delete`:

```bash
# Способ 1
kustomize build k8s/ | kubectl delete -f -

# Способ 2
kubectl delete -k k8s/
```

Результат:

```bash
service "nginx-loadbalancer-service" deleted
deployment.apps "nginx-deployment" deleted
```

**Рекомендация:** Всегда сначала просматривайте вывод `kustomize build` перед применением, чтобы убедиться, что конфигурации соответствуют ожиданиям.

---

## Часть 4. Управление директориями

По мере роста проекта количество YAML-файлов увеличивается. Разберём, как Kustomize помогает организовать их структуру.

### Типичная проблема без Kustomize

Представьте директорию `k8s/` с четырьмя файлами:

```
k8s/
├── api-depl.yaml
├── api-service.yaml
├── db-depl.yaml
└── db-service.yaml
```

Применить всё сразу просто:

```bash
kubectl apply -f k8s/
```

Но когда файлов становится 20–50, директория превращается в хаос. Логично разделить их по поддиректориям:

```
k8s/
├── api/
│   ├── api-depl.yaml
│   └── api-service.yaml
└── db/
    ├── db-depl.yaml
    └── db-service.yaml
```

Теперь одной командой не обойтись — приходится применять каждую директорию отдельно:

```bash
kubectl apply -f k8s/api/
kubectl apply -f k8s/db/
```

А если добавятся ещё компоненты (Redis, Kafka), команд станет ещё больше. Это неудобно, особенно в CI/CD-пайплайнах.

### Решение: корневой kustomization.yaml

Создайте файл `k8s/kustomization.yaml` и перечислите в нём все ресурсы:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - api/api-depl.yaml
  - api/api-service.yaml
  - db/db-depl.yaml
  - db/db-service.yaml
```

Теперь достаточно одной команды:

```bash
kubectl apply -k k8s/
```

### Масштабирование: добавление новых компонентов

Если появляются Redis и Kafka, корневой файл расширяется:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - api/api-depl.yaml
  - api/api-service.yaml
  - db/db-depl.yaml
  - db/db-service.yaml
  - cache/redis-depl.yaml
  - cache/redis-service.yaml
  - cache/redis-config.yaml
  - kafka/kafka-depl.yaml
  - kafka/kafka-service.yaml
  - kafka/kafka-config.yaml
```

Это работает, но корневой файл снова становится громоздким.

### Элегантное решение: kustomization.yaml в каждой поддиректории

Лучший подход — создать свой `kustomization.yaml` в каждой поддиректории:

**`k8s/api/kustomization.yaml`:**

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - api-depl.yaml
  - api-service.yaml
```

**`k8s/db/kustomization.yaml`:**

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - db-depl.yaml
  - db-service.yaml
```

**`k8s/cache/kustomization.yaml`:**

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - redis-depl.yaml
  - redis-service.yaml
  - redis-config.yaml
```

**Корневой `k8s/kustomization.yaml`** теперь просто ссылается на директории:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - api/
  - db/
  - cache/
  - kafka/
```

Когда вы запускаете `kubectl apply -k k8s/`, Kustomize рекурсивно обходит все поддиректории, находит в каждой `kustomization.yaml` и собирает все ресурсы в единую конфигурацию.

### Полный практический пример

Допустим, у вас такая структура с файлами:

**`k8s/cache/redis-service.yaml`:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: redis-cluster-ip-service
spec:
  type: ClusterIP
  selector:
    component: redis
  ports:
    - port: 6379
      targetPort: 6379
```

**`k8s/cache/redis-config.yaml`:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: redis-credentials
data:
  username: "redis"
  password: "password123"
```

После применения `kubectl apply -k k8s/` успешный вывод будет выглядеть так:

```bash
configmap/db-credentials created
configmap/redis-credentials created
service/api-service created
service/db-service created
service/redis-cluster-ip-service created
deployment.apps/api-deployment created
deployment.apps/db-deployment created
deployment.apps/redis-deployment created
```

Проверка запущенных подов:

```bash
kubectl get pods
NAME                                    READY   STATUS    RESTARTS   AGE
api-deployment-64dd567b46-1mw4c         1/1     Running   0          27s
db-deployment-657c8ffbd-vnjs7           1/1     Running   0          26s
redis-deployment-587fd758cf-7pt57       1/1     Running   0          26s
```

---

## Часть 5. Common Transformers — общие трансформеры

Трансформеры — это одна из самых мощных возможностей Kustomize. Они позволяют автоматически применять одинаковые изменения ко всем ресурсам без ручного редактирования каждого файла.

Представьте, что у вас есть файлы:

**`db-depl.yaml`:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      component: api
  template:
    metadata:
      labels:
        component: api
    spec:
      containers:
      - name: nginx
        image: nginx
```

**`db-service.yaml`:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: db-service
spec:
  selector:
    component: db-depl
  ports:
  - protocol: "TCP"
    port: 27017
    targetPort: 27017
  type: LoadBalancer
```

Добавить метку `org: KodeKloud` вручную в каждый файл — задача нетривиальная при десятках ресурсов. Трансформеры делают это автоматически.

### 1. Common Labels — общие метки

Добавляет указанную метку ко всем ресурсам. В `kustomization.yaml`:

```yaml
commonLabels:
  org: KodeKloud
```

После применения каждый ресурс получит эту метку в своём `metadata`. Метка также добавляется в `selector` и `template.metadata.labels` Deployment-ов, что важно для правильной работы Kubernetes.

### 2. Namespace — пространство имён

Назначает единый namespace всем ресурсам:

```yaml
namespace: lab
```

Все ресурсы будут развёрнуты в пространстве имён `lab`. Это особенно полезно, когда нужно изолировать окружения (dev, staging, prod) в разные namespace.

### 3. Prefix/Suffix — префикс и суффикс имён

Автоматически изменяет имена всех ресурсов:

```yaml
namePrefix: KodeKLOUD-
nameSuffix: -dev
```

Если был ресурс с именем `api-service`, после трансформации его имя станет `KodeKLOUD-api-service-dev`. Это помогает легко различать ресурсы из разных окружений.

### 4. Common Annotations — общие аннотации

Добавляет аннотации ко всем ресурсам:

```yaml
commonAnnotations:
  branch: master
```

Аннотации — это произвольные метаданные, которые не влияют на поведение Kubernetes, но полезны для CI/CD-систем, систем мониторинга и других инструментов.

### Итоговая таблица трансформеров

| Трансформер | Назначение | Пример конфигурации |
|---|---|---|
| `commonLabels` | Добавить метку всем ресурсам | `org: KodeKloud` |
| `namespace` | Назначить namespace | `namespace: lab` |
| `namePrefix` / `nameSuffix` | Изменить имена ресурсов | `namePrefix: KodeKLOUD-` |
| `commonAnnotations` | Добавить аннотации всем ресурсам | `branch: master` |

---

## Часть 6. Image Transformer — трансформер образов

Трансформер образов позволяет обновлять контейнерные образы в манифестах без ручного редактирования каждого файла.

### Базовый пример: смена образа

Исходный `deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      component: web
  template:
    metadata:
      labels:
        component: web
    spec:
      containers:
      - name: web
        image: nginx
```

В `kustomization.yaml` указываем замену:

```yaml
images:
- name: nginx
  newName: haproxy
```

**Важно:** `name` здесь — это имя образа (то, что указано в поле `image:`), а не имя контейнера (поле `name:`). Kustomize сканирует все файлы и заменяет образ `nginx` на `haproxy`.

Результат:

```yaml
containers:
- name: web
  image: haproxy
```

### Смена тега образа

Если нужно только обновить версию образа:

```yaml
images:
- name: nginx
  newTag: "2.4"
```

Результат:

```yaml
containers:
- name: web
  image: nginx:2.4
```

**Важно:** Тег всегда указывайте в кавычках, чтобы избежать проблем с преобразованием типов (например, `2.4` без кавычек может быть распознано как число).

### Одновременная смена образа и тега

```yaml
images:
- name: nginx
  newName: haproxy
  newTag: "2.4"
```

Результат:

```yaml
containers:
- name: web
  image: haproxy:2.4
```

---

## Часть 7. Практический демо-пример со всеми трансформерами

Рассмотрим реальный проект с такой структурой:

```
k8s/
├── kustomization.yaml
├── api/
│   ├── api-depl.yaml
│   ├── api-service.yaml
│   └── kustomization.yaml
└── db/
    ├── db-depl.yaml
    ├── db-service.yaml
    ├── db-config.yaml
    └── kustomization.yaml
```

**`k8s/api/kustomization.yaml`:**

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - api-depl.yaml
  - api-service.yaml
```

**`k8s/db/kustomization.yaml`:**

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - db-config.yaml
  - db-depl.yaml
  - db-service.yaml
```

### Шаг 1: Добавляем общую метку ко всем ресурсам

**`k8s/kustomization.yaml`:**

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - api/
  - db/

commonLabels:
  department: engineering
```

После `kustomize build k8s/` каждый ресурс получит метку `department: engineering`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  labels:
    department: engineering
  name: db-credentials
---
apiVersion: v1
kind: Service
metadata:
  labels:
    department: engineering
  name: api-service
```

### Шаг 2: Добавляем метку только для API-ресурсов

Обновляем `k8s/api/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - api-depl.yaml
  - api-service.yaml

commonLabels:
  feature: api
```

Теперь API-ресурсы получат обе метки (`department: engineering` из корня + `feature: api` из поддиректории), а DB-ресурсы — только `department: engineering`.

### Шаг 3: Назначаем namespace

**`k8s/kustomization.yaml`:**

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - api/
  - db/

commonLabels:
  department: engineering

namespace: debugging
```

Все ресурсы попадут в namespace `debugging`.

### Шаг 4: Префиксы и суффиксы имён

Глобальный префикс в корне:

```yaml
namePrefix: KodeKloud-
```

Суффикс для API в `k8s/api/kustomization.yaml`:

```yaml
nameSuffix: -web
```

Суффикс для DB в `k8s/db/kustomization.yaml`:

```yaml
nameSuffix: -storage
```

Итоговые имена ресурсов:
- API: `KodeKloud-api-deployment-web`, `KodeKloud-api-service-web`
- DB: `KodeKloud-db-deployment-storage`, `KodeKloud-db-credentials-storage`

### Шаг 5: Общие аннотации

```yaml
commonAnnotations:
  logging: verbose
```

Каждый ресурс получит аннотацию `logging: verbose`.

### Шаг 6: Смена образа в DB

В `k8s/db/kustomization.yaml` меняем MongoDB на PostgreSQL:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - db-config.yaml
  - db-depl.yaml
  - db-service.yaml

commonLabels:
  feature: db

nameSuffix: -storage

images:
  - name: mongo
    newName: postgres
    newTag: "4.2"
```

Результат в манифесте:

```yaml
spec:
  containers:
    - name: mongo          # имя контейнера остаётся прежним
      image: postgres:4.2  # образ изменён
      env:
        - name: MONGO_INITDB_ROOT_USERNAME
          valueFrom:
            configMapKeyRef:
              key: username
              name: KodeKloud-db-credentials-storage
```

Обратите внимание: имя контейнера (`name: mongo`) осталось неизменным — трансформер меняет только поле `image:`, но не `name:`.

---

## Часть 8. Kustomize vs Helm — сравнение инструментов

Оба инструмента решают одну задачу: управление конфигурациями Kubernetes для разных окружений. Но подходят к этому по-разному.

### Как работает Helm

Helm использует синтаксис шаблонов Go (Go templating). Вместо конкретных значений в YAML-файлах размещаются переменные в двойных фигурных скобках:

```yaml
# Deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.name }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Values.name }}
  template:
    metadata:
      labels:
        app: {{ .Values.name }}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "nginx:{{ .Values.image.tag }}"
```

Значения для переменных хранятся в отдельном файле:

```yaml
# values.yaml
replicaCount: 1
image:
  tag: "2.4.4"
```

Для разных окружений создаются разные файлы значений:

```
k8s/
└── environments/
    ├── values.dev.yaml
    ├── values.stg.yaml
    └── values.prod.yaml
└── templates/
    ├── nginx-deployment.yaml
    ├── nginx-service.yaml
    ├── db-deployment.yaml
    └── db-service.yaml
```

При развёртывании указывается нужный файл: `helm install myapp -f values.prod.yaml`

### Возможности Helm

Helm — это не просто инструмент шаблонизации, это полноценный пакетный менеджер для Kubernetes (аналог `apt` или `yum` для Linux). Он поддерживает:

- **Условные конструкции** (`if/else`)
- **Циклы** (`range`)
- **Функции** (встроенные функции Go templates)
- **Hooks** (выполнение действий до/после установки)
- **Зависимости** (один chart может зависеть от других)
- **Rollback** (откат к предыдущей версии)

### Сравнительная таблица

| Характеристика | Helm | Kustomize |
|---|---|---|
| Подход | Go-шаблоны с переменными | Чистый YAML + overlay-патчи |
| Сложность | Выше (нужно знать синтаксис шаблонов) | Ниже (только стандартный YAML) |
| Читаемость | Ниже (файлы не являются валидным YAML до рендеринга) | Выше (всегда валидный YAML) |
| Пакетный менеджер | Да (аналог apt/yum) | Нет (только кастомизация) |
| Условия и циклы | Да | Нет (ограниченная логика) |
| Hooks | Да | Нет |
| Встроен в kubectl | Нет (отдельная установка) | Да (с версии 1.14) |

### Когда выбирать что

**Kustomize подходит, когда:**
- Вам нужна простота и прозрачность конфигураций
- Ваша команда не хочет изучать синтаксис шаблонов
- Изменения между окружениями минимальны (разные теги образов, количество реплик)
- Важна читаемость YAML-файлов (полезно при аудите и code review)

**Helm подходит, когда:**
- Нужны сложные условия и логика в конфигурациях
- Вы хотите использовать готовые пакеты из Helm Hub (например, установить PostgreSQL одной командой)
- Нужен rollback к предыдущим версиям
- Важна зависимость между компонентами (один chart зависит от другого)

---

## Итоги и выводы

Kustomize — это элегантный инструмент для управления Kubernetes-конфигурациями, который придерживается принципа "конфигурация — это YAML, и только YAML". Вот ключевые идеи:

**1. Разделение ответственности через директории.** Организуйте манифесты по компонентам (api, db, cache), создайте `kustomization.yaml` в каждой поддиректории, а корневой файл пусть просто ссылается на директории. Это делает структуру масштабируемой и понятной.

**2. Два способа применения.** Можно использовать `kustomize build k8s/ | kubectl apply -f -` или встроенный в kubectl флаг `-k`. Второй способ проще, но первый даёт возможность посмотреть на финальный YAML перед применением.

**3. Трансформеры автоматизируют рутину.** Вместо того чтобы вручную добавлять метки, namespace или менять имена в десятках файлов, достаточно одной строки в `kustomization.yaml`. Трансформеры можно применять глобально (в корневом файле) или локально (в файле поддиректории).

**4. Image transformer особенно полезен в CI/CD.** В пайплайне сборки вы можете динамически задавать тег образа в `kustomization.yaml`, и он будет применён ко всем манифестам автоматически.

**5. Helm мощнее, но сложнее.** Если ваши конфигурации просты — используйте Kustomize. Если нужна сложная логика или готовые пакеты — Helm. На практике многие команды используют оба инструмента вместе: Helm для установки сторонних пакетов, Kustomize для кастомизации собственных приложений.

---

# 10.2 - Kustomize: Патчи, Overlays и Components — Полное руководство

---

## Часть 1. Введение в патчи (Patches)

Трансформеры, которые мы рассматривали ранее, применяют изменения широко — ко всем ресурсам сразу. Но что если нужно изменить только одно конкретное поле в одном конкретном ресурсе? Для этого в Kustomize существуют **патчи (patches)** — хирургический инструмент точечного изменения конфигураций.

Патч позволяет:
- Нацелиться на конкретный ресурс (например, только на Deployment с именем `api-deployment`)
- Изменить только одно поле (например, только количество реплик)
- Не затрагивать остальные ресурсы и остальные поля

### Три компонента любого патча

Каждый патч состоит из трёх обязательных элементов:

**1. Operation Type (тип операции)** — что именно делаем:
- `add` — добавить новый элемент (например, новый контейнер в список)
- `remove` — удалить существующий элемент (например, убрать метку)
- `replace` — заменить существующее значение на новое (например, поменять количество реплик)

**2. Target (цель)** — какой ресурс патчим. Можно указывать критерии:
- `kind` — тип ресурса (Deployment, Service, ConfigMap...)
- `name` — имя ресурса
- `namespace` — пространство имён
- `labelSelector` — выбор по меткам
- `annotationSelector` — выбор по аннотациям

**3. Value (значение)** — новые данные. При операции `remove` это поле не нужно.

---

## Часть 2. Два метода определения патчей

Kustomize поддерживает два принципиально разных синтаксиса для написания патчей. Оба метода можно использовать как inline (прямо в `kustomization.yaml`), так и через внешние файлы.

### Метод 1: JSON 6902 Patch

Назван в честь стандарта RFC 6902, описывающего формат JSON Patch. Явно указывает операцию, путь и значение. Это точный и детальный подход.

**Inline-вариант в `kustomization.yaml`:**

```yaml
patches:
  - target:
      kind: Deployment
      name: api-deployment
    patch: |-
      - op: replace
        path: /spec/replicas
        value: 5
```

**Через внешний файл:**

В `kustomization.yaml`:

```yaml
patches:
  - path: replica-patch.yaml
    target:
      kind: Deployment
      name: nginx-deployment
```

В `replica-patch.yaml`:

```yaml
- op: replace
  path: /spec/replicas
  value: 5
```

### Метод 2: Strategic Merge Patch

Этот подход похож на обычный Kubernetes-манифест. Вы пишете фрагмент YAML, который выглядит как сам ресурс, но содержит только те поля, которые хотите изменить. Kustomize "сливает" (merge) этот фрагмент с исходным ресурсом.

**Inline-вариант в `kustomization.yaml`:**

```yaml
patches:
  - patch: |-
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: api-deployment
      spec:
        replicas: 5
```

**Через внешний файл:**

В `kustomization.yaml`:

```yaml
patches:
  - path: replica-patch.yaml
```

В `replica-patch.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-deployment
spec:
  replicas: 5
```

### Сравнение двух методов

| Характеристика | JSON 6902 | Strategic Merge |
|---|---|---|
| Синтаксис | Явные операции (op, path, value) | Фрагмент Kubernetes-манифеста |
| Читаемость | Менее привычный синтаксис | Выглядит как обычный YAML |
| Точность пути | Явный JSON Pointer (`/spec/replicas`) | Структура YAML |
| Удаление элементов | `op: remove` | Установить значение в `null` или `$patch: delete` |
| Когда использовать | Когда нужен точный контроль над операцией | Когда важна читаемость |

**Рекомендация:** Если вы работаете в команде и важна читаемость — используйте Strategic Merge Patch. Если нужна строгая гарантия операции (особенно при работе со списками) — JSON 6902.

---

## Часть 3. Базовые примеры патчей

### Пример 1: Переименование deployment

Исходный `deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      component: api
  template:
    metadata:
      labels:
        component: api
    spec:
      containers:
        - name: nginx
          image: nginx
```

Патч в `kustomization.yaml` (JSON 6902):

```yaml
patches:
  - target:
      kind: Deployment
      name: api-deployment
    patch: |-
      - op: replace
        path: /metadata/name
        value: web-deployment
```

После применения:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment    # <-- изменено
spec:
  replicas: 1
  ...
```

Путь `/metadata/name` — это JSON Pointer: слэш `/` разделяет уровни вложенности YAML. Полный путь читается как "в объекте `metadata`, поле `name`".

### Пример 2: Изменение количества реплик

```yaml
patches:
  - target:
      kind: Deployment
      name: api-deployment
    patch: |
      - op: replace
        path: /spec/replicas
        value: 5
```

Путь `/spec/replicas` — "в объекте `spec`, поле `replicas`".

---

## Часть 4. Патчи для словарей (Dictionary) — работа с метками и полями

Словари (dictionary) в YAML — это набор пар ключ-значение. Метки (`labels`) и аннотации (`annotations`) — классические примеры словарей.

Исходный deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      component: api
  template:
    metadata:
      labels:
        component: api
    spec:
      containers:
      - name: nginx
        image: nginx
```

### Обновление метки (replace) — JSON 6902

Меняем значение метки `component` с `api` на `web`:

```yaml
patches:
  - target:
      kind: Deployment
      name: api-deployment
    patch: |-
      - op: replace
        path: /spec/template/metadata/labels/component
        value: web
```

Путь `/spec/template/metadata/labels/component` читается буквально: `spec` → `template` → `metadata` → `labels` → ключ `component`.

### Обновление метки (replace) — Strategic Merge Patch

Тот же результат через Strategic Merge, хранящийся в отдельном файле `label-patch.yaml`:

В `kustomization.yaml`:

```yaml
patches:
  - label-patch.yaml
```

В `label-patch.yaml` — только изменяемые поля:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-deployment
spec:
  template:
    metadata:
      labels:
        component: web
```

Kustomize найдёт deployment с именем `api-deployment` (по `metadata.name`) и обновит только указанные поля.

### Добавление новой метки (add) — JSON 6902

Добавляем метку `org: KodeKloud`, сохраняя существующую `component: api`:

```yaml
patches:
  - target:
      kind: Deployment
      name: api-deployment
    patch: |-
      - op: add
        path: /spec/template/metadata/labels/org
        value: KodeKloud
```

Результат в `labels`:

```yaml
labels:
  component: api
  org: KodeKloud
```

### Добавление новой метки (add) — Strategic Merge Patch

В `label-patch.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-deployment
spec:
  template:
    metadata:
      labels:
        org: kodekloud
```

При merge Kustomize добавит новую метку, не удаляя существующие. Результат:

```yaml
labels:
  component: api    # осталась
  org: kodekloud    # добавлена
```

### Удаление метки (remove) — JSON 6902

Предположим, у нас deployment с двумя метками:

```yaml
template:
  metadata:
    labels:
      org: KodeKloud
      component: api
```

Удаляем метку `org`:

```yaml
patches:
  - target:
      kind: Deployment
      name: api-deployment
    patch: |-
      - op: remove
        path: /spec/template/metadata/labels/org
```

После применения остаётся только `component: api`. Заметьте: для операции `remove` поле `value` не нужно.

### Удаление метки (remove) — Strategic Merge Patch

В Strategic Merge удаление делается через присвоение значения `null`:

В `label-patch.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-deployment
spec:
  template:
    metadata:
      labels:
        org: null
```

Kustomize интерпретирует `null` как команду удалить этот ключ.

---

## Часть 5. Патчи для списков (List) — работа с контейнерами

Списки (list) в YAML отличаются от словарей тем, что элементы обозначаются дефисом `-`. Список `containers` — самый частый пример. Работа со списками через JSON 6902 использует числовые индексы (нумерация с нуля).

Исходный deployment с одним контейнером:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      component: api
  template:
    metadata:
      labels:
        component: api
    spec:
      containers:
      - name: nginx
        image: nginx
```

### Замена контейнера — JSON 6902

Меняем nginx на haproxy. Контейнер находится в списке под индексом `0` (первый элемент):

```yaml
patches:
  - target:
      kind: Deployment
      name: api-deployment
    patch: |-
      - op: replace
        path: /spec/template/spec/containers/0
        value:
          name: haproxy
          image: haproxy
```

Путь `/spec/template/spec/containers/0` — обращение к нулевому элементу списка `containers`.

### Замена контейнера — Strategic Merge Patch

Strategic Merge для списков работает умнее: он ищет элемент по имени (`name`), а не по индексу. Это безопаснее, так как порядок элементов может меняться:

В `label-patch.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-deployment
spec:
  template:
    spec:
      containers:
      - name: nginx        # ищет контейнер с этим именем
        image: haproxy     # меняет только image
```

### Добавление нового контейнера — JSON 6902

Символ `-` в конце пути означает "добавить в конец списка":

```yaml
patches:
  - target:
      kind: Deployment
      name: api-deployment
    patch: |-
      - op: add
        path: /spec/template/spec/containers/-
        value:
          name: haproxy
          image: haproxy
```

После применения deployment будет содержать два контейнера:

```yaml
containers:
  - name: nginx
    image: nginx
  - name: haproxy
    image: haproxy
```

### Удаление контейнера из списка — JSON 6902

Допустим, есть два контейнера и нужно удалить второй:

```yaml
spec:
  containers:
    - name: web
      image: nginx
    - name: database
      image: mongo
```

Удаляем `database` (индекс `1`):

```yaml
patches:
  - target:
      kind: Deployment
      name: api-deployment
    patch:
      - op: remove
        path: /spec/template/spec/containers/1
```

**Важно:** Всегда проверяйте правильность индекса. Если в списке три контейнера, а вы укажете индекс `2`, будет удалён третий, а не второй.

### Удаление контейнера — Strategic Merge Patch

Используется специальная директива `$patch: delete`. Kustomize находит контейнер по имени и удаляет его:

В `label-patch.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-deployment
spec:
  template:
    spec:
      containers:
      - $patch: delete
        name: database
```

В `kustomization.yaml`:

```yaml
patches:
  - label-patch.yaml
```

После применения остаётся только контейнер `web`.

---

## Часть 6. Overlays — управление несколькими окружениями

Overlays (оверлеи) — это одна из главных концепций Kustomize, которая отвечает на вопрос: как деплоить одно приложение в dev, staging и prod с разными конфигурациями, не дублируя YAML?

### Концепция Base + Overlay

**Base (база)** — общие конфигурации, одинаковые для всех окружений.
**Overlay (оверлей)** — набор патчей и дополнений, специфичных для конкретного окружения.

Overlay ссылается на base и добавляет к нему изменения.

### Структура директорий

```
k8s/
├── base/
│   ├── kustomization.yaml
│   ├── nginx-depl.yaml
│   ├── service.yaml
│   └── redis-depl.yaml
└── overlays/
    ├── dev/
    │   ├── kustomization.yaml
    │   └── config-map.yaml
    ├── stg/
    │   ├── kustomization.yaml
    │   └── config-map.yaml
    └── prod/
        ├── kustomization.yaml
        ├── config-map.yaml
        └── grafana-depl.yaml
```

### Базовая конфигурация

**`k8s/base/kustomization.yaml`:**

```yaml
resources:
  - nginx-depl.yaml
  - service.yaml
  - redis-depl.yaml
```

**`k8s/base/nginx-depl.yaml`:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 1
```

### Overlay для development

В dev-окружении нужно 2 реплики вместо 1:

**`k8s/overlays/dev/kustomization.yaml`:**

```yaml
bases:
  - ../../base

patch: |-
  - op: replace
    path: /spec/replicas
    value: 2
```

Поле `bases` указывает на базовую директорию через относительный путь. Kustomize сначала загружает все ресурсы из base, затем применяет патчи из overlay.

### Overlay для production

В prod нужно 3 реплики:

**`k8s/overlays/prod/kustomization.yaml`:**

```yaml
bases:
  - ../../base

patch: |-
  - op: replace
    path: /spec/replicas
    value: 3
```

### Добавление новых ресурсов в overlay

Overlays могут не только изменять существующие ресурсы, но и добавлять новые, которых нет в base. Например, в production нужен Grafana:

**Обновлённая структура prod-директории:**

```
overlays/prod/
├── kustomization.yaml
├── config-map.yaml
└── grafana-depl.yaml
```

**`k8s/overlays/prod/kustomization.yaml`:**

```yaml
bases:
  - ../../base

resources:
  - grafana-depl.yaml

patch: |-
  - op: replace
    path: /spec/replicas
    value: 2
```

Здесь overlay делает сразу три вещи:
1. Импортирует все ресурсы из base
2. Добавляет новый ресурс `grafana-depl.yaml`
3. Применяет патч (меняет количество реплик)

### Как применять конкретный overlay

Вместо `k8s/` указывается путь к конкретному overlay:

```bash
# Применить конфигурацию для dev
kubectl apply -k k8s/overlays/dev/

# Применить конфигурацию для prod
kubectl apply -k k8s/overlays/prod/

# Предпросмотр без применения
kustomize build k8s/overlays/stg/
```

### Преимущества подхода Base + Overlay

Без overlays вам пришлось бы либо поддерживать три полностью отдельных набора YAML (дублирование и риск расхождений), либо вручную редактировать файлы при каждом деплое в новое окружение. Overlays решают эту проблему: базовая конфигурация живёт в одном месте, а различия описаны компактно в отдельных директориях.

---

## Часть 7. Components — переиспользуемая логика конфигураций

Components (компоненты) — продвинутая функция Kustomize для ситуаций, когда одна и та же необязательная функциональность нужна только в части overlay, но не во всех.

### Проблема, которую решают компоненты

Представьте приложение, которое деплоится в трёх вариантах:

- **dev** — разработческое окружение
- **premium** — расширенная версия для корпоративных клиентов
- **standalone** — самостоятельно развёртываемая версия

Приложение поддерживает две опциональные функции:

1. **Кэширование (Redis)** — нужно только для premium и standalone
2. **Внешняя база данных (Postgres)** — нужна только для dev и premium

Как поступить?

**Вариант 1: Поместить всё в base.**
Тогда кэширование будет включено и в dev, что нежелательно.

**Вариант 2: Скопировать конфигурацию кэширования в premium и standalone overlays.**
Тогда при изменении конфигурации Redis придётся обновлять её в двух местах. Это называется "дрейф конфигурации" (configuration drift) — опасная ситуация.

**Вариант 3: Компоненты Kustomize.**
Конфигурация кэширования описывается один раз в компоненте, и каждый нужный overlay просто импортирует его.

### Структура проекта с компонентами

```
k8s/
├── base/
│   ├── kustomization.yaml
│   └── api-depl.yaml
├── components/
│   ├── caching/
│   │   ├── kustomization.yaml
│   │   ├── deployment-patch.yaml
│   │   └── redis-depl.yaml
│   └── db/
│       ├── kustomization.yaml
│       ├── deployment-patch.yaml
│       └── postgres-depl.yaml
└── overlays/
    ├── dev/
    │   └── kustomization.yaml
    ├── premium/
    │   └── kustomization.yaml
    └── standalone/
        └── kustomization.yaml
```

### Реализация компонента: внешняя база данных (Postgres)

**`k8s/components/db/postgres-depl.yaml`** — Kubernetes Deployment для Postgres:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      component: postgres
  template:
    metadata:
      labels:
        component: postgres
    spec:
      containers:
        - name: postgres
          image: postgres
```

**`k8s/components/db/deployment-patch.yaml`** — патч для базового API-deployment, добавляющий переменную среды с паролем к БД:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-deployment
spec:
  template:
    spec:
      containers:
      - name: api
        env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-cred
              key: password
```

**`k8s/components/db/kustomization.yaml`** — ключевое отличие: `apiVersion` и `kind` не такие, как у обычного kustomization:

```yaml
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component

resources:
  - postgres-depl.yaml

secretGenerator:
  - name: postgres-cred
    literals:
      - password=postgres123

patches:
  - deployment-patch.yaml
```

`kind: Component` (а не `Kustomization`) сигнализирует Kustomize, что это переиспользуемый компонент, а не самостоятельная конфигурация. `apiVersion` тоже другой: `v1alpha1` вместо `v1beta1`.

Компонент делает три вещи:
1. Создаёт Deployment для Postgres
2. Создаёт Secret с паролем через `secretGenerator`
3. Применяет патч к базовому API-deployment, добавляя переменную среды

### Подключение компонента в overlay

**`k8s/overlays/dev/kustomization.yaml`** — dev использует и базу данных:

```yaml
bases:
  - ../../base

components:
  - ../../components/db
```

**`k8s/overlays/premium/kustomization.yaml`** — premium использует и базу данных, и кэш:

```yaml
bases:
  - ../../base

components:
  - ../../components/db
  - ../../components/caching
```

**`k8s/overlays/standalone/kustomization.yaml`** — standalone использует только кэш:

```yaml
bases:
  - ../../base

components:
  - ../../components/caching
```

### Матрица включения компонентов

| Окружение | База | Кэширование (Redis) | Внешняя БД (Postgres) |
|---|---|---|---|
| dev | ✅ | ❌ | ✅ |
| premium | ✅ | ✅ | ✅ |
| standalone | ✅ | ✅ | ❌ |

Каждый overlay управляет своим набором компонентов через поле `components:`. При изменении конфигурации Redis достаточно обновить один файл в `components/caching/` — все overlay, использующие этот компонент, автоматически получат обновление.

---

## Часть 8. Сравнительная таблица всех концепций

| Концепция | Назначение | Когда использовать |
|---|---|---|
| Common Transformers | Применить изменение ко всем ресурсам | Единые метки, namespace, префиксы для всего проекта |
| Image Transformer | Обновить образ контейнера | При обновлении версии приложения |
| JSON 6902 Patch | Точечное изменение через операции | Когда нужен строгий контроль операции |
| Strategic Merge Patch | Изменение через YAML-фрагмент | Когда важна читаемость |
| Overlays | Конфигурация под несколько окружений | dev/stg/prod с разными параметрами |
| Components | Переиспользуемые опциональные функции | Функциональность нужна только части overlay |

---

## Итоги и выводы

**Патчи** — это инструмент точечных изменений. JSON 6902 даёт явный контроль через операции `add`/`remove`/`replace` и числовые индексы для списков. Strategic Merge работает как обычный YAML и удобнее для людей. Оба метода можно писать inline или в отдельных файлах — выбор зависит от количества патчей и предпочтений команды.

**Overlays** решают главную проблему управления несколькими окружениями: вы описываете базовую конфигурацию один раз и добавляете только отличия для каждого окружения. Это устраняет дублирование и делает изменения предсказуемыми.

**Components** — следующий уровень переиспользования. Когда опциональная функциональность нужна только части overlay, компонент позволяет описать её единожды и подключать там, где требуется. Ключевое отличие от обычного kustomization — `kind: Component` и `apiVersion: kustomize.config.k8s.io/v1alpha1`.

Вместе эти три концепции формируют полноценную систему управления Kubernetes-конфигурациями: трансформеры для глобальных изменений, патчи для точечных, overlays для окружений, компоненты для переиспользуемых фич.