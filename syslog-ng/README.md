# Routing logs with `syslog-ng` 

`syslog-ng` is a powerful and flexible open-source log management tool that extends the traditional capabilities of the **syslog** protocol. It allows administrators to collect, filter, and route logs from various sources to multiple destinations, providing centralized log management for improved visibility, auditing, and troubleshooting.

With `syslog-ng`, you can route logs based on their content, priority, or source, and send them to various destinations like files, remote servers, databases, or third-party platforms. This helps ensure that logs are stored, analyzed, and monitored efficiently.

### Key Components of `syslog-ng` Log Routing:
1. **Sources**: Defines where the logs are coming from, such as system logs, network traffic (UDP/TCP), or application logs.
   ```bash
   source s_network {
      network(
        transport("udp")
        port(514)
        flags(no-parse)
      );
    };
   ```

2. **Destinations**: Defines where the logs should be sent, such as local files, remote servers, or other log collectors.
   ```bash
   destination d_local { file("/var/log/messages"); };
   destination d_remote { tcp("192.168.1.100" port(514)); };
   ```

3. **Filters**: Allows you to create rules to decide which logs should be routed to which destinations. For example, you can filter logs based on severity or program name.
   ```bash
   filter f_critical { 
      level(
        crit..emerg
      ); 
    };
   ```

4. **Log Paths**: Combines sources, filters, and destinations into a unified workflow, allowing logs to be routed based on custom rules.
   ```bash
   log { 
      source(s_network); 
      filter(f_critical); 
      destination(d_remote); 
    };
   ```

## Routing Logs with `syslog-ng` to SentinelOne AI SIEM

Here’s a basic example of how to configure `syslog-ng` to route critical logs from network sources to SentinelOne AI SIEM:

```bash
source udp_fortigate {
  network(
    transport("udp")
    port(514)
    flags(no-parse)
  );
};

destination d_sentinelone {
  http(
    url("https://ingest.us1.sentinelone.net/services/collector/raw?sourcetype=syslog")
    headers(
        "Authorization: Bearer 0abc1dAeB2CfghDiEFj5klmG_JKnopq6Hr7sIMNOtPv8==", 
        "Content-Type: text/plain")
    body("${MESSAGE}")
    method("POST")
    content-compression("gzip")
  );
};

log {
       source(udp_fortigate);
       destination(d_sentinelone);
};
```
### HTTP API ingestion

Use the `syslog-ng-mod-http` library to route log data to a SentinelOne HTTP API ingestion endpoint. The HTTPS protocol ensures that logs are securely transported outside of your network. This is essential when dealing with sensitive information, especially in compliance-regulated environments.