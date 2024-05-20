#!/bin/bash

sudo apt install python
sudo apt install python3-pip

sudo apt install python3-virtualenv

cd ~/project_folder_name

virtualenv env_name

source virtualenv_name/bin/activate

pip install -r requirements.txt

pip install gunicorn

sudo nano /etc/systemd/system/your_domain.gunicorn.socket

# [Unit]
# Description=your_domain.gunicorn socket

# [Socket]
# ListenStream=/run/your_domain.gunicorn.sock

# [Install]
# WantedBy=sockets.target

# Example:-
# [Unit]
# Description=your_domain.gunicorn socket

# [Socket]
# ListenStream=/run/your_domain.gunicorn.sock

# [Install]
# WantedBy=sockets.target

sudo nano /etc/systemd/system/your_domain.gunicorn.service

[Unit]
Description=your_domain.gunicorn daemon
Requires=your_domain.gunicorn.socket
After=network.target

[Service]
User=username
Group=groupname
WorkingDirectory=/home/username/project_folder_name
ExecStart=/home/username/project_folder_name/virtual_env_name/bin/gunicorn \
    --access-logfile - \
    --workers 3 \
    --bind unix:/run/your_domain.gunicorn.sock \
    inner_project_folder_name.wsgi:application

[Install]
WantedBy=multi-user.target

sudo systemctl start your_domain.gunicorn.socket
sudo systemctl start your_domain.gunicorn.service

sudo systemctl enable your_domain.gunicorn.socket
sudo systemctl enable your_domain.gunicorn.service

sudo systemctl status your_domain.gunicorn.socket
sudo systemctl status your_domain.gunicorn.service
