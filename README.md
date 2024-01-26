# Studying Docker (and trying to deploy a PHP project)

I decided to deploy an existing PHP website into a new hosting service with Docker.

Using the image php:7.4-apache.

It's a legacy website, not a Laravel project.

## The problem:

This website depends on the ".htaccess" file to routing, and I still haven't success to activate the .htaccess file in the Apache... 


## Starting this repo to find a solution

I started this repo to do another test, and below are the commands I ran on Linux terminal.

I created this folder:
- mkdir docker-php-apache

Open VSCode to create the files:
- code docker-php-apache

Enter the folder:
- cd docker-php-apache


## docker-compose.yml

I created a docker-compose file containing only one service (called "website-testing") with the image "php:7.4-apache" and with a volume setting the root path of the web server to the "website" folder, where I put some PHP files and a .htaccess for testing.

And I used the default port 80, mapped to the internal (inside the container) port 8001, which PHP server will be running and listening to.

<pre>
services:
    website-testing:
        build:
            dockerfile: Dockerfile
            context: .
        image: php:7.4-apache
        working_dir: /var/www/html
        volumes:
            - './website/:/var/www/html'
        ports:
            - '80:8001'
        command: "php -S 0.0.0.0:8001"
</pre>


## Dockerfile

I created a very simple Dockerfile for testing, here I'll put more lines later...

<pre>
FROM php:7.4-apache
WORKDIR /var/www/html
</pre>


# Creating the folder with a PHP file

Creating the folder where I put PHP and htaccess files:
- mkdir website

I created this "helloworld.php" file:
<pre>
<?php
    echo "<h2>Hello world...</h2>";
?>
</pre>

And I created this ".htaccess" file:
<pre>
RewriteEngine on

# testing this route: http://localhost/hellodocker
RewriteRule ^(hellodocker)$ helloworld.php
</pre>


# Docker in action...

To run the container and testing the container, run these commands:

To create the container's image:
- docker compose build

To run the container:
- docker compose up -d

This command you can see the container running:
- docker ps

Now, you can test the webserver clicking
- http://localhost/helloworld.php

The browser should show:
- Hello world...


BUT the problem I'm having is when I try to use the ".htaccess" with this route
- http://localhost/hellodocker/

Then I got "404 Not found" error:
- The requested resource /hellodocker was not found on this server.


Another test is to open the ".htaccess" file in the browser
- http://localhost/.htaccess

I think it's not suppose to happen, because of a configuration inside the "apache2.conf" file.
<pre>
#
# The following lines prevent .htaccess and .htpasswd files from being
# viewed by Web clients.
#
< FilesMatch "^\.ht" >
	Require all denied
</ FilesMatch >
</pre>


Now I'll stop the container and start the configuration (to try) to activate the ".htaccess" file:
- docker compose down


# Enabling "mod rewrite" on Apache

On Dockerfile, I inserted this line:
- RUN a2enmod rewrite

To test if it works, delete the image and build it again


## Cleaning Docker before a new buid

Stop the container:
- docker compose down

Listing the images:
- docker image ls

Deleting the image "php:7.4-apache"
- docker rmi php:7.4-apache

## Building the image again 

Run again this command to build the image:
- docker compose build

This time, this line should appear on terminal:
<pre>
=> [website-testing 3/3] RUN a2enmod rewrite
</pre>

And now to start the container:
- docker compose up -d

Testing again:
- http://localhost/hellodocker

And the same error "404 Not found":
- The requested resource /hellodocker was not found on this server.

Even the "helloworld.php" is OK:
- http://localhost/helloworld.php


# Getting a copy of the configuration files

Now I started to dive in Apache configuration and Docker containers...

I ran these commands to export/get a copy of each file from the container, and then I changed the required configuration, and I used the Dockerfile to send them back to the container with COPY lines.

## php.ini

docker run php:7.4-apache cat /usr/local/etc/php/php.ini-production > testing-php.ini

For example, in php.ini I changed... ?


