FROM python:3.8-slim-buster

RUN apt-get update

RUN apt-get -y install\
    libpq-dev\
    gcc

## Copy requirements.txt to container directory /tmp
COPY ./docker_config/requirement.txt /requirement.txt

## install required libs on container
RUN pip install -r requirement.txt

## Copy your working files over
COPY ./raphael /raphael
COPY ./docker_config /docker_config

## Define environment variables
ENV AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
ENV AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
ENV AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION
ENV AWS_SECRETS_ARN=$AWS_SECRETS_ARN
ENV ENVIRONMENT_FLAG=$ENVIRONMENT_FLAG

#set python path
ENV PYTHONPATH /raphael

# Run this script
CMD ["python", "raphael/feature_engineering/partial_fe/main_monthly_data_loading.py"]