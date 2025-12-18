#!/bin/bash
    apt update
    apt upgrade
    apt install -y apache2 php php-mysql unzip
    systemctl enable apache2
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install

    rm /var/html/www/index.php
    cd /var/html/www
    wget 

