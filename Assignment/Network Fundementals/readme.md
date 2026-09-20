# Networking Fundamentals — Homework

**Environment:** WSL2 (Ubuntu) on Windows

Most of these tools aren't installed in WSL by default, so first:

```bash
sudo apt install -y net-tools dnsutils traceroute iputils-ping curl wget
```

---

## 1. `ip a`

```bash
ip a
```

Lists every network interface with its IP, MAC address and state.

**What I understood:** This is the modern replacement for `ifconfig`. `lo` is the loopback interface (127.0.0.1) that the machine uses to talk to itself. `eth0` is the real interface with the actual IP. The `/20` or `/24` after the IP is the subnet mask in CIDR form — it says how many bits are the network portion and how many identify the host.

---

## 2. `ifconfig`

```bash
ifconfig
```

Shows the same interface information in the older format.

**What I understood:** Deprecated but still everywhere in older docs and tutorials. It shows RX/TX packet counts, which is handy for spotting whether an interface is actually passing traffic. It isn't installed by default any more — you need the `net-tools` package.

---

## 3. `hostname -I` and `ip route`

```bash
hostname -I
ip route
```

**What I understood:** `hostname -I` is the quickest way to get just the IP, with no parsing. `ip route` shows the routing table — the `default via <gateway>` line is the most important one, since that's where traffic goes when the destination isn't on the local network. Without a default route you can reach your LAN but not the internet.

---

## 4. `ping`

```bash
ping -c 4 google.com
ping -c 4 8.8.8.8
```

**What I understood:** `ping` sends ICMP echo requests and measures the round-trip time. On Linux it runs forever unless you give it `-c`, unlike Windows where it stops after four.

The useful trick is running it against both a domain and a raw IP. If `ping 8.8.8.8` works but `ping google.com` fails, the network is fine and the problem is DNS. That single comparison narrows the fault down immediately.

The output also shows packet loss and min/avg/max times, so you can tell a slow connection from a broken one.

---

## 5. `traceroute`

```bash
traceroute google.com
```

**What I understood:** Shows every router hop between me and the destination, with timing for each. It works by sending packets with an increasing TTL so each router in turn drops one and reports back.

Useful for finding *where* a connection slows down or dies rather than just knowing that it did. Some hops show `* * *` because those routers are configured not to reply — that's normal, not a failure.

---

## 6. `nslookup` and `dig`

```bash
nslookup google.com
dig google.com +short
dig google.com
```

**What I understood:** Both resolve a domain to an IP, but `dig` gives far more detail. Its output is split into sections — QUESTION (what was asked), ANSWER (the records returned), and stats including which DNS server replied and how long it took.

`+short` strips everything down to just the IP, which is what you'd use inside a script.

The TTL value in the answer is how long the result can be cached before it must be looked up again. That's why DNS changes take time to propagate.

---

## 7. `/etc/resolv.conf` and `/etc/hosts`

```bash
cat /etc/resolv.conf
cat /etc/hosts
```

**What I understood:** `/etc/resolv.conf` lists the DNS servers the system will query. `/etc/hosts` is a manual name-to-IP mapping file that gets checked **before** DNS — so you can point a domain anywhere locally, which is how people test sites before changing real DNS records.

On WSL, `/etc/resolv.conf` is auto-generated and points at a Windows-side address, since WSL routes DNS through the host.

---

## 8. `netstat` and `ss`

```bash
netstat -tuln
ss -tuln
ss -s
```

**What I understood:** Both list network connections and listening ports. The flags read as: `-t` TCP, `-u` UDP, `-l` only listening, `-n` show numbers instead of resolving names to service names.

`ss` is the newer and faster tool — `netstat` is deprecated but still what most tutorials use. `ss -s` gives a summary count of connections by state.

This is what you'd run to answer "is my service actually listening, and on which port?" A service that's running but not listed here isn't bound properly.

The address column matters too: `0.0.0.0:80` means listening on every interface, while `127.0.0.1:80` means local connections only.

---

## 9. `curl` and `wget`

```bash
curl -I https://www.google.com
curl https://api.github.com/users/octocat
wget -q -O test.html https://example.com
```

**What I understood:** `curl -I` fetches only the response headers, so you can check whether a site is up and what status code it returns without downloading the page. The first line gives `HTTP/2 200` or whatever the status is.

Without `-I` it prints the full body, which is how you'd hit an API from the terminal.

`wget` is for downloading files — `-O` sets the output filename, `-q` keeps it quiet. The rough split is that `curl` is for talking to APIs and inspecting responses, `wget` is for grabbing files.

---

## 10. `arp -a` and `hostname`

```bash
arp -a
hostname
hostname -f
```

**What I understood:** ARP maps IP addresses to MAC addresses on the local network. `arp -a` shows the cached entries — the devices this machine has recently talked to on the LAN. It only ever covers the local network, since MAC addresses don't travel past a router.

`hostname` is the machine name, `hostname -f` gives the fully qualified version with the domain if one is set.

---

## Summary

| Command | Purpose |
|---|---|
| `ip a` / `ifconfig` | Interfaces and IP addresses |
| `ip route` | Routing table, default gateway |
| `hostname -I` | Just the IP |
| `ping -c 4` | Test reachability and latency |
| `traceroute` | Show the path, hop by hop |
| `nslookup` / `dig` | DNS resolution |
| `netstat -tuln` / `ss -tuln` | Listening ports and connections |
| `curl -I` | HTTP headers / status |
| `wget` | Download files |
| `arp -a` | Local IP-to-MAC table |
| `/etc/hosts` | Manual DNS override |
| `/etc/resolv.conf` | Configured DNS servers |

## What I took away

The thing that stuck most was using `ping google.com` versus `ping 8.8.8.8` to separate a DNS problem from a connectivity problem. It's a two-second test that tells you which half of the stack to look at.

The other one was `ss -tuln`. Knowing whether a service is actually bound to a port, and to which interface, seems like it'll come up constantly once we start running things in Docker.

WSL does have some limits here — `traceroute` behaves oddly because traffic goes through the Windows host, and `/etc/resolv.conf` is managed by WSL rather than by me.