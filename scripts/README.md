# Basic testing

We use these scripts is to test connectivity to:

1. confirm the ability to connect and deliver data to your SLD ingestion endpoint.
2. send test messages localhost over UDP port 514

## 1 - Connect to the SLD ingestion endpoint

### 1.1 - Expose your SDL API Token
Do not declare this variable in a public enviornment, and **do not store in a file** to avoid credential sprawl.

```bash
SDL_API_TOKEN="0abc1dAeB2CfghDiEFj5klmG_JKnopq6Hr7sIMNOtPv8=="
```

### 1.2 - Run a simple connection test

The [test_rest](test_rest.bash) script looks for this variable. If it is not declared, you are prompted to enter it each time your run the script.

```bash
bash test_rest.bash
```
Successful results should looks like these:

```bash
Oct 01 16:23:52.000 D6T6RGQQ4T tester[4867]: Test message to SDL intake API using curl and paloaltonetworksfirewall

* Host ingest.us1.sentinelone.net:443 was resolved.
* IPv6: (none)
* IPv4: 100.64.1.18
*   Trying 100.64.1.18:443...
* Connected to ingest.us1.sentinelone.net (100.64.1.18) port 443
* ALPN: curl offers h2,http/1.1
* (304) (OUT), TLS handshake, Client hello (1):
* (304) (IN), TLS handshake, Server hello (2):
* (304) (IN), TLS handshake, Unknown (8):
* (304) (IN), TLS handshake, Certificate (11):
* (304) (IN), TLS handshake, CERT verify (15):
* (304) (IN), TLS handshake, Finished (20):
* (304) (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 
* ALPN: server accepted h2
* Server certificate:
*  subject: CN=*.us1.sentinelone.net
*  start date: Aug  6 15:54:10 2024 GMT
*  expire date: Nov  4 15:54:09 2024 GMT
*  issuer: C=US; O=Lets Encrypt; CN=R10
*  SSL certificate verify ok.
* using HTTP/2
* [HTTP/2] [1] OPENED stream for https://ingest.us1.sentinelone.net/services/collector/raw?sourcetype=marketplace-paloaltonetworksfirewall-latest
* [HTTP/2] [1] [:method: POST]
* [HTTP/2] [1] [:scheme: https]
* [HTTP/2] [1] [:authority: ingest.us1.sentinelone.net]
* [HTTP/2] [1] [:path: /services/collector/raw?sourcetype=marketplace-paloaltonetworksfirewall-latest]
* [HTTP/2] [1] [user-agent: curl/8.7.1]
* [HTTP/2] [1] [authorization: Bearer 0abc1dAeB2CfghDiEFj5klmG_JKnopq6Hr7sIMNOtPv8==]
* [HTTP/2] [1] [accept: application/text]
* [HTTP/2] [1] [content-length: 115]
* [HTTP/2] [1] [content-type: application/x-www-form-urlencoded]
> POST /services/collector/raw?sourcetype=marketplace-paloaltonetworksfirewall-latest HTTP/2
> Host: ingest.us1.sentinelone.net
> User-Agent: curl/8.7.1
> Authorization: Bearer 0abc1dAeB2CfghDiEFj5klmG_JKnopq6Hr7sIMNOtPv8==
> Accept: application/text
> Content-Length: 115
> Content-Type: application/x-www-form-urlencoded
> 
* upload completely sent off: 115 bytes
< HTTP/2 200 
< date: Tue, 01 Oct 2024 20:23:52 GMT
< content-length: 27
< content-type: text/plain; charset=utf-8
< x-envoy-upstream-service-time: 60
< server: envoy
< 
* Connection #0 to host ingest.us1.sentinelone.net left intact
{"text":"Success","code":0}%                                                                    
```

If you are able to reach the SDL ingestion endpoint from the system, you should see a 200 `OK` message.

---

If your SDL_API_TOKEN is not valid, you will see a message trailer as follows:

```bash
* upload completely sent off: 115 bytes
< HTTP/2 401 
< date: Tue, 01 Oct 2024 21:04:12 GMT
< content-length: 32
< content-type: text/plain; charset=utf-8
< x-envoy-upstream-service-time: 16
< server: envoy
< 
* Connection #0 to host ingest.us1.sentinelone.net left intact
{"text":"Unauthorized","code":3}
```

---

If your host does not have the ability to connect to the SDL ingestion endpoint, you will see a message like this one:

```bash
* Could not resolve host: ingest.us1.sentinelone.net
* Closing connection
curl: (6) Could not resolve host: ingest.us1.sentinelone.net
```

