#!/usr/bin/bash
# File in /root/user-data.bash.tpl

# Function to install syslog-ng on Ubuntu
install_syslog_ng_ubuntu() {
    echo "Detected Ubuntu OS."
    
    wget -qO - https://ose-repo.syslog-ng.com/apt/syslog-ng-ose-pub.asc | sudo apt-key add -
    echo "deb https://ose-repo.syslog-ng.com/apt/ stable ubuntu-focal" | sudo tee -a /etc/apt/sources.list.d/syslog-ng-ose.list

    # Update package list
    sudo apt update

    # Install syslog-ng and the HTTP module
    sudo apt install -y syslog-ng syslog-ng-mod-http

    # Enable and start the syslog-ng service
    sudo systemctl daemon-reload
    sudo systemctl enable syslog-ng
    sudo systemctl start syslog-ng

    echo "syslog-ng installed and started on Ubuntu."
}

# Function to install syslog-ng on SUSE
install_syslog_ng_suse() {
    echo "Detected SUSE OS."
    
    # Add the syslog-ng repository
    sudo zypper ar https://download.opensuse.org/repositories/home:/czanik:/syslog-ng48/15.5/ syslog-ng48

    # Refresh the package list
    sudo zypper refresh

    # Install syslog-ng and the HTTP module
    sudo zypper in -y syslog-ng syslog-ng-curl

    # Enable and start the syslog-ng service
    sudo systemctl daemon-reload
    sudo systemctl enable syslog-ng
    sudo systemctl start syslog-ng

    echo "syslog-ng installed and started on SUSE."
}

# Detect the OS type
if [ -f /etc/os-release ]; then
    # Source the os-release file to read OS info
    . /etc/os-release

    case "$ID" in
        ubuntu)
            install_syslog_ng_ubuntu
            ;;
        suse|opensuse|sles)
            install_syslog_ng_suse
            ;;
        *)
            echo "Unsupported OS. This script only works on Ubuntu or SUSE."
            exit 1
            ;;
    esac
else
    echo "Could not detect OS type. /etc/os-release not found."
    exit 1
fi

# To prevent pollution, we use a base64 blob to store the configuration
SDL_SYSLOG="c291cmNlIHVkcF9mb3J0aWdhdGUgewogIG5ldHdvcmsoCiAgICB0cmFuc3BvcnQoInVkcCIpCiAgICBwb3J0KDUxNCkKICAgIGZsYWdzKG5vLXBhcnNlKQogICk7Cn07CgpkZXN0aW5hdGlvbiBkX3NlbnRpbmVsb25lX2hlY19mb3J0aWdhdGUgewogIGh0dHAoCiAgICB1cmwoImh0dHBzOi8vaW5nZXN0LnVzMS5zZW50aW5lbG9uZS5uZXQvc2VydmljZXMvY29sbGVjdG9yL3Jhdz9zb3VyY2V0eXBlPW1hcmtldHBsYWNlLWZvcnRpbmV0Zm9ydGlnYXRlLWxhdGVzdCIpCiAgICBoZWFkZXJzKCJBdXRob3JpemF0aW9uOiBCZWFyZXIgU0RMX1RPS0VOIiwgIkNvbnRlbnQtVHlwZTogdGV4dC9wbGFpbiIpCiAgICBib2R5KCIke01FU1NBR0V9IikKICAgIG1ldGhvZCgiUE9TVCIpCiAgICBjb250ZW50LWNvbXByZXNzaW9uKCJnemlwIikKICAgIGJhdGNoLWxpbmVzKDUwMDApCiAgICBiYXRjaC1ieXRlcyg2MDAwS2IpCiAgICBiYXRjaC10aW1lb3V0KDEwMDAwKQogICAgcmV0cmllcygxKQogICAgd29ya2Vycyg0KQogICk7Cn07Cgpsb2cgewogICAgICAgc291cmNlKHVkcF9mb3J0aWdhdGUpOwogICAgICAgZGVzdGluYXRpb24oZF9zZW50aW5lbG9uZV9oZWNfZm9ydGlnYXRlKTsKfTsK"

if [ -d "/etc/syslog-ng/conf.d" ]; then
    sudo echo $SDL_SYSLOG | base64 --decode > /etc/syslog-ng/conf.d/sentinel-one.conf
    # Restart syslog-ng to apply the changes
    sudo systemctl restart syslog-ng
else
    echo "Could not find the syslog-ng configuration directory."
    exit 1
fi

SDL_API_TOKEN="${SDL_TOKEN}"

# Check if the environment variable SDL_TOKEN exists and is not empty
if [ -n "$SDL_API_TOKEN" ]; then
    # Use sed to replace SDL_TOKEN with the contents of SDL_TOKEN in a file
    sudo sed -i "s/SDL_TOKEN/$SDL_API_TOKEN/g" /etc/syslog-ng/conf.d/sentinel-one.conf
    echo "SDL_TOKEN has been replaced with the value of ${SDL_TOKEN}."

    # Restart syslog-ng to apply the changes
    sudo systemctl restart syslog-ng
else
    echo "SDL_TOKEN \"${SDL_TOKEN}\" is not set or is empty. No replacement done."
fi

unset SDL_API_TOKEN
