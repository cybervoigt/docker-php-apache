FROM php:7.4-apache
WORKDIR /var/www/html
RUN a2enmod rewrite
COPY testing-php.ini /usr/local/etc/php/php.ini
COPY testing-apache2.conf /etc/apache2/apache2.conf
COPY testing-default.conf /etc/apache2/sites-available/localhost.conf
RUN a2ensite localhost.conf
