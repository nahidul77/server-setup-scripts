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

# Get User Domain

read -r -p "Enter Your Domain name (eg. domain.com): " DOMAIN_NAME

if [ -n "$DOMAIN_NAME" ]; then
    CONCATED_TEXT+="Your Domain Name: $DOMAIN_NAME \n"
else
    echo "Input is empty. Exiting..."
    exit 1
fi

# Prompt the user for confirmation to create user

read -r -p "do you want to you create new user? (yes/no): " isCreateUser

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

read -r -p "do you want to you install mysql? (yes/no): " isMysqlInstall

isMysqlInstall=$(to_lowercase "$isMysqlInstall")

# Check if the user entered "yes" or "y"
if [[ "$isMysqlInstall" =~ ^(yes|y)$ ]]; then
    read -r -p "Enter Mysql Database Name: " MYSQL_DB_NAME
    read -r -p "Enter Mysql Database Username: " MYSQL_DB_USERNAME
    read -r -p "Enter Mysql Database User Password: " MYSQL_DB_PASSWORD

    CONCATED_TEXT+="Your Mysql Database Name: $MYSQL_DB_NAME \n"
    CONCATED_TEXT+="Your Mysql Database Username: $MYSQL_DB_USERNAME \n"
    CONCATED_TEXT+="Your Mysql Database User Password: $MYSQL_DB_PASSWORD \n"
else
    echo "Mysql Installation will be skipped..."
fi

# Prompt the user for confirmation to install & setup Postgresql

read -r -p "do you want to you install Postgresql? (yes/no): " isPsqlInstall

isPsqlInstall=$(to_lowercase "$isPsqlInstall")

# Check if the user entered "yes" or "y"
if [[ "$isPsqlInstall" =~ ^(yes|y)$ ]]; then
    read -r -p "Enter Postgres Database Name: " POSTGRES_DB_NAME
    read -r -p "Enter Postgres User Password: " POSTGRES_USER_PASSWORD

    CONCATED_TEXT+="Your Postgres Database Name: $POSTGRES_DB_NAME \n"
    CONCATED_TEXT+="Your Postgres Database User Password: $POSTGRES_USER_PASSWORD \n"
else
    echo "Postgresql Installation will be skipped..."
fi

# Prompt the user for confirmation to install & setup Node

read -r -p "do you want to you install NodeJs? (yes/no): " isNodeInstall

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

sudo apt update -y

sudo apt upgrade -y

#++++++++ FireWall Installation +++++++++++++++++++++

print_color "green" "Installing Firewall..."

sudo ufw allow 'OpenSSH'

sudo ufw enable

#++++++++ User Setup ++++++++++++++++++++++++++++++

if [ -n "$SYS_USER_NAME" ] && [ -n "$SYS_USER_PASSWORD" ]; then

    print_color "green" "Setup User..."

    sudo useradd -ms /bin/bash "$SYS_USER_NAME"

    sudo echo "$SYS_USER_NAME:$SYS_USER_PASSWORD" | chpasswd

    sudo usermod -aG sudo "$SYS_USER_NAME"

    sudo mkdir -p /home/"$SYS_USER_NAME"/www/"$DOMAIN_NAME"

    print_color "green" "User Setup Completed.."

fi

#++++++++ Nginx Installation ++++++++++++++++++++++++++++++

if [ -n "$DOMAIN_NAME" ]; then

    print_color "green" "Installing Nginx..."

    sudo add-apt-repository ppa:ondrej/nginx

    sudo apt update -y

    sudo apt install nginx libnginx-mod-http-cache-purge libnginx-mod-http-headers-more-filter -y

    sudo ufw allow 'Nginx Full'

    sudo mkdir -p /var/www/"$DOMAIN_NAME"/public

    sudo touch /etc/nginx/sites-available/"$DOMAIN_NAME"

    cat >/etc/nginx/sites-available/"$DOMAIN_NAME" <<-EOF
