# User Documentation (USER_DOC.md)

This document explains in clear and simple terms how an end user or system administrator can operate, access, configure, and verify the Inception multi-container infrastructure stack.

---

## 1. Services Provided by the Stack

The infrastructure consists of dedicated, isolated microservices running inside Docker containers:

| Service | Category | Endpoint / Port | Purpose |
|---|---|---|---|
| **NGINX** | Gateway / Reverse Proxy | `https://aelbouss.42.fr` (Port `443` TLS) | The sole public entry point into the web stack, securing all traffic with TLS 1.2/1.3 encryption. |
| **WordPress** | Application | Internal (FastCGI Port `9000`) | Content Management System running PHP-FPM 8.2 serving the blog. |
| **MariaDB** | Database | Internal (MySQL Port `3306`) | Relational database engine storing all WordPress tables, posts, and user data. |
| **Redis** | In-Memory Cache *(Bonus)* | Internal (Port `6379`) | High-speed cache reducing database load by caching WordPress database queries. |
| **Adminer** | DB Management *(Bonus)* | `http://localhost:8080` (Port `8080`) | Lightweight web-based graphical interface for administering the MariaDB database. |
| **FTP Server** | File Transfer *(Bonus)* | `ftp://127.0.0.1` (Ports `21`, `30000-30009`) | Secure vsftpd server granting direct file access to the WordPress `/var/www/html` volume. |
| **Static Website** | Portfolio *(Bonus)* | `https://aelbouss.42.fr/resume/` | Isolated Python 3 HTTP microservice hosting a static software engineering resume. |
| **Portainer** | Container Admin *(Bonus)* | `http://localhost:9000` (Port `9000`) | Centralized web management dashboard to monitor containers, volumes, and logs. |

---

## 2. Starting and Stopping the Project

All container lifecycle operations are orchestrated using the `Makefile` located at the root of the repository:

### Starting the Stack
To create the necessary volume storage directories, build all Docker images, and start the containers in detached mode:
```bash
make
# or
make up
```

### Stopping the Stack
To cleanly stop and remove running containers while keeping persistent data intact:
```bash
make down
```

### Viewing Real-Time Logs
To follow live log output from all services:
```bash
make logs
```
To follow logs for a specific service:
```bash
docker compose -f srcs/docker-compose.yml logs -f <service_name>
# Examples:
docker compose -f srcs/docker-compose.yml logs -f nginx
docker compose -f srcs/docker-compose.yml logs -f wordpress
```

### Resetting & Rebuilding
* **Clean images and volumes**:
  ```bash
  make clean
  ```
* **Full factory reset** (deletes images, volumes, and host data directories):
  ```bash
  make fclean
  ```
* **Rebuild everything from scratch**:
  ```bash
  make re
  ```

---

## 3. Accessing Websites and Administration Panels

Ensure your host `/etc/hosts` contains the domain mapping:
```text
127.0.0.1 aelbouss.42.fr
```

### Web Applications
* **WordPress Website**:
  Navigate to: `https://aelbouss.42.fr`
* **WordPress Admin Login Panel**:
  Navigate to: `https://aelbouss.42.fr/wp-login.php`
* **Static Resume Page**:
  Navigate to: `https://aelbouss.42.fr/resume/`

### Administrative Dashboards
* **Adminer (Database Management)**:
  * Open: `http://localhost:8080`
  * System: `MySQL`
  * Server: `mariadb`
  * Username: `Flex` (or database user defined in `.env`)
  * Password: Located in `secrets/db_password.txt`
  * Database: `wp_db`
* **Portainer (Container Dashboard)**:
  * Open: `http://localhost:9000`
  * On initial setup, create an administrative user with a strong password (minimum 12 characters).
  * Connect to the **Local** environment to inspect all containers, CPU/RAM usage, volumes, and network activity.

### FTP File Management
Connect using an FTP client (FileZilla) or command line:
* **Host**: `127.0.0.1`
* **Port**: `21`
* **User**: `ramon`
* **Password**: Located in `secrets/ftp_user_password.txt`
* **Directory**: Confined directly to `/var/www/html`

---

## 4. Locating and Managing Credentials

Security best practices mandate separating environment configuration from sensitive secrets.

### Public Configuration Variables (`srcs/.env`)
Non-sensitive configuration is stored in `srcs/.env`:
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

### Sensitive Credentials (`secrets/`)
Confidential passwords are stored in individual files inside the `secrets/` directory and mounted securely via Docker Secrets:
* `secrets/db_root_password.txt`: MariaDB `root` administrative password.
* `secrets/db_password.txt`: Password for standard database user `Flex`.
* `secrets/wp_admin_password.txt`: WordPress Administrator (`surprise`) login password.
* `secrets/wp_user_password.txt`: Standard WordPress Author (`morgan`) login password.
* `secrets/ftp_user_password.txt`: FTP user (`ramon`) password.

> [!NOTE]
> Never commit actual passwords or the `secrets/` files to Git. A `.gitignore` file is configured to exclude sensitive files.

### Rotating Passwords
To change any password:
1. Update the corresponding file in `secrets/`.
2. Re-run `make up` to restart the containers with the updated secrets.

---

## 5. Checking Service Health and Status

### Check Container Status
Verify that all 8 containers are running:
```bash
docker compose -f srcs/docker-compose.yml ps
```
Every container should report a state of `Up`.

### Validate TLS Security (NGINX)
Ensure that only secure protocols are accepted:
```bash
# Must succeed (HTTP 200 OK)
curl -k --tlsv1.3 -sI https://aelbouss.42.fr
curl -k --tlsv1.2 -sI https://aelbouss.42.fr

# Must fail / be rejected (TLS 1.0 / 1.1 are prohibited)
curl -k --tlsv1.1 --tls-max 1.1 -sI https://aelbouss.42.fr

# Port 80 (HTTP) must be closed
curl -I http://aelbouss.42.fr:80
```

### Validate Redis Object Cache
Verify Redis caching is actively functioning:
```bash
# Check status through WP-CLI
docker exec wordpress su -s /bin/sh www-data -c "wp --path=/var/www/html redis status"

# Stream Redis commands in real-time
docker exec redis redis-cli monitor
```

### Validate FTP Functionality
Verify FTP listing and upload permissions:
```bash
# List files
curl -s -u ramon:waaa@ftp@hhh ftp://127.0.0.1/

# Test upload
echo "Hello from 42" > /tmp/test.txt
curl -s -u ramon:waaa@ftp@hhh -T /tmp/test.txt ftp://127.0.0.1/
```

### Validate Static Site
```bash
curl -k -s https://aelbouss.42.fr/resume/ | grep -i "Anass Alboussaili"
```
