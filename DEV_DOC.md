# Developer Documentation (DEV_DOC.md)

This document provides technical instructions for developers and contributors to set up, build, develop, test, and manage the Inception project from scratch.

---

## 1. Environment Setup from Scratch

### Prerequisites
* **Operating System**: Linux (Debian/Ubuntu recommended) inside a virtual machine or physical host.
* **Core Software**:
  * `docker` (v20.10+ / Docker Engine)
  * `docker compose` (v2.0+)
  * `make`
  * `curl` and `openssl`
* **Network Permissions**: Ensure user belongs to the `docker` group (`sudo usermod -aG docker $USER`) to run Docker commands without `sudo`.

### Domain Name Configuration
Map the project domain to localhost:
```bash
echo "127.0.0.1 aelbouss.42.fr" | sudo tee -a /etc/hosts
```

### Configuration Files Setup
Copy the environment template:
```bash
cp srcs/.env.example srcs/.env
```
Ensure `srcs/.env` defines all required runtime parameters:
```ini
DOMAIN_NAME=aelbouss.42.fr

DB_NAME=wp_db
DB_USER=Flex
MYSQL_HOST=mariadb

WP_USER=morgan
WP_ADMIN_NAME=surprise

WP_TITLE=Inception
WP_URL=https://aelbouss.42.fr

WP_USER_EMAIL=flex@student.42.fr
WP_ADMIN_EMAIL=admin@aelbouss.42.fr

FTP_USER=ramon
FTP_GROUP=ramons
FTP_DATA=/var/www/html
```

### Secrets Setup
Docker Secrets are loaded from files located in `secrets/` outside the `srcs/` directory. Create the directory and supply initial passwords:
```bash
mkdir -p secrets

echo "your_root_db_password" > secrets/db_root_password.txt
echo "your_db_password"      > secrets/db_password.txt
echo "your_wp_admin_password"> secrets/wp_admin_password.txt
echo "your_wp_user_password" > secrets/wp_user_password.txt
echo "your_ftp_password"     > secrets/ftp_user_password.txt

chmod 600 secrets/*.txt
```

---

## 2. Building and Launching the Infrastructure

The build and deployment workflow is standardized via the root `Makefile`:

### Build & Run
```bash
make
```
This triggers:
1. Creation of persistent host directories:
   * `/home/${USER}/data/mariadb`
   * `/home/${USER}/data/wordpress`
   * `/home/${USER}/data/portainer`
2. Execution of `docker compose -f srcs/docker-compose.yml up --build -d`.
3. Self-building of every individual container image from source (`Dockerfile` based on `debian:bookworm`).
4. Network attachment to the isolated bridge network (`inception`).

### Useful Makefile Targets
| Target | Command | Purpose |
|---|---|---|
| `make` / `make all` | `docker compose up --build -d` | Builds and launches all services in detached mode |
| `make up` | `docker compose up -d --build` | Starts or updates containers |
| `make down` | `docker compose down -v` | Stops and removes containers and networks |
| `make build` | `docker compose build` | Rebuilds container images without starting |
| `make logs` | `docker compose logs -f` | Tails real-time logs from all services |
| `make clean` | `docker compose down --volumes --rmi all` | Tears down containers, volumes, and images |
| `make fclean` | Clean + Volume wipe + System prune | Thorough cleanup of all host volumes and unused Docker objects |
| `make re` | `make fclean && make all` | Complete clean rebuild from zero |

---

## 3. Container and Volume Management

### Inspecting Running Containers
```bash
# List container status, ports, and names
docker compose -f srcs/docker-compose.yml ps

# View live resource metrics (CPU, RAM, Net I/O)
docker stats
```

### Entering Containers for Debugging
```bash
# Enter WordPress container
docker exec -it wordpress /bin/bash

# Enter MariaDB container
docker exec -it mariadb /bin/bash

# Enter NGINX container
docker exec -it nginx /bin/bash
```

### Managing Specific Services
```bash
# Rebuild and restart a single service
docker compose -f srcs/docker-compose.yml up -d --build <service_name>

# Restart a service
docker compose -f srcs/docker-compose.yml restart <service_name>

# View logs for a single service
docker compose -f srcs/docker-compose.yml logs -f <service_name>
```

### Managing Volumes
```bash
# List all Docker volumes
docker volume ls

# Inspect specific volume
docker volume inspect srcs_mariadb_data
docker volume inspect srcs_wordpress_data
docker volume inspect srcs_portainer_data
```

---

## 4. Data Storage and Persistence Architecture

Data persistence strictly complies with the 42 Inception subject requirements:

### Persistence Mechanism
Named volumes configured with local bind drivers mount direct host directories into the containers:

```yaml
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/${USER}/data/mariadb

  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/${USER}/data/wordpress

  portainer_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/${USER}/data/portainer
```

### Host File Locations
* **MariaDB Schema & Tables**: Stored on the host at `/home/${USER}/data/mariadb/`.
  * Preserves user tables, posts, options, and credentials across container reboots.
* **WordPress Core, Uploads & Plugins**: Stored on the host at `/home/${USER}/data/wordpress/`.
  * Shared between `wordpress` (for PHP execution), `nginx` (for static asset serving), and `ftp` (for remote file management).
* **Portainer Configuration & Credentials**: Stored on the host at `/home/${USER}/data/portainer/`.
  * Preserves administrative user and dashboard settings.

### Testing Persistence
To verify data persistence:
1. Access WordPress (`https://aelbouss.42.fr/wp-login.php`) and publish a new post or comment.
2. Stop and remove all containers:
   ```bash
   make down
   ```
3. Verify files remain on host:
   ```bash
   ls -la /home/$USER/data/mariadb
   ls -la /home/$USER/data/wordpress
   ```
4. Restart the stack:
   ```bash
   make up
   ```
5. Refresh `https://aelbouss.42.fr` to confirm the post is still visible.
