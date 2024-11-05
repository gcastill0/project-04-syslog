# Syslog-ng Configuration

Here are some of the key commands and methods for troubleshooting `syslog-ng`:

| **Command**                                    | **Description**                                                                                                      |
|------------------------------------------------|----------------------------------------------------------------------------------------------------------------------|
| `sudo syslog-ng --syntax-only`                 | Checks for syntax errors in the syslog-ng configuration.                                                             |
| `sudo syslog-ng -Fedv`                         | Runs syslog-ng in debug mode, showing detailed processing logs in real-time.                                         |
| `sudo syslog-ng-ctl reload`                    | Reloads the syslog-ng configuration without stopping the service.                                                    |
| `sudo systemctl status syslog-ng`              | Shows the current status of the syslog-ng service.                                                                   |
| `sudo syslog-ng-ctl stats`                     | Displays statistics about received, filtered, and processed logs.                                                    |
| `sudo syslog-ng-ctl config`                    | Displays the active syslog-ng configuration.                                                                         |
| `sudo syslog-ng-ctl verbose --set`             | Increases the verbosity of syslog-ng logging for debugging purposes.                                                 |
| `sudo syslog-ng-ctl flush`                     | Flushes any queued messages immediately.                                                                             |
| `sudo ss -tuln \| grep 514`                     | Verifies that syslog-ng is listening on the correct network ports (e.g., port 514 for syslog).                      |
| `sudo journalctl -u syslog-ng`                 | Views startup and runtime logs for syslog-ng, useful for identifying startup issues.                                 |


### 1. **Check Configuration Syntax**

One of the most common issues with `syslog-ng` is a misconfigured configuration file. You can check if the syntax of your configuration file is correct with this command:

```bash
sudo syslog-ng --syntax-only
```

- This will parse the configuration file and report any syntax errors. If there are issues, the command will output detailed information about what is wrong.

### 2. **Start syslog-ng in Debug Mode**

You can start **syslog-ng** in debug mode to get detailed logging about its internal operations. This is especially useful when troubleshooting issues related to message processing or configuration problems.

```bash
sudo syslog-ng -Fedv
```

- **`-F`**: Run syslog-ng in the foreground (instead of as a daemon).
- **`-e`**: Log internal errors to stderr.
- **`-d`**: Enable debug/verbose mode.
- **`-v`**: Print version information and startup details.

This will output detailed logs to the console as syslog-ng runs, showing how it processes messages and where potential issues may arise.

### 3. **Reload syslog-ng Configuration**

If you've made changes to the configuration and want to reload it without stopping the service, you can use the following command:

```bash
sudo syslog-ng-ctl reload
```

This reloads the configuration without stopping the service, making it easier to test configuration changes on the fly.

### 4. **Check syslog-ng Status**

To check if syslog-ng is running and get basic information about its status:

```bash
sudo systemctl status syslog-ng
```

This command will show whether the service is active, provide basic logs, and indicate whether syslog-ng is encountering any major issues.

### 5. **View syslog-ng Internal Logs**

Syslog-ng generates internal logs, which can be useful for troubleshooting operational problems (e.g., failed log deliveries, missing configuration).

To view the internal logs, check the default log location (typically `/var/log/syslog` or `/var/log/messages` depending on your system):

```bash
sudo tail -f /var/log/syslog
```

If syslog-ng is running, you'll see the internal logs related to its operations.

### 6. **Query syslog-ng Statistics**

You can use the **`syslog-ng-ctl`** command to query various statistics about message processing, including how many logs have been received, processed, and sent to different destinations:

```bash
sudo syslog-ng-ctl stats
```

This will output detailed information on:
- Messages received by different sources.
- Messages processed by different filters.
- Messages sent to different destinations.

### 7. **List Current syslog-ng Configuration**

To see the active syslog-ng configuration that is currently loaded, you can use:

```bash
sudo syslog-ng-ctl config
```

This is especially useful for verifying which configuration is currently being used without having to manually check the configuration files.

### 8. **Increase Verbosity with syslog-ng-ctl**

You can adjust the verbosity level of syslog-ng on the fly using the following command:

```bash
sudo syslog-ng-ctl verbose --set
```

This increases the verbosity level, allowing you to see more detailed logs for debugging purposes. After you're done, you can reset the verbosity with:

```bash
sudo syslog-ng-ctl verbose --unset
```

### 9. **Flush syslog-ng Queues**

If you suspect that syslog-ng is not sending messages due to message queuing, you can manually flush the message queues using:

```bash
sudo syslog-ng-ctl flush
```

This forces syslog-ng to immediately send any queued messages to their destinations.

### 10. **Check the Listening Ports**

To confirm that syslog-ng is correctly listening on the expected network ports (for example, for UDP or TCP traffic on port 514), use:

```bash
sudo ss -tuln | grep 514
```

This shows whether syslog-ng is listening on the correct ports, such as port 514 for syslog over UDP/TCP.

### 11. **Analyze syslog-ng Startup Logs**

If syslog-ng fails to start, check the logs during startup for any errors. You can do this by using the `journalctl` command:

