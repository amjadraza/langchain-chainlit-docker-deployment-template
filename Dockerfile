# The builder image, used to build the virtual environment
FROM python:3.11-slim-buster as builder

# Environment setup for build
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/home/appuser/.local/bin:${PATH}" \
    POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=1 \
    POETRY_VIRTUALENVS_CREATE=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache

RUN apt-get update && apt-get install -y git

RUN groupadd -g 1001 appgroup && \
    adduser --uid 1001 --gid 1001 --disabled-password --gecos '' appuser

USER 1001

RUN pip install --user --no-cache-dir --upgrade pip && \
    pip install --user --no-cache-dir poetry

WORKDIR /home/appuser/app/
COPY pyproject.toml poetry.lock /home/appuser/app/
RUN poetry install --no-cache --no-root && \
    rm -rf $POETRY_CACHE_DIR

# The runtime image, used to just run the code provided its virtual environment
FROM python:3.11-slim-buster as runtime

# Environment setup for runtime
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    VIRTUAL_ENV=/home/appuser/app/.venv \
    PATH="/home/appuser/app/.venv/bin:/home/appuser/.local/bin:$PATH" \
    HOST=0.0.0.0 \
    LISTEN_PORT=8000

RUN groupadd -g 1001 appgroup && \
    adduser --uid 1001 --gid 1001 --disabled-password --gecos '' appuser

USER 1001
EXPOSE 8000
WORKDIR /home/appuser/app/

# Copy virtual environment from builder
COPY --chown=appuser:appuser --from=builder ${VIRTUAL_ENV} ${VIRTUAL_ENV}

# Copy application files
COPY ./chainlit.md /home/appuser/app/chainlit.md
COPY --chown=appuser:appuser ./.chainlit /home/appuser/app/.chainlit
COPY ./demo_app /home/appuser/app/demo_app

CMD ["chainlit", "run", "/home/appuser/app/demo_app/main.py"]
