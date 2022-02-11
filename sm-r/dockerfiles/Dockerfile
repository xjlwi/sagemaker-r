# Base image https://hub.docker.com/u/rocker/
# Specify the version of R to use
FROM rocker/rstudio:4.0.5

RUN apt-get update

RUN apt-get install -y\
    libpq-dev \
    libxml2

## Copy requirements.R to container directory /tmp
COPY docker_config/requirements.R /tmp/requirements.R  

## install required libs on container
RUN Rscript /tmp/requirements.R

## Copy your working files over
COPY /raphael /raphael
COPY /docker_config /docker_config

## ENV
# ENV SAGEMAKER PROGRAM /raphael/modelling/crude/monthly/main_modelling_monthly_crude.R
# ENTRYPOINT ["Rscript", "/raphael/modelling/crude/monthly/main_modelling_monthly_crude.R" ]
# ENTRYPOINT ["Rscript", "/raphael/modelling/crude/monthly/main_modelling_monthly_crude_forecast.R" ]
RUN chmod +x /raphael/main_inference.sh
ENTRYPOINT [ "/raphael/main_inference.sh" ]
