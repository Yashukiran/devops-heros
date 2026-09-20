# Docker Networking & Volumes — Homework

**Environment:** WSL2 (Ubuntu) on Windows, Docker Engine

---

## Task 1 — Container networking

### Commands

```bash
docker network create frontend-net
docker network create backend-net
docker network create database-net

docker run -d --name frontend --network frontend-net nginx:alpine
docker run -d --name backend  --network backend-net  alpine:latest sleep 3600
docker run -d --name database --network database-net -e MYSQL_ROOT_PASSWORD=root123 mysql:8.0

# put backend on two more networks
docker network connect frontend-net backend
docker network connect database-net backend
```

### Connectivity results

| From | To | Result |
|---|---|---|
| backend | frontend | ✅ works — shares frontend-net |
| backend | database | ✅ works — shares database-net |
| frontend | database | ❌ `bad address 'database'` — no shared network |

### What I understood

The part that surprised me is that containers on a user-defined network can reach each other **by container name**. `ping database` works without knowing any IP, because Docker runs an internal DNS resolver that maps container names to their current IPs. That matters because container IPs change every time they restart — names don't.

This only works on user-defined networks. The default `bridge` network doesn't do name resolution, so you'd be stuck using IPs there.

A container can be attached to several networks at once, which is what `docker network connect` does. That gives you real isolation: my backend can talk to both the frontend and the database, but the frontend cannot reach the database at all. Nothing is blocking it with a firewall rule — they simply have no network in common, so the name doesn't even resolve.

That's a genuinely useful pattern. In a real app you don't want your public-facing web tier to be able to reach the database directly; it should have to go through the backend. Network separation enforces that at the infrastructure level rather than relying on application code to behave.

---

## Task 2 — Host network

```bash
docker pull httpd:2.4
docker run -d --name apache-host --network host httpd:2.4
curl http://localhost:80
```

### What I understood

With `--network host` the container skips Docker's virtual network entirely and uses the host's network stack directly. So Apache binding to port 80 inside the container means it's on the host's port 80 — no `-p` flag, and `docker ps` shows no port mapping at all.

The trade-off is losing isolation. The container can see every network interface on the host, and because there's no mapping layer, two containers both wanting port 80 will collide. With bridge networking I could map them to 8081 and 8082 and run both.

Host networking is mainly for performance — there's no NAT translation on every packet — or when a service needs to see the real client IP rather than Docker's gateway address.

One limitation worth noting: `--network host` only works properly on Linux. On Docker Desktop for Windows and Mac, Docker runs inside a Linux VM, so "host" means the VM rather than my actual machine. I ran this with Docker Engine directly in WSL.

---

## Task 3 — Bind mount

```bash
mkdir ~/docker-bindmount && cd ~/docker-bindmount
echo "<h1>Hello students</h1>" > index.html

docker run -d --name nginx-bind -p 8085:80 \
  -v ~/docker-bindmount:/usr/share/nginx/html \
  nginx:alpine
```

Then editing `index.html` on my machine and refreshing the browser showed the new content immediately, with no restart and the same container ID in `docker ps`.

### What I understood

`-v <host-path>:<container-path>` maps a folder on my machine into the container. It isn't a copy — it's the *same* directory seen from both sides. So changes flow in both directions instantly.

This is the opposite of `COPY` in a Dockerfile. `COPY` bakes files into the image at build time, so changing a file means rebuilding the image and recreating the container. With a bind mount the files live outside the image entirely.

That's exactly why bind mounts are the standard setup for local development — edit code, refresh, see the change, no rebuild cycle. It also means the data survives the container: `docker rm` destroys the container but my `index.html` is still sitting in my home directory.

### Bind mounts vs volumes

| | Bind mount | Named volume |
|---|---|---|
| Location | A path I choose on the host | Managed by Docker in `/var/lib/docker/volumes` |
| Syntax | `-v /home/me/app:/app` | `-v myvolume:/app` |
| Best for | Development — live editing | Production — databases, persistent data |
| Portable | No, depends on my folder layout | Yes, Docker handles it |

Rough rule: bind mount when *I* need to see and edit the files, named volume when only the container cares about them.

---

## Task 4 — Overlay networks

*(Research task — no commands run.)*

### What I understood

Everything above works on one Docker host. A **bridge** network connects containers on a single machine. An **overlay** network connects containers running on *different* machines, making them behave as if they were on one network.

It works by encapsulating container traffic inside packets sent between the hosts — a VXLAN tunnel over the physical network. Each container still gets an IP on the overlay's subnet and can still resolve other containers by name, even though the container it's talking to is physically on a different server.

Overlay networks need an orchestrator to coordinate them — Docker Swarm or Kubernetes. They also need a key-value store so every host agrees on which container has which IP; in Swarm mode Docker handles that itself.

### Where you'd use one

- A service scaled across several machines, needing one flat network
- Microservices spread over a cluster, still addressing each other by name
- High availability, where containers can be rescheduled onto a different host without anything needing reconfiguration

### Why it matters

It's the piece that makes containers work beyond a single laptop. Once you have more than one server, something has to make a container on host A able to reach a container on host B by name — that's the overlay. Docker also encrypts overlay traffic between hosts if you ask it to, which matters when the packets cross a real network.

---

## Network types summary

| Type | Scope | Use case |
|---|---|---|
| `bridge` | Single host | Default; isolated container networking |
| `host` | Single host | Max performance, no isolation |
| `none` | Single host | No networking at all |
| `overlay` | Multiple hosts | Swarm / Kubernetes clusters |
| `macvlan` | Single host | Container gets a real IP on the physical LAN |

## Commands reference

| Command | Purpose |
|---|---|
| `docker network ls` | List networks |
| `docker network create <name>` | Create a network |
| `docker network connect <net> <container>` | Attach a running container |
| `docker network disconnect <net> <container>` | Detach |
| `docker network inspect <name>` | Details and connected containers |
| `docker run --network <name>` | Start on a specific network |
| `docker run -v <host>:<container>` | Bind mount |
| `docker exec <container> ping <name>` | Test connectivity by name |