```bash
sudo journalctl -u syslog-ng
```

This will show you the systemd logs for syslog-ng and help pinpoint why syslog-ng may not be starting or why it’s encountering issues during initialization.

---

# Firewall Troubleshooting

## Security-Enhanced Linux (SELinux)

In some situations, the Linux firewall prevents the default behaviour with UDP traffic over port 514. 

For example, the following are typical errors in `/var/syslog`:
```bash
Sep 25 20:31:42 ip-172-31-10-3 systemd[1]: Starting System Logger Daemon...
Sep 25 20:31:42 ip-172-31-10-3 syslog-ng[41811]: [2024-09-25T20:31:42.401476] Error binding socket;
  addr='AF_INET(0.0.0.0:514)', error='Permission denied (13)'
```

In this case, we need to ascertain the status of the `Syslog` service as identified by the ports. Note that port 514 is not in the default configuration: 
```bash
[root@ip-172-31-10-3 conf.d]# semanage port -l | grep -i syslog
syslog_tls_port_t              tcp      6514, 10514
syslog_tls_port_t              udp      6514, 10514
syslogd_port_t                 tcp      601, 20514
syslogd_port_t                 udp      601, 20514
```

We double-check the status of the firewall. In this case, we're checking for a blocking behaviour - which we confirm with `sestatus`
```bash
[root@ip-172-31-10-3 conf.d]# sestatus
SELinux status:                 enabled
SELinuxfs mount:                /sys/fs/selinux
SELinux root directory:         /etc/selinux
Loaded policy name:             targeted
Current mode:                   enforcing
Mode from config file:          enforcing
Policy MLS status:              enabled
Policy deny_unknown status:     allowed
Memory protection checking:     actual (secure)
Max kernel policy version:      33
```

We enable the port via the firewall to allow traffic flow for syslog. Our desired port is 514, using the UDP protocol.
```bash
[root@ip-172-31-10-3 conf.d]# sudo semanage port -a -t syslogd_port_t -p udp 514
```
We confirm that port 514 is allowed via the firewall:
```bash
[root@ip-172-31-10-3 conf.d]# sudo semanage port -l | grep syslog
syslog_tls_port_t              tcp      6514, 10514
syslog_tls_port_t              udp      6514, 10514
syslogd_port_t                 tcp      601, 20514
syslogd_port_t                 udp      514, 601, 20514
```

## Uncomplicated Firewall (ufw)

Indicating message from `/var/log/messages`:

```bash
Oct  8 14:39:52 ip-10-0-2-114 kernel: [UFW BLOCK] IN=eth0 OUT= MAC=0a:ff:f4:c4:fe:89:0a:ff:d7:7e:56:a3:08:00 SRC=65.49.1.62 DST=10.0.2.114 LEN=40 TOS=0x00 PREC=0x00 TTL=239 ID=54321 PROTO=TCP SPT=43887 DPT=80 WINDOW=65535 RES=0x00 SYN URGP=0 
Oct  8 14:40:33 ip-10-0-2-114 kernel: [UFW BLOCK] IN=eth0 OUT= MAC=0a:ff:f4:c4:fe:89:0a:ff:d7:7e:56:a3:08:00 SRC=45.79.98.252 DST=10.0.2.114 LEN=44 TOS=0x00 PREC=0x00 TTL=240 ID=54321 PROTO=TCP SPT=35766 DPT=80 WINDOW=65535 RES=0x00 SYN URGP=0  
```

Start by checking the current status of UFW and the rules applied:

```bash
ubuntu@ip-10-0-2-114:~$ sudo ufw status verbose
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip
```

This will display all the active rules and whether UFW is enabled. Look for any rules that reference UDP port 514, which is the standard port for syslog over UDP.

Example output of the rule you're looking for:

```bash
514/udp                     ALLOW       Anywhere
```

If you do not see a rule for UDP port 514 and want to allow UDP syslog traffic, you can add a rule with the following command:

```bash
sudo ufw allow 514/udp
```

## Install TCP Dump

```bash
# Lastes version as of Oct. 2024
VERSION="4.99.5"  
# Download the source code
wget https://www.tcpdump.org/release/tcpdump-$VERSION.tar.gz

# Extract the files
tar -xvf tcpdump-$VERSION.tar.gz

# Navigate to the tcpdump directory
cd tcpdump-$VERSION/

# Build the software
make

# Install the software
sudo make install

# Output:
# tcpdump-$VERSION/
# tcpdump-$VERSION/[...]
# make: Nothing to be done for 'all'.
# make: Nothing to be done for 'install'.
```

```bash
wget https://rpmfind.net/linux/centos-stream/9-stream/BaseOS/x86_64/os/Packages/libpcap-1.10.0-4.el9.x86_64.rpm

wget https://rpmfind.net/linux/centos-stream/10-stream/AppStream/x86_64/os/Packages/tcpdump-4.99.4-9.el10.x86_64.rpm

sudo rpm -ivh libpcap-1.10.0-4.el9.x86_64.rpm
sudo rmp -ivh tcpdump-4.99.4-9.el10.x86_64.rpm

tcpdump --version
```