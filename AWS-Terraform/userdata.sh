#!/bin/bash
    apt update
    apt upgrade
    apt install -y apache2 php php-mysql unzip php-curls
    
    
    systemctl enable apache2
    systemctl restart apache2
    
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install

    rm /var/www/html/index.html
    cd /var/html/www
    wget https://raw.githubusercontent.com/Vic-Winderix/AWS/refs/heads/main/AWS-Terraform/index.php

    cd /var/www/html
    curl -sS https://getcomposer.org/installer | php
    wget https://raw.githubusercontent.com/Vic-Winderix/AWS/refs/heads/main/AWS-Terraform/composer.json
    php composer.phar install

