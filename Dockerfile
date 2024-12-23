FROM python:3.10-alpine AS builder

WORKDIR /usr/ecommerce/backend

RUN apk add --no-cache \
        build-base \
        postgresql-dev \
        bash \
        libpq

COPY requirements/base.txt /usr/ecommerce/backend/requirements/base.txt
RUN pip install -r requirements/base.txt


FROM python:3.10-alpine

WORKDIR /usr/ecommerce/backend

RUN adduser --disabled-password ecommerce \
    && apk add --no-cache \
        bash \
        libpq \
    && rm -rf /var/cache/apk/*

COPY --from=builder /usr/local/lib/python3.10 /usr/local/lib/python3.10
COPY --from=builder /usr/local/bin /usr/local/bin
COPY . /usr/ecommerce/backend

RUN chmod +x ./entrypoints.sh

USER ecommerce
EXPOSE ${WEB_PORT}

ENTRYPOINT ["./entrypoints.sh"]