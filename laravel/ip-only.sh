#!/bin/bash

CONCATED_TEXT=""

# Define the lowercase function
to_lowercase() {
    local str="$1"
    echo "${str,,}"
}

function print_color() {
    NC="\033[0m"

    case $1 in
    "green") COLOR="\033[0;32m" ;;
    "red") COLOR="\033[0;31m" ;;
    "*") COLOR="\033[0m" ;;
    esac

    echo -e "${COLOR} $2 ${NC}"
}

function check_service_status() {
    is_service_active=$(systemctl is-active $1)

    if [ "$is_service_active" = "active" ]; then
        print_color "green" "$1 service is active"
    else
        print_color "red" "$1 service is not active"
        exit 1
    fi
}

# Get Server IP (automatically)
SERVER_IP=$(hostname -I | awk '{print $1}')
CONCATED_TEXT+="Your Server IP: $SERVER_IP \n"

# Prompt the user for confirmation to create user
read -r -p "Do you want to create a new user? (yes/no): " isCreateUser

isCreateUser=$(to_lowercase "$isCreateUser")

# Check if the user entered "yes" or "y"
if [[ "$isCreateUser" =~ ^(yes|y)$ ]]; then
    read -r -p "Enter User name (eg. ubuntu): " SYS_USER_NAME
    read -r -p "Enter User Password: " SYS_USER_PASSWORD

    CONCATED_TEXT+="Your System User Name: $SYS_USER_NAME \n"
    CONCATED_TEXT+="Your System User Password: $SYS_USER_PASSWORD \n"
else
    echo "User creation will be skipped..."
fi

# Prompt the user for confirmation to install & setup mysql
read -r -p "Do you want to install MySQL? (yes/no): " isMysqlInstall

isMysqlInstall=$(to_lowercase "$isMysqlInstall")

# Check if the user entered "yes" or "y"
if [[ "$isMysqlInstall" =~ ^(yes|y)$ ]]; then
    read -r -p "Enter MySQL Database Name: " MYSQL_DB_NAME
    read -r -p "Enter MySQL Database Username: " MYSQL_DB_USERNAME
    read -r -p "Enter MySQL Database User Password: " MYSQL_DB_PASSWORD

    CONCATED_TEXT+="Your MySQL Database Name: $MYSQL_DB_NAME \n"
    CONCATED_TEXT+="Your MySQL Database Username: $MYSQL_DB_USERNAME \n"
    CONCATED_TEXT+="Your MySQL Database User Password: $MYSQL_DB_PASSWORD \n"
else
    echo "MySQL Installation will be skipped..."
fi

# Prompt the user for confirmation to install & setup PostgreSQL
read -r -p "Do you want to install PostgreSQL? (yes/no): " isPsqlInstall

isPsqlInstall=$(to_lowercase "$isPsqlInstall")

# Check if the user entered "yes" or "y"
if [[ "$isPsqlInstall" =~ ^(yes|y)$ ]]; then
    read -r -p "Enter Postgres Database Name: " POSTGRES_DB_NAME
    read -r -p "Enter Postgres User Password: " POSTGRES_USER_PASSWORD

    CONCATED_TEXT+="Your Postgres Database Name: $POSTGRES_DB_NAME \n"
    CONCATED_TEXT+="Your Postgres Database User Password: $POSTGRES_USER_PASSWORD \n"
else
    echo "PostgreSQL Installation will be skipped..."
fi

# Prompt the user for confirmation to install & setup PHP
read -r -p "Do you want to install PHP? (yes/no): " isPhpInstall

isPhpInstall=$(to_lowercase "$isPhpInstall")

# Check if the user entered "yes" or "y"
if [[ "$isPhpInstall" =~ ^(yes|y)$ ]]; then
    read -r -p "Enter PHP Version (eg. 8.1): " PHP_VERSION

    CONCATED_TEXT+="Your PHP Version: $PHP_VERSION \n"
else
    echo "PHP Installation will be skipped..."
fi

