# Developer Documentation

This document describes how to set up, build, and manage the Inception project from a developer's perspective.

---

## Environment Setup from Scratch

### Prerequisites

- A Linux virtual machine (Debian 11/12 or Alpine 3.x recommended)
- Docker Engine installed: [https://docs.docker.com/engine/install/](https://docs.docker.com/engine/install/)
- Docker Compose v2 (comes bundled with Docker Desktop or installable via `apt`)
- `make` installed (`sudo apt install make`)
- Git installed

### Repository Structure

```
inception/
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/
|   |
|   ├── credentials.txt
|   ├── db_password.txt
|   └── db_root_password.txt
|
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements
        |
        ├── nginx/
        │   ├── Dockerfile
        │   └── conf/nginx.conf
        |
        ├── wordPress/
        │   ├── Dockerfile
        │   ├── conf/www.conf
        |   └── tools/script_wp.sh
        |
        └── mariadb/
            ├── Dockerfile
            ├── conf/50-server.cnf
            └── tools/script_db.sh
```

### Configuration Files

**1. Create `srcs/.env` and `secrets/*.txt` files:**
- **Create `srcs/.env`** — copy and fill in all values:
    ```bash
    DOMAIN_NAME=aelmsafe.42.fr

    MYSQL_DATABASE=CUSTOM_DATABASE_NAME
    MYSQL_USER=CUSTOM_USERNAME

    WP_ADMIN_USER=CUSTOM_WORDPRESS_ADMIN_USERNAME
    WP_ADMIN_EMAIL=CUSTOM_WORDPRESS_ADMIN_EMAIL

    WP_USER=CUSTOM_WORDPRESS_AUTHOR_USERNAME
    WP_USER_EMAIL=CUSTOM_WORDPRESS_AUTHOR_EMAIL
    ```

- **Create `secrets/credentials.txt`** — copy and fill in all values:
    ```bash
    WP_ADMIN_PASSWORD="CUSTOM_ADMIN_PASSWORD"
    WP_USER_PASSWORD="CUSTOM_USER_PASSWORD"
    ```

- **Create `secrets/db_password.txt`** — copy and fill in all values:
    ```bash
    MYSQL_PASSWORD="CUSTOM_MYSQL_PASSWORD"
    ```

- **Create `secrets/db_root_password.txt`** — copy and fill in all values:
    ```bash
    MYSQL_ROOT_PASSWORD="CUSTOM_ROOT_PASSWORD"
    ```


Rules from the subject:
- `ADMIN_USER` must NOT contain `admin`, `Admin`, `administrator`, or `Administrator`
- Never commit `srcs/.env` nor `secrets/*` to Git. They are listed in `.gitignore`

**2. Add your domain to `/etc/hosts` on the VM:**
```bash
echo "127.0.0.1 aelmsafe.42.fr" | sudo tee -a /etc/hosts
```

---

## Building and Launching with Makefile and Docker Compose

**First build and start:**
```bash
make
```
Internally runs:
```bash
docker compose -f ./srcs/docker-compose.yml up -d --build
```
- `--build` forces image rebuild even if cached
- `-d` runs in detached (background) mode

**Nuclear reset (wipe everything including data):**
```bash
make fclean
```
Internally runs:
```bash
docker compose -f ./srcs/docker-compose.yml down -v --rmi all
docker system prune -af
sudo rm -rf /home/aelmsafe/data/mariadb
sudo rm -rf /home/aelmsafe/data/wordpress
sudo rm -rf /home/aelmsafe/data
```
where `/home/aelmsafe/data/` directory is our persistent storage

**Full clean rebuild:**
```bash
make re
```
Stops containers, removes images, removes data, then rebuilds from scratch.

---

## Container Management Commands

**See running containers:**
```bash
docker ps
```

**See all containers including stopped:**
```bash
docker ps -a
```

**Follow logs in real time:**
```bash
docker logs -f wordpress
docker logs -f mariadb
docker logs -f nginx
```

**Shell into a running container:**
```bash
docker exec -it wordpress bash
docker exec -it mariadb bash
docker exec -it nginx bash
```

**Restart a single service:**
```bash
docker restart wordpress
```

**Rebuild and restart a single service only:**
```bash
docker compose -f ./srcs/docker-compose.yml up -d --build wordpress
```

**Inspect the Docker network:**
```bash
docker network inspect srcs_inception
```

---

## Data Storage and Persistence

### Named Volumes

The project uses two Docker named volumes:

| Volume | Mounted at | Contains |
|---|---|---|
| `wordpress_data` | `/var/www/html` in wordpress and nginx | WordPress core files, themes, plugins, uploads |
| `mariadb_data` | `/var/lib/mysql` in mariadb | All MariaDB database files |

**Inspect a volume:**
```bash
docker volume inspect wordpress_data
docker volume inspect mariadb_data
```

**List all volumes:**
```bash
docker volume ls
```

### How Persistence Works

When you run `docker compose down` (without `-v`), containers are destroyed but volumes remain. On the next `make`, containers are recreated and reattach to the existing volumes  all WordPress content and database data survives.

### Where Docker Stores Volume Data on the Host

it is stored on /home/aelmsafe/data/ and you can check by running:

```bash
# Find the actual path on the host:
docker volume inspect wordpress_data
#or
docker volume inspect mariadb_data
# Returns something like: /var/lib/docker/volumes/mariadb_data/_data
```

**Delete volumes (all data lost):**
```bash
docker compose -f ./srcs/docker-compose.yml down -v
sudo rm -rf /home/aelmsafe/data/mariadb
sudo rm -rf /home/aelmsafe/data/wordpress
sudo rm -rf /home/aelmsafe/data
```

---

## How the Startup Sequence Works

Understanding the boot order helps debug issues:

```
1. MariaDB container starts
   └── script_db.sh runs
       ├── If fresh volume: initializes DB, creates user, sets root password
       └── exec mysqld (becomes PID 1, ready for connections on port 3306)

2. WordPress container starts (depends_on: mariadb)
   └── sript_wp.sh runs
       ├── Patience loop: checks if mariadb is up every 1sec until it is up
       ├── If fresh volume: downloads WordPress, creates wp-config.php, installs WP, creates users
       └── exec php-fpm8.2 -F (becomes PID 1, listens on port 9000)

3. NGINX container starts (depends_on: wordpress)
   └── nginx -g 'daemon off;' (becomes PID 1, listens on port 443)
       └── Forwards .php requests to wordpress:9000 via FastCGI
```

---

## Common Debug Commands

```bash
# Check if MariaDB DB was created:
docker exec -it mariadb mariadb -uroot -p"{root password here}" -e "SHOW DATABASES;"

# Check WordPress files exist:
docker exec -it wordpress ls /var/www/wordpress

# Check wp-config.php was created:
docker exec -it wordpress cat /var/www/wordpress/wp-config.php | head -20

# Check NGINX config is valid:
docker exec -it nginx nginx -t
```