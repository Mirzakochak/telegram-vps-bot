#!/bin/bash

echo "📦 Telegram VPS Bot Auto Installer via GitHub"
echo "---------------------------------------------"

read -p "🔑 Enter your Telegram Bot Token: " TOKEN
read -p "🗄️  Enter MySQL Database Name: " DBNAME
read -p "👤 Enter MySQL Username: " DBUSER
read -s -p "🔒 Enter MySQL Password: " DBPASS
echo
read -p "🌐 Enter your domain (e.g. example.com): " DOMAIN
read -p "💳 Enter your NextPay API Key: " NEXTKEY

echo "📥 Installing dependencies..."
sudo apt update
sudo apt install -y apache2 php php-mysqli php-curl unzip curl

echo "📦 Downloading bot files..."
cd /tmp
curl -LO https://github.com/Mirzakochak/telegram-vps-bot/raw/refs/heads/main/telegram-vps-bot.zip
unzip -o telegram-vps-bot.zip
cd telegram-vps-bot

echo "📂 Copying files to /var/www/html/bot..."
sudo mkdir -p /var/www/html/bot
sudo cp -r telegram-bot-files/* /var/www/html/bot/
sudo chown -R www-data:www-data /var/www/html/bot
sudo chmod -R 755 /var/www/html/bot

echo "🛠 Configuring database.php..."
sed -i "s/'username' *=> *''/'username' => '${DBUSER}'/g" /var/www/html/bot/database.php
sed -i "s/'passwoed' *=> *''/'password' => '${DBPASS}'/g" /var/www/html/bot/database.php
sed -i "s/'dbname' *=> *''/'dbname' => '${DBNAME}'/g" /var/www/html/bot/database.php
sed -i "s/\\\$api_key = '';/\$api_key = '${NEXTKEY}';/g" /var/www/html/bot/database.php

echo "⚙️ Configuring bot.php..."
sed -i "s/define('ROBOT',' TOKEN ');/define('ROBOT','${TOKEN}');/g" /var/www/html/bot/bot.php

echo "⚙️ Configuring nextpay.php..."
sed -i "s/define(\"Domin\",.*/define(\"Domin\",\"${DOMAIN}\");/g" /var/www/html/bot/nextpay.php
sed -i "s/define(\"nextpay\",.*/define(\"nextpay\", \"${NEXTKEY}\");/g" /var/www/html/bot/nextpay.php

echo "🛢 Creating MySQL database..."
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS ${DBNAME};
CREATE USER IF NOT EXISTS '${DBUSER}'@'localhost' IDENTIFIED BY '${DBPASS}';
GRANT ALL PRIVILEGES ON ${DBNAME}.* TO '${DBUSER}'@'localhost';
FLUSH PRIVILEGES;"

echo "🌐 Setting Telegram Webhook..."
curl -s "https://api.telegram.org/bot${TOKEN}/setWebhook?url=https://${DOMAIN}/bot/bot.php"

echo "⏱ Adding Cron job..."
(crontab -l 2>/dev/null; echo "*/30 * * * * /usr/bin/php /var/www/html/bot/cron.php") | crontab -

echo "✅ Installation complete!"
echo "➡️  Visit: https://${DOMAIN}/bot/"
