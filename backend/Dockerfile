FROM tiangolo/uvicorn-gunicorn:python3.11

RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y curl
RUN apt-get install unzip
RUN apt-get -y install python3
RUN apt-get update && apt-get -y install python3-pip
RUN apt-get -y install git
RUN pip install ffmpeg

COPY ./requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

RUN apt-get install -y libopus0 libopus-dev

COPY . /app
RUN rm -rf /app/.env /app/.env.dev /app/docker-compose.yml /app/docker-compose-dev.yml

EXPOSE 8080
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]