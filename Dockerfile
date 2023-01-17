# syntax=docker/dockerfile:1
FROM ubuntu:18.04
WORKDIR /app

SHELL ["/bin/bash", "-c"]
RUN apt-get update && \
    apt-get install -y git gcc wget vim make && \
    mkdir -p /tools/bin && \
    cd /tools && \
    wget https://repo.anaconda.com/miniconda/Miniconda2-latest-Linux-x86_64.sh && \
    bash Miniconda2-latest-Linux-x86_64.sh -b -p /tools/miniconda -u && \
    . /tools/miniconda/etc/profile.d/conda.sh && \
    rm Miniconda2-latest-Linux-x86_64.sh && \
    : fixme clean apt-cache folder

RUN . /tools/miniconda/etc/profile.d/conda.sh && \
    conda activate && \
    conda config --add channels conda-forge && \
    conda config --add channels bioconda && \
    conda config --set channel_priority flexible && \
    : && \
    conda create -n pypy pypy3.6 && \
    conda install -n pypy numpy

RUN . /tools/miniconda/etc/profile.d/conda.sh && \
    conda create -n snakemake python=3.5 && \
    conda run -n snakemake pip install snakemake==5.3.0 && \
    conda create -n latex -c conda-forge texlive-core && \
    conda create -n R -c conda-forge r=3.6.0

RUN . /tools/miniconda/etc/profile.d/conda.sh && \
    conda install -n R -c conda-forge \
    r-shiny=1.4.0 \
    'r-usethis>=2.0.1' \
    r-shinycssloaders= \
    r-shinythemes=1.1.2 \
    r-shinydashboard=0.7.1 \
    r-shinydashboardplus=0.7.0 \
    r-shinyjs=1.1 \
    r-dt=0.13 \
    r-shinywidgets=0.5.3 \
    r-devtools=2.3.0 \
    r-shinyhelper=0.3.2 \
    r-tidyr=1.1.0 \
    r-rcolorbrewer=1.1.2 \
    r-factominer=2.3 \
    r-ggplot2=3.2.1 \
    r-ggpubr=0.3.0 \
    r-plotly=4.9.2.1 \
    r-viridis=0.5.1 \
    r-ranger=0.12.1 \
    r-rcpparmadillo=0.9.900.1.0 && \
    conda install -n R -c r \
    r-yaml=2.2.0 \
    r-data.table=1.12.2 \
    r-nnet=7.3.12 \
    r-tidyverse=1.3.0 && \
    conda install -n R -c bioconda r-matrixstats=0.56.0

# Copy repo scripts and wrappers
ADD wrappers/* /usr/bin/
ADD DILS/ /tools/
ADD webinterface /tools/webinterface/

# Finalize installs of misc repos
RUN Rscript -e 'library(devtools); install_github("nik01010/dashboardthemes")' && \
    Rscript -e "install.packages('abcrf', repos='https://cloud.r-project.org/')" && \
    apt-get install -y python-pip && pip install PyYAML `: this one is for the entrypoint` && \
    chmod 755 /tools/bin/* && \
 	cd /tools/msnsam && \
 	./clms

#	export DEBIAN_FRONTEND=noninteractive	#pour empecher les interactions avec le terminal (demande de pays avec tzdata...)
#	apt-get install -y tzdata

ENV PATH=$PATH:/tools:/tools/bin:/tools/miniconda/bin:/tools/miniconda/condabin

ENTRYPOINT ["/tools/bin/entrypoint.sh"]