# Prompt the user for confirmation to install & setup Node
read -r -p "Do you want to install NodeJs? (yes/no): " isNodeInstall

isNodeInstall=$(to_lowercase "$isNodeInstall")

# Check if the user entered "yes" or "y"
if [[ "$isNodeInstall" =~ ^(yes|y)$ ]]; then
    read -r -p "Enter NodeJs Version (eg. 18): " NODE_VERSION

    CONCATED_TEXT+="Your NodeJs Version: $NODE_VERSION \n"
else
    echo "Node Installation will be skipped..."
fi

# Display the input information
print_color "green" "$CONCATED_TEXT"

# Final confirmation
read -r -p "Are you sure you want to continue? (yes/no): " isConfirmed

isConfirmed=$(to_lowercase "$isConfirmed")

# Check if the user entered "yes" or "y"
if [[ "$isConfirmed" =~ ^(yes|y)$ ]]; then
    print_color "green" "Installation started..."
else
    echo "Aborting..."
    exit 1
fi

############
## Server Setup script Start here.
############

#++++++++ Update & Upgrade the system +++++++++++++++++++++
print_color "green" "Updating and upgrading the system..."
sudo apt update -y
sudo apt upgrade -y

#++++++++ FireWall Installation +++++++++++++++++++++
print_color "green" "Installing Firewall..."
sudo apt install ufw -y
sudo ufw allow 'OpenSSH'
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

#++++++++ User Setup ++++++++++++++++++++++++++++++
if [ -n "$SYS_USER_NAME" ] && [ -n "$SYS_USER_PASSWORD" ]; then
    print_color "green" "Setting up User..."
    sudo useradd -ms /bin/bash "$SYS_USER_NAME"
    echo "$SYS_USER_NAME:$SYS_USER_PASSWORD" | sudo chpasswd
    sudo usermod -aG sudo "$SYS_USER_NAME"
    sudo mkdir -p /home/"$SYS_USER_NAME"/www/app
    print_color "green" "User Setup Completed."
fi

#++++++++ Nginx Installation ++++++++++++++++++++++++++++++
print_color "green" "Installing Nginx..."
sudo add-apt-repository ppa:ondrej/nginx -y
sudo apt update -y
sudo apt install nginx libnginx-mod-http-cache-purge libnginx-mod-http-headers-more-filter -y
sudo ufw allow 'Nginx Full'

# Create web root directory
sudo mkdir -p /var/www/app/public

# Create a default index.html page for testing
cat > /var/www/app/public/index.html <<-EOF
<!DOCTYPE html>
<html>
<head>
    <title>Server Setup Complete</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 50px;
            text-align: center;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 4px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #4CAF50;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Server Setup Complete!</h1>
        <p>Your server is now up and running at IP: $SERVER_IP</p>
        <p>This is the default page. Replace this with your application files.</p>
    </div>
</body>
</html>
EOF

# Configure Nginx to serve the application on the server IP
sudo touch /etc/nginx/sites-available/app

cat > /etc/nginx/sites-available/app <<-EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    root /var/www/app/public;
    index index.php index.html index.htm;
    
    server_name _;
    
    access_log /var/log/nginx/app-access.log;
    error_log /var/log/nginx/app-error.log error;
    
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    
    charset utf-8;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }
    
    error_page 404 /index.php;
EOF

# Add PHP configuration if PHP is being installed
if [ -n "$PHP_VERSION" ]; then
    cat >> /etc/nginx/sites-available/app <<-EOF
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php$PHP_VERSION-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }
EOF
fi

# Finish the server block
cat >> /etc/nginx/sites-available/app <<-EOF
    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF

# Enable the site and remove default if it exists
sudo ln -s /etc/nginx/sites-available/app /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

sudo systemctl enable nginx
sudo systemctl restart nginx

check_service_status nginx
print_color "green" "Nginx Setup Completed..."

