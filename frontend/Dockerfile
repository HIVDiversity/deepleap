from zauberzeug/nicegui:3.8.0


WORKDIR /app

COPY . /app

RUN uv pip install .

EXPOSE 8080

cmd ["python", "frontend/main.py", "run"]