## apache2.conf

docker run php:7.4-apache cat /etc/apache2/apache2.conf > testing-apache2.conf

In this file I changed "AllowOverride None" to "AllowOverride All"

And I also tried defining:
- ServerName localhost

...

## 000-default.conf

docker run php:7.4-apache cat /etc/apache2/sites-available/000-default.conf > testing-default.conf

Inside this "testing-default.conf" I put this block inside the "VirtualHost" tag
<pre>
< VirtualHost >
   ...
    < Directory /var/www/html/>
        AllowOverride All
		Require all granted
    </ Directory >
< /VirtualHost >
</pre>

I didn't understand what should be the correct configuration on the Directory tag
- Directory /var/www/html/ (I saw on internet)
- or
- Directory /var/www/ (apache2.conf)



## Copying files to the container

Inside the Dockerfile, now I defined the COPY lines that will copy the configuration files back to the container, after it is running:

- COPY testing-php.ini /usr/local/etc/php/php.ini
- COPY testing-apache2.conf /etc/apache2/apache2.conf
- COPY testing-default.conf /etc/apache2/sites-available/localhost.conf
- RUN a2ensite localhost.conf

I'm trying to turn the "localhost" server available, and then the command "a2ensite" turn it enabled.

I saw an example of these commandos on this Youtube video:
- https://www.youtube.com/watch?v=53YEs0VUw9A


# Testing Again

Down
- docker compose down

Delete container image
- docker rmi php:7.4-apache

Build a new image
- docker compose build

Up the server and application
- docker compose up -d

Trying again:
- http://localhost/hellodocker

Nothing:
- The requested resource /hellodocker was not found on this server.


## Inside a Docker container

Listing the containers running:
- docker ps

The results should looks like this:
<pre>
CONTAINER ID   IMAGE            COMMAND                  CREATED         STATUS         PORTS                          NAMES
123456789x   php:7.4-apache   "docker-php-entrypoi…"   4 minutes ago   Up 4 minutes   80/tcp, 0.0.0.0:80->8001/tcp   docker-php-apache-website-testing-1
</pre>

This is the name of the container: docker-php-apache-website-testing-1

You can have more than 1 container running based on the same image, Docker it's awesome...

This command, you can "enter" the container with a terminal (bash):
- docker exec -ti docker-php-apache-website-testing-1 bash

You will be in the "/var/www/html" folder:
<pre>
root@123456789x:/var/www/html#
</pre>

If you run a "ls -la" command, you will see the files inside the "website" folder, which is mapped as a volume on the docker-compose file:
<pre>
root@123456789x:/var/www/html# ls -la
total 20
drwxr-xr-x 2 1000 1000 4096 Jan 26 13:10 .
drwxr-xr-x 1 root root 4096 Nov 15  2022 ..
-rw-r--r-- 1 1000 1000  198 Jan 26 13:10 .htaccess
-rw-r--r-- 1 1000 1000   35 Jan 26 13:31 helloworld.php
</pre>

I also tried change the owner of the ".htaccess" file to root:
<pre>
chown root:root .htaccess
</pre>

And listing again:
<pre>
root@123456789x:/var/www/html# ls -la
total 20
drwxr-xr-x 2 1000 1000 4096 Jan 26 13:10 .
drwxr-xr-x 1 root root 4096 Nov 15  2022 ..
-rw-r--r-- 1 root root  198 Jan 26 13:10 .htaccess
-rw-r--r-- 1 1000 1000   35 Jan 26 13:31 helloworld.php
</pre>

THe web server is OK:
- http://localhost/helloworld.php
- Hello world...

BUT the ".htaccess" isn't working, and remains the same "404 Not found"
- http://localhost/hellodocker
- The requested resource /hellodocker was not found on this server.

Leaving the container:
- exit


# Sharing this test on Github


git init

git branch -M main

git remote add origin git@github.com:cybervoigt/docker-php-apache.git

git add .

git commit -m "First commit...";

git push
