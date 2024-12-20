FROM python:3.10-alpine

WORKDIR /usr/ecommerce/backend

RUN adduser --disabled-password ecommerce \
    && apk add --no-cache \
        build-base \
        postgresql-dev \
        bash \
    && rm -rf /var/cache/apk/*

COPY requirements/base.txt /usr/ecommerce/backend/requirements/base.txt
RUN pip install --no-cache-dir -r requirements/base.txt \
    && rm -rf /root/.cache/pip
COPY . /usr/ecommerce/backend

RUN chmod +x ./entrypoints.sh

EXPOSE ${WEB_PORT}
USER ecommerce

ENTRYPOINT ["./entrypoints.sh"]