server{
    listen 80;
    listen [::]:80;
    server_name "$DOMAIN_NAME" www."$DOMAIN_NAME";
    location / {
       proxy_pass http://localhost:3001;
       proxy_http_version 1.1;
       proxy_set_header Upgrade \$http_upgrade;
       proxy_set_header Connection 'upgrade';
       proxy_set_header Host \$host;
       proxy_cache_bypass \$http_upgrade;
    }
}
EOF

    sudo ln -s /etc/nginx/sites-available/"$DOMAIN_NAME" /etc/nginx/sites-enabled/

    sudo systemctl enable nginx

    check_service_status nginx

    print_color "green" "Nginx Setup Completed..."

fi

#++++++++ Nodejs Installation ++++++++++++++++++++++++++++++

if [ -n "$NODE_VERSION" ]; then

    print_color "green" "Installing Nodejs & npm"

    curl -fsSL https://deb.nodesource.com/setup_"$NODE_VERSION".x | sudo -E bash -

    sudo apt-get install -y nodejs

    sudo npm install -g pm2@latest

    sudo pm2 startup

    print_color "green" "Nodejs, npm & PM2 setup completed..."
fi

#++++++++ Mariadb Installation ++++++++++++++++++++++++++++++

if [ -n "$MYSQL_DB_NAME" ] && [ -n "$MYSQL_DB_USERNAME" ] && [ -n "$MYSQL_DB_PASSWORD" ]; then

    print_color "green" "Installing Mysql..."

    sudo apt update -y

    sudo apt install mariadb-server mariadb-client -y

    # Create a SQL script

    cat >configure-mysql.sql <<-EOF
CREATE USER '$MYSQL_DB_USERNAME'@'%' IDENTIFIED BY '$MYSQL_DB_PASSWORD';

CREATE DATABASE $MYSQL_DB_NAME CHARACTER SET utf8 COLLATE utf8_unicode_ci;

GRANT ALL ON $MYSQL_DB_NAME.* TO '$MYSQL_DB_USERNAME'@'%';

FLUSH PRIVILEGES;

exit
EOF

    sudo mysql -u root <configure-mysql.sql

    sudo mysql_secure_installation

    check_service_status mysql

    print_color "green" "Mysql setup completed..."

fi

#++++++++ Postgresql Installation ++++++++++++++++++++++++++++++

if [ -n "$POSTGRES_DB_NAME" ] && [ -n "$POSTGRES_USER_PASSWORD" ]; then

    print_color "green" "Installing postgresql..."

    sudo apt update -y

    sudo apt install postgresql-14 postgresql-contrib-14 postgresql-client-14 -y

    # Create a temporary directory in a location writable by the PostgreSQL user
    temp_dir=$(sudo -u postgres mktemp -d)

    # Create a temporary SQL file
    temp_sql_file="$temp_dir/configure-db.sql"

    # Write SQL commands to the temporary file
    cat >"$temp_sql_file" <<EOF
ALTER USER postgres PASSWORD '$POSTGRES_DB_PASSWORD';
CREATE DATABASE "$POSTGRES_DB_NAME";
EOF

    # Execute SQL script using sudo
    sudo -u postgres psql -f "$temp_sql_file"

    # Remove temporary directory
    rm -rf "$temp_dir"

    check_service_status postgresql

    print_color "green" "Postgresql setup completed..."

fi

#++++++++ Certbot & Wildcard SSL Installation ++++++++++++++++++++++++++++++

if [ -n "$DOMAIN_NAME" ]; then

    print_color "green" "Installing Certbot & SSL..."

    sudo snap install --classic certbot

    sudo certbot --nginx -d "$DOMAIN_NAME" -d www."$DOMAIN_NAME"

    sudo rm /etc/nginx/sites-enabled/default

    sudo systemctl reload nginx

    print_color "green" "Certbot & SSL Setup Completed..."

fi

############
## Server Setup script end here.
############

print_color "green" "Server Setup Completed"

##############Follow up command#############

# npm run build

# nano ecosystem.config.js

# module.exports = {
#   apps : [
#       {
#         name: "myapp",
#         script: "npm start",
#         port: 3001
#       }
#   ]
# }

# sudo service nginx restart

# pm2 start ecosystem.config.js

# pm2 save

# pm2 reload app_name
