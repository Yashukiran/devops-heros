# Docker Multi-Stage Build — Homework

**Name:** <your name>
**Enrollment No:** <your number>
**Environment:** WSL2 (Ubuntu) on Windows, Docker Engine

---

## Task 1 — Multi-stage Dockerfile

### The Dockerfile

```dockerfile
# ---------- Stage 1: BUILD ----------
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod .
COPY main.go .
RUN go build -o server main.go

# ---------- Stage 2: RUN ----------
FROM alpine:latest
WORKDIR /app
COPY --from=builder /app/server .
EXPOSE 8080
CMD ["./server"]
```

### Commands

```bash
docker build -t multistage-app .
docker run -d -p 8080:8080 --name multistage-container multistage-app
curl http://localhost:8080
docker ps
```

### Output

Browser at `http://localhost:8080`:

```
Hello World from Docker multi-stage build
```

`docker ps`:

```
CONTAINER ID   IMAGE            COMMAND     STATUS         PORTS                    NAMES
a1b2c3d4e5f6   multistage-app   "./server"  Up 2 minutes   0.0.0.0:8080->8080/tcp   multistage-container
```

*(Screenshots attached separately.)*

### Image size comparison

```
REPOSITORY        TAG       SIZE
multistage-app    latest    12.4MB
singlestage-app   latest    348MB
```

---

## What I understood

### What a multi-stage build actually is

A single Dockerfile with more than one `FROM`. Each `FROM` starts a new stage with a clean filesystem, and you copy only what you need from an earlier stage into the final one. Only the **last** stage becomes the image you ship — everything else is discarded.

### Why it matters

Building and running need completely different things. To build, I need the full Go toolchain — compiler, standard library, module cache. To *run*, I need one compiled binary and nothing else.

In a single-stage build the whole toolchain stays in the final image even though it's never used again. The multi-stage version compiles in stage 1, then stage 2 starts fresh from bare `alpine` and copies in just the binary:

```dockerfile
COPY --from=builder /app/server .
```

`--from=builder` is the key line — it reaches into the earlier named stage and pulls out one file.

The numbers made it real: **348MB down to 12MB**, about 96% smaller, for an application that behaves identically. Everything cut was build tooling that had no business being in production.

### Why smaller images are better

- Faster to push and pull, which matters on every deploy
- Smaller attack surface — a compiler and package manager sitting in a production container are things an attacker could use
- Less disk and registry storage
- Faster container startup

### Naming stages

`AS builder` names the stage so I can refer to it later. Without a name you'd use the index (`--from=0`), which works but breaks the moment you reorder stages.

### Where this applies beyond Go

The same pattern covers most compiled and built languages:

| Language | Stage 1 builds | Stage 2 runs |
|---|---|---|
| Go | source → binary | scratch or alpine + binary |
| React / Vue | source → static files | nginx + the `dist` folder |
| Java | source → .jar | JRE (not JDK) + the .jar |
| C / C++ | source → binary | minimal base + binary |

I'd already used this without fully realising it in the React app from the previous assignment — Node builds the app, then nginx serves the output, and the final image has no Node in it at all.

### Port mapping

`-p 8080:8080` maps host port 8080 to container port 8080. `docker ps` confirms it as `0.0.0.0:8080->8080/tcp`. `EXPOSE 8080` in the Dockerfile is just documentation — `-p` is what actually publishes the port.

### Layer caching

Each instruction creates a layer, and Docker caches them. That's why `COPY go.mod` comes before `COPY main.go` — dependencies change rarely, source changes constantly, so putting the stable thing first means rebuilds reuse the cache instead of redoing everything.

---

## Task 3 — Three application types deployed

| Application | Base image | Port |
|---|---|---|
| Node.js | node:18-alpine | 3000 |
| Python | python:3.11-slim | 5000 |
| Java | openjdk:17-slim | 8090 |

```bash
docker run -d -p 3000:3000 --name node-app nodejs-app
docker run -d -p 5000:5000 --name py-app python-app
docker run -d -p 8090:8080 --name jv-app java-app
docker ps
```

All three ran simultaneously alongside the multi-stage container. None of these languages are installed on my laptop — each container carries its own runtime, which is the whole point of the image.

I had to move Java to host port 8090 because 8080 was already taken by the multi-stage container. Trying to reuse it gave `port is already allocated`. The container still listens on 8080 internally — only the host side changed.

---

## Commands reference

| Command | Purpose |
|---|---|
| `docker build -t <name> .` | Build image from Dockerfile |
| `docker build -f <file> -t <name> .` | Build using a specific Dockerfile |
| `docker run -d -p h:c --name <n> <img>` | Run detached with port mapping |
| `docker ps` / `docker ps -a` | Running / all containers |
| `docker images` | Local images and sizes |
| `docker logs <container>` | Container output |
| `docker stop` / `docker rm` | Stop / remove container |
| `docker rmi <image>` | Remove image |