#++++++++ PHP & Composer Installation ++++++++++++++++++++++++++++++
if [ -n "$PHP_VERSION" ]; then
    print_color "green" "Installing PHP & Composer..."
    sudo apt -y install software-properties-common ca-certificates lsb-release apt-transport-https
    sudo add-apt-repository ppa:ondrej/php -y
    sudo apt update -y
    sudo apt -y install php"$PHP_VERSION"
    sudo apt install -y php"$PHP_VERSION"-{fpm,gd,mbstring,mysql,pgsql,redis,xml,xmlrpc,opcache,cli,zip,soap,intl,bcmath,curl,imagick,common,imap,readline}
    sudo apt remove --purge apache2 -y
    sudo update-alternatives --config php
    
    # Add PHP info page for testing
    cat > /var/www/app/public/index.php <<-EOF
<?php
echo phpinfo();
EOF
    
    curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
    
    check_service_status php"$PHP_VERSION"-fpm
    print_color "green" "PHP & Composer setup completed..."
fi

#++++++++ Nodejs Installation ++++++++++++++++++++++++++++++
if [ -n "$NODE_VERSION" ]; then
    print_color "green" "Installing Nodejs & npm"
    curl -fsSL https://deb.nodesource.com/setup_"$NODE_VERSION".x | sudo -E bash -
    sudo apt-get install -y nodejs
    print_color "green" "Nodejs & npm setup completed..."
fi

#++++++++ MariaDB Installation ++++++++++++++++++++++++++++++
if [ -n "$MYSQL_DB_NAME" ] && [ -n "$MYSQL_DB_USERNAME" ] && [ -n "$MYSQL_DB_PASSWORD" ]; then
    print_color "green" "Installing MySQL..."
    sudo apt update -y
    sudo apt install mariadb-server mariadb-client -y
    
    # Create a SQL script
    cat > configure-mysql.sql <<-EOF
CREATE USER '$MYSQL_DB_USERNAME'@'%' IDENTIFIED BY '$MYSQL_DB_PASSWORD';
CREATE DATABASE $MYSQL_DB_NAME CHARACTER SET utf8 COLLATE utf8_unicode_ci;
GRANT ALL ON $MYSQL_DB_NAME.* TO '$MYSQL_DB_USERNAME'@'%';
FLUSH PRIVILEGES;
EOF
    
    sudo mysql -u root < configure-mysql.sql
    
    # Configure MariaDB to listen on all interfaces
    sudo sed -i 's/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
    
    sudo systemctl restart mysql
    sudo mysql_secure_installation
    
    check_service_status mysql
    print_color "green" "MySQL setup completed..."
fi

#++++++++ PostgreSQL Installation ++++++++++++++++++++++++++++++
if [ -n "$POSTGRES_DB_NAME" ] && [ -n "$POSTGRES_USER_PASSWORD" ]; then
    print_color "green" "Installing PostgreSQL..."
    sudo apt update -y
    sudo apt install postgresql postgresql-contrib -y
    
    # Create a temporary directory in a location writable by the PostgreSQL user
    temp_dir=$(sudo -u postgres mktemp -d)
    
    # Create a temporary SQL file
    temp_sql_file="$temp_dir/configure-db.sql"
    
    # Write SQL commands to the temporary file
    cat > "$temp_sql_file" <<EOF
ALTER USER postgres PASSWORD '$POSTGRES_USER_PASSWORD';
CREATE DATABASE "$POSTGRES_DB_NAME";
EOF
    
    # Execute SQL script using sudo
    sudo -u postgres psql -f "$temp_sql_file"
    
    # Configure PostgreSQL to listen on all interfaces
    sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf
    
    # Allow connections from all hosts (for development purposes only - for production, restrict to specific IPs)
    echo "host    all             all             0.0.0.0/0               md5" | sudo tee -a /etc/postgresql/*/main/pg_hba.conf
    
    sudo systemctl restart postgresql
    
    # Remove temporary directory
    rm -rf "$temp_dir"
    
    check_service_status postgresql
    print_color "green" "PostgreSQL setup completed..."
fi

############
## Server Setup script end here.
############

print_color "green" "Server Setup Completed"
print_color "green" "You can access your application at: http://$SERVER_IP"