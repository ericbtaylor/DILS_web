# syntax=docker/dockerfile:1
FROM ubuntu:18.04
WORKDIR /app

ADD wrappers/* /usr/bin/
ADD DILS/ /tools/
ADD webinterface /tools/webinterface/



SHELL ["/bin/bash", "-c"]
RUN apt-get update && \
    apt-get install -y git gcc wget vim make && \
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
    conda create -n pypy  pypy3.6 && \
    conda install -n pypy numpy

RUN . /tools/miniconda/etc/profile.d/conda.sh && \
    conda create -n snakemake python=3.5 && \
    conda run -n snakemake pip install snakemake==5.3.0 && \
    conda create -n latex -c conda-forge texlive-core && \
    conda create -n R -c conda-forge r=3.6.0

RUN . /tools/miniconda/etc/profile.d/conda.sh && \
    conda install -n R -c conda-forge r-shiny=1.4.0 'r-usethis>=2.0.1' r-shinycssloaders \
    r-shinythemes \
    r-shinydashboard \
    r-shinydashboardplus \
    r-shinyjs \
    r-dt \
    r-shinywidgets \
    r-devtools \
    r-shinyhelper \
    r-tidyr \
    r-rcolorbrewer \
    r-factominer \
    r-ggplot2=3.2.1 \
    r-ggpubr \
    r-plotly \
    r-viridis \
    r-ranger \
    r-rcpparmadillo && \
    conda install -n R -c r r-yaml && \
    Rscript -e 'library(devtools); install_github("nik01010/dashboardthemes")' && \
    conda install -n R -c r r-data.table && \
    conda install -n R -c r r-nnet && \
    conda install -n R r-tidyverse && \
    conda install -n R -c bioconda r-matrixstats && \
    Rscript -e "install.packages('abcrf', repos='https://cloud.r-project.org/')"


#	git clone https://github.com/popgenomics/DILS_web.git
RUN chmod 755 /tools/bin/* && \
 	cd /tools/msnsam && \
 	./clms

#	export DEBIAN_FRONTEND=noninteractive	#pour empecher les interactions avec le terminal (demande de pays avec tzdata...)
#	apt-get install -y tzdata

ENV PATH=$PATH:/tools:/tools/bin:/tools/miniconda/bin:/tools/miniconda/condabin
