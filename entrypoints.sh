#!/bin/bash

./wait-for-it.sh db:5432 --timeout=30 --strict -- echo "Database is up"

python manage.py migrate --settings=src.settings.local-docker

python manage.py loaddata products/fixture.json --settings=src.settings.local-docker

exec python manage.py runserver 0.0.0.0:8000 --settings=src.settings.local-docker