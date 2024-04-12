FROM python:3.11
WORKDIR /service
COPY ./requirements.txt /service/requirements.txt
RUN apt-get update && apt-get -y install libgl1-mesa-glx
RUN pip install --no-cache-dir --upgrade -r /service/requirements.txt
COPY ./app /service/app
EXPOSE 1000
CMD ["uvicorn", "app.main:app", "--proxy-headers", "--host", "0.0.0.0", "--port", "1000"]
