# Installation

## Install syslog-ng on Ubuntu 20.02 - Focal

### Enable source repo
```    
wget -qO - https://ose-repo.syslog-ng.com/apt/syslog-ng-ose-pub.asc | sudo apt-key add -
echo "deb https://ose-repo.syslog-ng.com/apt/ stable ubuntu-focal" | sudo tee -a /etc/apt/sources.list.d/syslog-ng-ose.list
```
### Update package list
```
sudo apt update
```
### Install syslog-ng and the HTTP module

```
sudo apt install -y syslog-ng syslog-ng-mod-http
```
### Enable and start the syslog-ng service

```
sudo systemctl daemon-reload
sudo systemctl enable syslog-ng
sudo systemctl start syslog-ng
```

## Install syslog-ng on Ubuntu 22.02 - Jammy

### Enable source repo
```    
wget -qO - https://ose-repo.syslog-ng.com/apt/syslog-ng-ose-pub.asc | sudo apt-key add -
echo "deb https://ose-repo.syslog-ng.com/apt/ stable ubuntu-jammy" | sudo tee -a /etc/apt/sources.list.d/syslog-ng-ose.list
```
### Update package list
```
sudo apt update
```
### Install syslog-ng and the HTTP module

```
sudo apt install -y syslog-ng-core syslog-ng-scl syslog-ng-mod-http
```
### Enable and start the syslog-ng service

```
sudo systemctl daemon-reload
sudo systemctl enable syslog-ng
sudo systemctl start syslog-ng
```