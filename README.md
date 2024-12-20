# Docker: докеризация приложения
Цель лабораторной: собрать из исходного когда и запустить в докере рабочее приложение с базой данных (любое опенсорс - Java, python/django/flask, golang).

Задание
--------
1. Образ должен быть легковесным
2. Использовать базовые легковестные образы - alpine
3. Вся конфигурация приложения должна быть через переменные окружения
4. Статика (зависимости) должна быть внешним томом `volume`
5. Создать файл `docker-compose` для старта и сборки
6. В `docker-compose` нужно использовать базу данных (postgresql,mysql,mongodb etc.)
7. При старте приложения должно быть учтено выполнение автоматических миграций
8. Контейнер должен запускаться от непривилегированного пользователя
9. После установки всех нужных утилит, должен очищаться кеш


## Инструкция по настройке

### Сборка и запуск контейнеров

1. Клонируйте репозиторий:
   ```bash
   git clone <url-репозитория>
   cd <папка-репозитория>
   ```
2.	Соберите и запустите контейнеры:
   ```bash
   docker-compose up
   ```
3.	Проверьте, что сервисы запущены. Backend доступен по адресу: http://localhost:8000

### Описание Dockerfile

```dockerfile
FROM python:3.10-alpine
```
 Устанавливает базовый образ для создания контейнера.
```dockerfile
WORKDIR /usr/ecommerce/backend
```


Устанавливает рабочую директорию внутри контейнера.

```dockerfile
RUN adduser --disabled-password ecommerce \
    && apk add --no-cache \
        build-base \
        postgresql-dev \
        bash \
    && rm -rf /var/cache/apk/*
```
Команда `adduser --disabled-password ecommerce` cоздаёт пользователя ecommerce без пароля.

Далее происходит установка необходимых пакетов:\
`build-base`: Набор инструментов для компиляции Python-зависимостей.\
`postgresql-dev`: Библиотеки и заголовочные файлы для взаимодействия с PostgreSQL. \
`bash`: Устанавливается для выполнения скриптов.

`rm -rf /var/cache/apk/*` удаляет временные файлы, чтобы уменьшить размер итогового образа.

```dockerfile
COPY requirements/base.txt /usr/ecommerce/backend/requirements/base.txt
```

Копирует файл base.txt с зависимостями Python в контейнер.

```dockerfile
RUN pip install --no-cache-dir -r requirements/base.txt \
    && rm -rf /root/.cache/pip
COPY . /usr/ecommerce/backend
```

`pip install --no-cache-dir -r requirements/base.txt` устанавливает зависимости Python, указанные в base.txt. `--no-cache-dir` предотвращает сохранение временных файлов, что уменьшает размер образа.\
`rm -rf /root/.cache/pip` удаляет оставшиеся временные файлы pip.\
COPY копирует весь проект в рабочую директорию контейнера.

```dockerfile
RUN chmod +x ./entrypoints.sh
```

Изменяет права доступа для файла entrypoints.sh, чтобы он стал исполняемым.

```dockerfile
EXPOSE ${WEB_PORT}
USER ecommerce
```

EXPOSE документирует, что контейнер будет использовать порт, указанный в переменной WEB_PORT.\
USER устанавливает пользователя, от имени которого будет выполняться контейнер.

```dockerfile
ENTRYPOINT ["./entrypoints.sh"]
```

Указывает команду, которая будет выполняться при запуске контейнера.

### Описание entrypoints.sh

```shell
./wait-for-it.sh db:5432 --timeout=30 --strict -- echo "Database is up"

python manage.py migrate --settings=src.settings.local-docker

python manage.py loaddata products/fixture.json --settings=src.settings.local-docker

exec python manage.py runserver 0.0.0.0:8000 --settings=src.settings.local-docker
```

1.	Ожидает, пока база данных не станет доступной.
2.	Применяет миграции для синхронизации базы данных с моделями Django.
3.	Загружает начальные данные в базу данных.
4.	Запускает веб-сервер Django для обработки запросов.

### Описание docker-compose.yml
```yml
version: '3.9'

services:
  db:
    image: postgres:17-alpine
    container_name: pg_db_1
    environment:
      POSTGRES_DB: pg_db_docker
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: admin
    ports:
      - "5432:5432"
    volumes:
      - db_data:/var/lib/postgresql/data

  web:
    build:
      context: .
      dockerfile: Dockerfile
    environment:
      POSTGRES_DB: pg_db_docker
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: admin
      DATABASE_HOST: db
      DB_PORT: 5432

      DJANGO_SETTINGS_MODULE: src.settings.local-docker
    volumes:
      - .:/usr/src/app
      - static_data:/usr/ecommerce/backend/scr/static
      - media_data:/usr/ecommerce/backend/src/media
    ports:
      - "8000:8000"
    depends_on:
      - db

volumes:
  db_data:
  static_data:
  media_data:
```

#### db
`image: postgres:17-alpine`  задает Docker-образ для контейнера базы данных. Используется официальный образ PostgreSQL версии 17 на базе Alpine Linux, что делает его легковесным.

`environment` Устанавливает переменные окружения для настройки базы данных:
1. POSTGRES_DB: Имя базы данных, которая будет создана при запуске контейнера.
2. POSTGRES_USER: Имя пользователя для подключения к базе данных.
3. POSTGRES_PASSWORD: Пароль для пользователя.

`ports` `"5432:5432"` это проброс порта 5432 из контейнера на тот же порт хоста.

`volumes` монтирует том для хранения данных базы данных.

#### web

`build` указывает, что контейнер для веб-приложения будет собираться на основе Dockerfile, который находится в текущей директории.

`environment` устанавливает переменные окружения для веб-приложения. 
1. POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD: Эти параметры передаются веб-приложению для подключения к базе данных.
2. DATABASE_HOST: Указывает хост базы данных как db — это имя сервиса базы данных в Docker Compose, что позволяет контейнерам общаться друг с другом.
3. DB_PORT: Указывает порт, на котором работает база данных.
4. DJANGO_SETTINGS_MODULE: Указывает на настройки Django, которые нужно использовать для запуска в Docker.

`depends_on` указывает, что сервис web зависит от сервиса db и будет запускаться только после того, как контейнер с базой данных будет готов.

#### volumes
Определяет тома, которые используются для хранения данных.
