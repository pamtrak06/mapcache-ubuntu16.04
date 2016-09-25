FROM pamtrak06/ubuntu16.04-apache2-python

MAINTAINER pamtrak06 <pamtrak06@gmail.com>

# Install mapcache compilation prerequisites
RUN apt-get update && apt-get install -y software-properties-common g++ make cmake

# Install mapcache dependencies provided by Ubuntu repositories
RUN apt-get install -y git \
    libaprutil1-dev \
    libapr1-dev \
    libpng12-dev \
    libjpeg-dev \
    libcurl4-gnutls-dev \
    libpcre3-dev \
    libpixman-1-dev \
    libgdal-dev \
    libgeos-dev \
    libsqlite3-dev \
    libdb-dev \
    libtiff-dev

# Install Mapcache itself
RUN git clone https://github.com/mapserver/mapcache/ /usr/local/src/mapcache

# Compile Mapcache for Apache
RUN mkdir /usr/local/src/mapcache/build && \
    cd /usr/local/src/mapcache/build && \
    cmake ../ \
    -DWITH_FCGI=0 -DWITH_APACHE=1 -DWITH_PCRE=1 \
    -DWITH_TIFF=1 -DWITH_BERKELEY_DB=1 -DWITH_MEMCACHE=1 \
    -DCMAKE_PREFIX_PATH="/etc/apache2" && \
    make && \
    make install

# Force buit libraries dependencies
RUN ldconfig

# Apache configuration for mapcache
COPY mapcache.load /etc/apache2/mods-available/
COPY mapcache.conf /etc/apache2/mods-available/

# Download scripts to build mapcache.xml from a wms url
COPY mapcache.py /etc/apache2/conf-available/
COPY mapcache-run.sh /etc/apache2/conf-available/

# Enable mapcache module in Apache
RUN a2enmod mapcache

# Create temp directory for mapcache tiles
RUN if [ ! -d /tmp/mapcache ]; then mkdir /tmp/mapcache; fi
RUN chmod 755 /tmp/mapcache

# Volumes
VOLUME ["/var/www", "/var/log/apache2", "/etc/apache2"]

# Expose ports 80/443... : to be override for needs

# Define default command
CMD ["apachectl", "-D", "FOREGROUND"]
