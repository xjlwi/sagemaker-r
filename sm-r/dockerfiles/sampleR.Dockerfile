FROM rph-base-rdocker:dev

RUN apt-get update

RUN apt-get install -y\
    libpq-dev \
    libxml2

## Copy requirements.R to container directory /tmp
COPY ./sm-r/requirements.R /tmp/requirements.R

## install required libs on container
RUN Rscript /tmp/requirements.R

## Copy your working files over into docker image
COPY ./sm-r/src /src
COPY ./sm-r/dockerfiles /dockerfiles

## Define environment variables
ENV ENVIRONMENT_FLAG=$ENVIRONMENT_FLAG

## Run this script
ENTRYPOINT ["Rscript", "/src/sm/samples/main_monthly_model.R"]