*This project has been created as part of the 42 curriculum by aelbouss.*

# Inception

A secure, multi-container system administration infrastructure engineered inside a virtual machine using Docker and Docker Compose for the **42 Network** curriculum.

---

## Description

The goal of the **Inception** project is to broaden systems administration and DevOps knowledge through containerization. The infrastructure orchestrates a complete web application stack adhering to strict microservice isolation rules: each service runs in a dedicated container built from custom Dockerfiles based on **Debian Bookworm**, without using ready-made application images from Docker Hub.

Traffic is strictly routed through an NGINX reverse proxy on port 443 with modern TLS encryption, protecting internal application components (WordPress via PHP-FPM, MariaDB, and Redis) from direct external exposure.

### Key Design Choices
1. **Debian Bookworm Base**: Uniform base distribution across all services ensures compatibility, stability, and security package consistency.
2. **Strict Microservice Isolation**: Each service runs as PID 1 (or managed cleanly via an initialization entrypoint script) without daemon hacks (`sleep infinity`, `tail -f`, or background loops).
3. **Internal Network Segmentation**: Containers communicate exclusively over a user-defined Docker bridge network (`inception`) through internal DNS names; internal ports (FastCGI `9000`, MySQL `3306`, Redis `6379`) are never published to the host.
4. **Decoupled Data Persistence**: Application and database states are decoupled from container lifecycles by mounting dedicated named volumes tied to `/home/aelbouss/data/`.

---

### Technical Comparisons

#### 1. Virtual Machines vs. Docker
* **Virtual Machines**: Virtualize hardware through a hypervisor (Type 1 or Type 2). Each VM runs a complete guest operating system, including its own kernel, device drivers, and system services. This provides high isolation but results in significant resource overhead, large disk footprints (gigabytes), and slow boot times (minutes).
* **Docker Containers**: Virtualize at the operating system level by sharing the host Linux kernel. Containers leverage Linux kernel primitives (**cgroups** for resource limits and **namespaces** for process, network, and mount isolation). They are lightweight (megabytes), share host resources dynamically, and boot in milliseconds.

#### 2. Secrets vs. Environment Variables
* **Environment Variables**: Passed into container processes via `docker-compose.yml` or `.env`. While convenient for non-sensitive configuration (hostnames, database names, ports), they are insecure for credentials because they persist in plain text, can be read via `docker inspect`, and leak in child processes, system crash dumps, or error logs.
* **Docker Secrets**: Securely mount confidential data (passwords, certificates, keys) into container memory filesystems (typically under `/run/secrets/`). They are never written to disk within the image, do not appear in `docker inspect`, and prevent sensitive credentials from being committed to source control.

#### 3. Docker Network vs. Host Network
* **Host Network (`network_mode: host`)**: The container shares the host's networking namespace directly, bypassing Docker's network isolation. While offering marginally lower latency, it creates port collisions with host applications, exposes internal services directly to the outside world, and breaks container network isolation.
* **Docker Network (User-Defined Bridge)**: Creates an isolated, virtual software switch (`inception`). Containers get private IP addresses, can communicate securely across designated ports, and benefit from Docker's automatic internal DNS resolution (e.g. resolving `mariadb` or `wordpress` by service name) without exposing internal services to the host interface.

#### 4. Docker Volumes vs. Bind Mounts
* **Bind Mounts**: Directly mount a specific directory or file from the host filesystem into the container (e.g., `/path/on/host:/path/in/container`). Behavior depends on host directory structure, OS permissions, and UID/GID mapping, making them less portable across different environments.
* **Docker Volumes**: Completely managed by the Docker engine (residing in `/var/lib/docker/volumes/`). They are isolated from host filesystem mechanics, easier to back up, migrate, and share safely between multiple containers. In Inception, named volumes are paired with local bind options to ensure both Docker volume management and explicit storage under `/home/${USER}/data/`.

---

## Architecture Overview

```text
                        ┌──────────────────────────────────────────────┐
                        │                 HOST MACHINE                 │
                        │           Domain: aelbouss.42.fr             │
                        └──────────────┬───────────────────────────────┘
                                       │
                         HTTPS (443)   │   HTTP (8080)        HTTP (9000)
             ┌─────────────────────────┼─────────────────────┬──────────────┐
             │                         │                     │              │
             ▼                         ▼                     ▼              │
 ┌───────────────────────┐ ┌───────────────────────┐ ┌────────────────────┐ │
 │   NGINX (TLS 1.2/1.3) │ │     Adminer (Web)     │ │     Portainer      │ │
 └───────────┬───────────┘ └───────────┬───────────┘ └────────────────────┘ │
             │                         │                                    │
             │ FastCGI (9000)          │ MySQL (3306)          FTP (21/pasv)│
             ▼                         │                                    ▼
 ┌───────────────────────┐             │                         ┌────────────────────┐
 │  WordPress + PHP-FPM  ├─────────────┤                         │    FTP (vsftpd)    │
 └───────┬───────────────┴─────────────┼─────────────────────────┴──────────┬─────────┘
         │                             │                                    │
         │ Redis (6379)                ▼                                    │
         ▼                 ┌───────────────────────┐                        │
 ┌───────────────┐         │        MariaDB        │                        │
 │  Redis Cache  │         └───────────┬───────────┘                        │
 └───────────────┘                     │                                    │
                                       ▼                                    ▼
                         Volume: /home/${USER}/data/mariadb   Volume: /home/${USER}/data/wordpress
```

### Services Summary

