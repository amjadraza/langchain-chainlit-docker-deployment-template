# The builder image, used to build the virtual environment
FROM python:3.11-slim-buster as builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y git

RUN groupadd -g 1001 appgroup && \
    adduser --uid 1001 --gid 1001 --disabled-password --gecos '' appuser

USER 1001

RUN pip install --user --no-cache-dir --upgrade pip && \
    pip install --user --no-cache-dir poetry==1.4.2

ENV PATH="/home/appuser/.local/bin:${PATH}" \
    POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=1 \
    POETRY_VIRTUALENVS_CREATE=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache \
    HOST=0.0.0.0 \
    LISTEN_PORT=8000

EXPOSE 8000

WORKDIR /app

COPY pyproject.toml poetry.lock /app/

RUN poetry install --without dev --no-cache --no-root && \
    rm -rf $POETRY_CACHE_DIR

# The runtime image, used to just run the code provided its virtual environment
FROM python:3.11-slim-buster as runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y git

RUN groupadd -g 1001 appgroup && \
    adduser --uid 1001 --gid 1001 --disabled-password --gecos '' appuser

USER 1001

ENV VIRTUAL_ENV=/app/.venv \
    PATH="/app/.venv/bin:/home/appuser/.local/bin$PATH"
    POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=1 \
    POETRY_VIRTUALENVS_CREATE=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache \
    HOST=0.0.0.0 \
    LISTEN_PORT=8000

EXPOSE 8000

WORKDIR /app

COPY --from=builder ${VIRTUAL_ENV} ${VIRTUAL_ENV}

COPY ./demo_app /app/demo_app
COPY ./.chainlit /app/.chainlit
COPY chainlit.md /app/

CMD ["chainlit", "run", "demo_app/main.py"]
