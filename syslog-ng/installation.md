# Installation

## Install syslog-ng on Ubuntu 20.02 - Focal

### Enable source repo
```
# fetch the key    
wget -qO - https://ose-repo.syslog-ng.com/apt/syslog-ng-ose-pub.asc | sudo apt-key add -

# add the repo (for Focal)
echo "deb https://ose-repo.syslog-ng.com/apt/ stable ubuntu-focal" \
  | sudo tee -a /etc/apt/sources.list.d/syslog-ng-ose.list
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
# fetch the key    
wget -qO - https://ose-repo.syslog-ng.com/apt/syslog-ng-ose-pub.asc \
  | sudo gpg --dearmor -o /etc/apt/keyrings/syslog-ng-ose.gpg

# add the repo (for Jammy)
echo "deb [signed-by=/etc/apt/keyrings/syslog-ng-ose.gpg] https://ose-repo.syslog-ng.com/apt/ stable ubuntu-jammy" \
  | sudo tee /etc/apt/sources.list.d/syslog-ng-ose.list
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