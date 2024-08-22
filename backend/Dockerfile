FROM tiangolo/uvicorn-gunicorn:python3.11

RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y curl
RUN apt-get install unzip
RUN apt-get -y install python3
RUN apt-get -y install python3-pip
RUN apt-get -y install git
RUN apt-get -y install ffmpeg

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

COPY . /app
# TODO: tiangolo/uvicorn-gunicorn:python3.11 sets the working directory at /app, so docker commands
# runs at there. at local dev environment, working directory is at the backend folder.
COPY credentials.json .

EXPOSE 8080
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]