# Inception

A multi-container infrastructure engineered in a virtual machine using Docker and Docker Compose, developed for the **42 Network** curriculum.

---

## Architecture Overview

All services run inside dedicated, custom-built containers based on **Debian Bookworm** connected through an isolated Docker bridge network (`inception`). Only NGINX (port 443) and Adminer (port 8080) are exposed to the host machine.

```text
                        ┌──────────────────────────────────────────────┐
                        │                 HOST MACHINE                 │
                        │           Domain: aelbouss.42.fr             │
                        └──────────────┬───────────────────────────────┘
                                       │
                        HTTPS (443)    │    HTTP (8080)
                    ┌──────────────────┴──────────────────┐
                    │                                     │
                    ▼                                     ▼
        ┌───────────────────────┐             ┌───────────────────────┐
        │   NGINX (TLS 1.2/1.3) │             │     Adminer (Web)     │
        └───────────┬───────────┘             └───────────┬───────────┘
                    │ FastCGI (9000)                      │ MySQL (3306)
                    ▼                                     │
        ┌───────────────────────┐                         │
        │   WordPress + PHP-FPM │                         │
        └───────┬───────────────┴─────────────────────────┤
                │ Redis (6379)                            │
                ▼                                         ▼
    ┌───────────────────────┐                 ┌───────────────────────┐
    │      Redis Cache      │                 │        MariaDB        │
    └───────────────────────┘                 └───────────┬───────────┘
                                                          │
                                                          ▼
                                            Volume: /home/${USER}/data/mariadb
```

### Services Summary

| Service | Base Image | Exposed Port | Purpose |
|---|---|---|---|
| **NGINX** | Debian Bookworm | `443` (TLS) | Sole entrypoint with TLSv1.2/1.3 encrypted HTTPS proxy |
| **WordPress** | Debian Bookworm | None (`9000` internal) | Core WordPress engine running FastCGI PHP-FPM 8.2 |
| **MariaDB** | Debian Bookworm | None (`3306` internal) | Relational database containing WordPress schema |
| **Redis** | Debian Bookworm | None (`6379` internal) | In-memory object caching for WordPress queries (Bonus) |
| **Adminer** | Debian Bookworm | `8080` (Host) | Web-based database management interface (Bonus) |
| **FTP** | Debian Bookworm | `21`, `30000-30009` | File Transfer Protocol server targeting WordPress volume (Bonus) |
| **Static Site** | Debian Bookworm | None (`8080` internal) | Dedicated Python 3 HTTP server hosting static resume page (Bonus) |

---

## Getting Started

### 1. Prerequisites

Ensure your `/etc/hosts` file maps the required domain name to your local machine:

```bash
echo "127.0.0.1 aelbouss.42.fr" | sudo tee -a /etc/hosts
```

### 2. Environment Configuration

Copy the example environment file:

```bash
cp srcs/.env.example srcs/.env
```

Create your Docker Secrets directory and password files:

```bash
mkdir -p secrets
echo "your_db_password" > secrets/db_password.txt
echo "your_db_root_password" > secrets/db_root_password.txt
echo "your_wp_admin_password" > secrets/wp_admin_password.txt
echo "your_wp_user_password" > secrets/wp_user_password.txt
```

---

## Makefile Commands

| Command | Description |
|---|---|
| `make` / `make all` | Creates volume directories, builds all images, and starts containers in detached mode |
| `make up` | Starts containers with `--build` |
| `make down` | Stops and removes running containers and volumes |
| `make build` | Builds or rebuilds images without launching them |
| `make logs` | Follows real-time logs from all running containers |
| `make clean` | Stops containers and deletes project images and volumes |
| `make fclean` | Thorough cleanup: stops containers, empties host data volumes, and removes all unused Docker objects |
| `make re` | Performs `fclean` followed by a fresh `all` build |

---

## Verification & Evaluation Testing

### 1. Accessing the Services
* **WordPress Website**: `https://aelbouss.42.fr`
* **WordPress Admin Login**: `https://aelbouss.42.fr/wp-login.php`
* **Adminer Web Interface**: `http://localhost:8080` *(Server: `mariadb`, Database: `wp_db`)*

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
Check active connection and live cache hits:
```bash
# Check connection status via WP-CLI
docker exec wordpress su -s /bin/sh www-data -c "wp --path=/var/www/html redis status"

# Stream live Redis operations while browsing the site
docker exec redis redis-cli monitor
```

### 4. Validating FTP Service
Test connecting, listing, and uploading files to `/var/www/html`:
```bash
# List WordPress files via FTP
curl -s -u ramon:waaa@ftp@hhh ftp://127.0.0.1/

# Test uploading a file
echo "Hello 42" > test.txt
curl -s -u ramon:waaa@ftp@hhh -T test.txt ftp://127.0.0.1/
```

### 5. Validating Static Website Service
Test accessing the isolated static resume site through the NGINX TLS reverse proxy:
```bash
# Verify the static site is served over HTTPS
curl -k -s https://aelbouss.42.fr/resume/ | grep -i "Anass Alboussaili"
```

### 6. Data Persistence Test
1. Log in to WordPress admin, publish a test post or comment.
2. Run `make down` to stop all containers.
3. Run `make up` to restart.
4. Refresh `https://aelbouss.42.fr` to verify the new post/comment persisted on host volumes at `/home/${USER}/data/`.
