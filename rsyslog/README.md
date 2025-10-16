Requirements for rsyslog on **SUSE Linux Enterprise Server (SLES)** to forward UDP log traffic over HTTPS:

---

### 1. Base Package Installation

Install the core rsyslog package and required modules:

```bash
sudo zypper install rsyslog rsyslog-gnutls rsyslog-mmjsonparse rsyslog-omhttp
```

Modules needed:

* **rsyslog-gnutls** – provides TLS/SSL capability.
* **rsyslog-omhttp** – enables HTTP(S) output.
* **rsyslog-mmjsonparse** – useful if log messages are in JSON format.

---

### 2. Network and Firewall Configuration

* Allow **outbound TCP 443** to your HTTPS endpoint.
* Allow **inbound UDP 514** if receiving syslog traffic locally.
* Example:

  ```bash
  sudo firewall-cmd --add-port=514/udp --permanent
  sudo firewall-cmd --reload
  ```

---

### 3. Configuration Requirements

In `/etc/rsyslog.conf` or under `/etc/rsyslog.d/`:

**Input (UDP):**

```conf
module(load="imudp")
input(type="imudp" port="514")
```

**Output (HTTPS):**

```conf
module(load="omhttp")

action(
    type="omhttp"
    server="ingest.us1.sentinelone.net"
    restpath="services/collector/raw?sourcetype=marketplace-fortinetfortigate-latest"
    httpcontenttype="text/plain"
    httpheaders=[	
        "Authorization: Bearer LOG_WRITE_ACCESS_KEY"
    ]
    errorfile="/tmp/rsyslog.err"
    template="unparsed_raw_string"
    serverport="443"
    batch="on"
    batch.format="newline"
    batch.maxsize="5000"
    batch.maxbytes="6000"
    compress="on"
    useHttps="on"
)
```

---

### 4. Validation

Run:

```bash
rsyslogd -N1
systemctl enable --now rsyslog
```

Check logs in `/var/log/messages` for connectivity or module errors.

---

### Summary Table

| Component        | Requirement                                   | Notes                              |
| ---------------- | --------------------------------------------- | ---------------------------------- |
| OS               | SLES 12 SP5 or SLES 15+                       | Fully supported packages available |
| Package          | `rsyslog`, `rsyslog-omhttp`, `rsyslog-gnutls` | For HTTPS transport                |
| Port             | 443 outbound                                  | To HTTPS destination               |
| Certificate      | Valid CA or self-signed trust                 | Required for HTTPS                 |
| SELinux/AppArmor | Must allow rsyslog network connections        | Verify policy                      |
| Test command     | `rsyslogd -N1`                                | Validates config syntax            |

