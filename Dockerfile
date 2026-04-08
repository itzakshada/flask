FROM python:3.10-slim
WORKDIR /app

COPY . /app

RUN pip install --no-cache-dir -U pip build \
 && python -m build --wheel \
 && pip install --no-cache-dir dist/*.whl

CMD ["python", "-c", "from importlib.metadata import version; print('Flask installed:', version('flask'))"]