| Service | Base Image | Exposed Port | Purpose |
|---|---|---|---|
| **NGINX** | Debian Bookworm | `443` (TLS) | Sole HTTPS reverse proxy entrypoint using TLS 1.2/1.3 |
| **WordPress** | Debian Bookworm | None (`9000` internal) | Core WordPress engine running FastCGI PHP-FPM 8.2 |
| **MariaDB** | Debian Bookworm | None (`3306` internal) | Relational database containing WordPress schema |
| **Redis** | Debian Bookworm | None (`6379` internal) | In-memory key-value cache for WordPress database queries (Bonus) |
| **Adminer** | Debian Bookworm | `8080` (Host) | Web-based database administration interface (Bonus) |
| **FTP** | Debian Bookworm | `21`, `30000-30009` | File Transfer Protocol server targeting `/var/www/html` (Bonus) |
| **Static Site** | Debian Bookworm | None (`8080` internal) | Dedicated Python 3 HTTP microservice hosting static resume (Bonus) |
| **Portainer** | Debian Bookworm | `9000` (Host) | Web-based container and volume management dashboard (Bonus) |

---

## Instructions

### 1. Prerequisites

1. Add the domain name mapping to your `/etc/hosts`:
   ```bash
   echo "127.0.0.1 aelbouss.42.fr" | sudo tee -a /etc/hosts
   ```

2. Configure environment variables by copying the template:
   ```bash
   cp srcs/.env.example srcs/.env
   ```

3. Create the `secrets/` directory and populate your password files:
   ```bash
   mkdir -p secrets
   echo "your_db_password"       > secrets/db_password.txt
   echo "your_db_root_password"  > secrets/db_root_password.txt
   echo "your_wp_admin_password" > secrets/wp_admin_password.txt
   echo "your_wp_user_password"  > secrets/wp_user_password.txt
   echo "your_ftp_password"      > secrets/ftp_user_password.txt
   chmod 600 secrets/*.txt
   ```

### 2. Compilation and Execution (Makefile)

| Command | Description |
|---|---|
| `make` / `make all` | Creates volume directories, builds all images, and starts containers |
| `make up` | Starts or updates containers with `--build` |
| `make down` | Stops and removes running containers and networks |
| `make build` | Builds or rebuilds images without launching them |
| `make logs` | Streams live logs from all running containers |
| `make clean` | Stops containers and deletes project images and volumes |
| `make fclean` | Thorough cleanup: stops containers, wipes data volumes, and prunes unused objects |
| `make re` | Performs `fclean` followed by a fresh `make all` build |

---

## Verification & Evaluation Testing

### 1. Accessing the Services
* **WordPress Website**: `https://aelbouss.42.fr`
* **WordPress Admin Login**: `https://aelbouss.42.fr/wp-login.php`
* **Static Resume Website**: `https://aelbouss.42.fr/resume/`
* **Adminer Web Interface**: `http://localhost:8080` *(Server: `mariadb`, Database: `wp_db`)*
* **Portainer Web Dashboard**: `http://localhost:9000`

### 2. Validating TLS Encryption
Verify that only modern TLS protocols (1.2 and 1.3) are accepted:
```bash
# Must succeed (HTTP 200 OK)
curl -k --tlsv1.3 -sI https://aelbouss.42.fr
curl -k --tlsv1.2 -sI https://aelbouss.42.fr

# Must fail / be rejected
curl -k --tlsv1.1 --tls-max 1.1 -sI https://aelbouss.42.fr

# Unencrypted HTTP (Port 80) must be closed
curl -I http://aelbouss.42.fr:80
```

### 3. Validating Redis Object Cache
```bash
# Check connection status via WP-CLI
docker exec wordpress su -s /bin/sh www-data -c "wp --path=/var/www/html redis status"

# Stream live Redis operations
docker exec redis redis-cli monitor
```

### 4. Validating FTP Service
```bash
# List WordPress files via FTP
curl -s -u ramon:waaa@ftp@hhh ftp://127.0.0.1/

# Test uploading a file
echo "Hello 42" > test.txt
curl -s -u ramon:waaa@ftp@hhh -T test.txt ftp://127.0.0.1/
```

### 5. Validating Static Website Service
```bash
# Verify the static site is served over HTTPS via reverse proxy
curl -k -s https://aelbouss.42.fr/resume/ | grep -i "Anass Alboussaili"
```

### 6. Data Persistence Test
1. Log in to WordPress admin, publish a test post or comment.
2. Run `make down` to stop all containers.
3. Run `make up` to restart.
4. Refresh `https://aelbouss.42.fr` to verify data persisted on host volumes at `/home/${USER}/data/`.

---

## Resources

### Documentation & References
* [Docker Documentation](https://docs.docker.com/) — Multi-stage builds, Dockerfile best practices, and Docker Compose specification.
* [NGINX Reverse Proxy Guide](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/) — TLS termination, FastCGI proxying, and location matching.
* [WordPress Developer Handbook](https://developer.wordpress.org/cli/commands/) — WP-CLI automation and unattended setup.
* [vsftpd Official Manual](http://vsftpd.beasts.org/vsftpd_conf.html) — Secure FTP daemon configuration and passive mode settings.
* [Portainer CE Documentation](https://docs.portainer.io/) — Deployment and socket communication.

### AI Usage Declaration
Artificial Intelligence was consulted during the development of this project for the following tasks:
* **Architecture Design Review**: Clarifying Docker microservice boundaries, volume bind configurations, and evaluation compliance.
* **Troubleshooting Configuration Errors**: Diagnosing `vsftpd` passive mode Docker port-forwarding issues and resolving volume bind permissions.
* **Documentation Structuring**: Generating comprehensive markdown templates for `USER_DOC.md`, `DEV_DOC.md`, and technical comparisons adhering to 42 Inception subject requirements.
