FROM php:8.5-apache-trixie

# Base OS tools
RUN apt-get update && apt-get install -y \
        ca-certificates \
        curl \
        wget \
        gnupg \
        git \
        zip \
        unzip \
        jq \
        nano \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Python3 => Python
RUN apt-get update && apt-get install -y python3 python3-virtualenv python-is-python3 \
    && rm -rf /var/lib/apt/lists/*

# Node 24
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get update && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Yarn
RUN corepack enable \
    && corepack prepare yarn@1.22.22 --activate

# Gitlab-Runner
RUN curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | bash \
    && apt-get update && apt-get install -y gitlab-runner \
    && rm -rf /var/lib/apt/lists/*

# PHP extension build dependencies
RUN apt-get update && apt-get install -y \
        zlib1g-dev \
        libzip-dev \
        libgmp-dev \
        libxml2-dev \
        libxslt1-dev \
        libicu-dev \
        libwebp-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libfreetype6-dev \
        g++ \
    && rm -rf /var/lib/apt/lists/*

# Exif - PHP
RUN docker-php-ext-configure exif --enable-exif \
    && docker-php-ext-install exif

# GD - PHP
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install gd

# APCu (Gestionnaire de cache) - PHP
RUN pecl install apcu \
    && docker-php-ext-enable apcu

# Mysql - PHP
RUN docker-php-ext-install -j"$(nproc)" pdo_mysql

# Lib des entiers, des nombres rationnels et des nombres à virgule flottante de précision arbitraire
RUN docker-php-ext-install -j"$(nproc)" gmp

# SOAP, ZIP, XSL, INTL - PHP
RUN docker-php-ext-install soap zip xsl intl

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

# WeasyPrint
# https://doc.courtbouillon.org/weasyprint/stable/first_steps.html#debian-11
RUN apt-get update \
    && apt-get install -y weasyprint \
    && rm -rf /var/lib/apt/lists/*

# Libreoffice
# libreoffice-writer        nécessaire pour DOC/DOCX/ODT
# libreoffice-java-common   utile pour certaines fonctions LibreOffice, macros, filtres ou documents complexes
# fonts-dejavu              polices de base
# fonts-liberation          équivalents Arial / Times New Roman / Courier New
RUN apt-get update \
    && apt-get install -y \
        libreoffice-writer \
        libreoffice-java-common \
        fonts-dejavu \
        fonts-liberation \
    && rm -rf /var/lib/apt/lists/*

# XDebug
RUN pecl install xdebug \
    && docker-php-ext-enable xdebug

# xdebug_state
COPY xdebug_state.sh /usr/bin/xdebug_state
RUN chmod +x /usr/bin/xdebug_state
ENV xdebugRemoteMachine=${xdebugRemoteMachine:-""}
ENV userPrefixPort=${userPrefixPort:-""}

# Symfony CLI
RUN curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | bash
RUN apt-get update \
    && apt-get install -y symfony-cli \
    && rm -rf /var/lib/apt/lists/*

# AWS eb-cli
RUN git clone https://github.com/aws/aws-elastic-beanstalk-cli-setup.git \
    && python ./aws-elastic-beanstalk-cli-setup/scripts/ebcli_installer.py
ENV PATH="/root/.ebcli-virtual-env/executables:$PATH"

# AWS cli
RUN curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf aws awscliv2.zip

# Geckodriver
ENV GECKODRIVER_VERSION=0.36.0
RUN curl -fsSL \
        "https://github.com/mozilla/geckodriver/releases/download/v${GECKODRIVER_VERSION}/geckodriver-v${GECKODRIVER_VERSION}-linux64.tar.gz" \
        -o /tmp/geckodriver.tar.gz \
    && tar -xzf /tmp/geckodriver.tar.gz -C /usr/local/bin \
    && chmod +x /usr/local/bin/geckodriver \
    && rm /tmp/geckodriver.tar.gz

# Navigateur Firefox
RUN apt-get update \
    && apt-get install -y firefox-esr \
    && rm -rf /var/lib/apt/lists/*

## PHPUnit
RUN wget -O phpunit https://phar.phpunit.de/phpunit-13.phar \
    && chmod +x phpunit \
    && mv phpunit /usr/local/bin/phpunit

# Creation dossier sessions
RUN mkdir -p /var/lib/php/sessions && chown -R www-data.www-data /var/lib/php/sessions
# Creation dossier symfony
RUN mkdir -p /tmp/symfony && chown -R www-data.www-data /tmp/symfony

RUN a2enmod rewrite

RUN sed -i "s/DocumentRoot .*/DocumentRoot \/var\/www\/html\/public/" /etc/apache2/sites-available/000-default.conf
