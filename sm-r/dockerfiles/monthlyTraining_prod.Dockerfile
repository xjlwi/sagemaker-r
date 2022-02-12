FROM rph-base-rdocker:dev

RUN apt-get update

RUN apt-get install -y\
    libpq-dev \
    libxml2

## Copy requirements.R to container directory /tmp
COPY .requirements.R /tmp/requirements.R

## install required libs on container
RUN Rscript /tmp/requirements.R

## Copy your working files over
COPY ./src /src
COPY ./dockerfiles /dockerfiles

## Define environment variables
ENV ENVIRONMENT_FLAG=$ENVIRONMENT_FLAG

# Run this script
ENTRYPOINT ["Rscript", "/sm/samples/main_monthly_crude_jetkero_gasoline95merged_prod.R"]