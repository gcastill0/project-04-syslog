# Linux Kernel UDP Tuning for Docker Syslog Ingestion

## Overview

These settings are **host-level Linux kernel network parameters**. They apply globally
to all UDP socket traffic on the host — they are not specific to any syslog service,
port, or application. Any process opening a UDP socket benefits from these settings,
including the Docker bridge network stack receiving traffic on port 514.

---

## Parameters

### `net.core.rmem_default`

The default receive buffer size (in bytes) allocated to any new socket before the
application explicitly requests a larger one.

| Property | Value |
|---|---|
| Default (kernel) | 212,992 bytes (~208 KB) |
| Recommended | 16,777,216 bytes (16 MB) |
| Scope | All UDP and TCP sockets |

---

### `net.core.rmem_max`

The **maximum** receive buffer size a socket is permitted to request. Applications
cannot exceed this ceiling even if they ask for more.

| Property | Value |
|---|---|
| Default (kernel) | 212,992 bytes (~208 KB) |
| Recommended | 33,554,432 bytes (32 MB) |
| Scope | All UDP and TCP sockets |

---

### `net.core.netdev_max_backlog`

The number of packets the kernel will queue per NIC when the receiving CPU is busy
processing the network stack. Overflow packets are silently dropped.

| Property | Value |
|---|---|
| Default (kernel) | 1,000 packets |
| Recommended | 5,000 packets |
| Scope | NIC input queue (all protocols) |

---

### `net.ipv4.udp_mem`

System-wide UDP memory pressure thresholds, expressed in **memory pages** as three
space-separated values:

| Field | Meaning |
|---|---|
| min | Below this, no memory pressure |
| pressure | Kernel begins reducing buffer allocations |
| max | Hard ceiling on total UDP memory usage |

| Property | Value |
|---|---|
| Default (kernel) | Auto-calculated at boot based on RAM |
| Recommended | `8388608 12582912 16777216` |
| Scope | All UDP sockets system-wide combined |

---

## Configuration File

Create the drop-in configuration file:

```bash
sudo nano /etc/sysctl.d/99-syslog-tuning.conf
```

Add the following content:

```ini
# UDP receive buffers for high-volume syslog ingestion
# These are host-level kernel parameters — not specific to any syslog service.
# Applied by systemd-sysctl.service at boot, or manually via:
#   sysctl -p /etc/sysctl.d/99-syslog-tuning.conf

net.core.rmem_default=16777216
net.core.rmem_max=33554432
net.core.netdev_max_backlog=5000
net.ipv4.udp_mem=8388608 12582912 16777216
```

---

## Applying the Settings

### Apply immediately (no reboot required):

```bash
sudo sysctl -p /etc/sysctl.d/99-syslog-tuning.conf
```

### Or apply individual parameters at runtime:

```bash
sudo sysctl -w net.core.rmem_default=16777216
sudo sysctl -w net.core.rmem_max=33554432
sudo sysctl -w net.core.netdev_max_backlog=5000
sudo sysctl -w net.ipv4.udp_mem="8388608 12582912 16777216"
```

### Verify the settings took effect:

```bash
sysctl net.core.rmem_max
sysctl net.core.rmem_default
sysctl net.core.netdev_max_backlog
sysctl net.ipv4.udp_mem
```

---

## Persistence

Settings placed in `/etc/sysctl.d/` are applied automatically at boot by
`systemd-sysctl.service` on all modern systemd-based distributions. No additional
configuration is required.

For non-systemd distributions (e.g. Alpine with OpenRC), add an explicit call in
your init scripts:

```bash
sysctl -p /etc/sysctl.d/99-syslog-tuning.conf
```

---

## Compatibility

These parameters have been part of the Linux kernel for many years and are supported
on all distributions capable of running Docker.

| Parameter | Available Since |
|---|---|
| `net.core.rmem_default` / `rmem_max` | Kernel 2.2+ |
| `net.core.netdev_max_backlog` | Kernel 2.4+ |
| `net.ipv4.udp_mem` | Kernel 2.6.25+ |

Docker itself requires kernel 3.10 minimum (4.x+ recommended), so all four
parameters are guaranteed to be available on any valid Docker host.

| Distribution Family | Examples | Supported |
|---|---|---|
| Debian / Ubuntu | Ubuntu 18.04+, Debian 9+ | Yes |
| RHEL / CentOS | RHEL 7+, AlmaLinux, Rocky Linux | Yes |
| Fedora / SUSE | Fedora 30+, openSUSE Leap, SLES | Yes |
| Alpine | Alpine 3.x | Yes |
| Arch | Arch Linux, Manjaro | Yes |
| Windows (native) | — | No (different network stack) |
| macOS | — | No (BSD kernel, different sysctl namespace) |
| Docker Desktop (Mac/Win) | — | Applies inside the Linux VM only |

---

## Important Notes

- These settings apply **globally** to the host. All UDP traffic on the host benefits from the larger buffers.
- If the host also runs a local syslog daemon (e.g. `rsyslog` for OS logging), it
  will benefit from these settings too — this is harmless.
- UDP has **no flow control**. If the receive buffer fills before the kernel can
  process packets, excess packets are **silently dropped** with no notification to
  the sender. Correctly sizing these buffers is the primary defence against silent
  log loss under burst conditions.
- These settings survive container restarts and image updates — they are applied at
  the host OS level and are independent of the container lifecycle.
