*This project has been created as part of the 42 curriculum by aelmsafe.*

# Inception

## Description

Inception is a system administration project from the 42 curriculum. The goal is to set up a small but fully functional web infrastructure using Docker and Docker Compose, running inside a virtual machine.

The stack consists of three services [ NGINX ] [ WordPress + PHP-FPM ] [ MariaDB ], each isolated in its own container, communicating over a private Docker network, with persistent data stored in docker named volumes.

### Project Design Choices

**Virtual Machines vs Docker**

- A Virtual Machine (VM) emulates a full operating system with its own kernel, providing strong isolation but at a heavy resource cost. Docker containers, by contrast, share the host kernel and package only the application and its dependencies, making them far lighter and faster to spin up. This project uses Docker because it's ideal for deploying isolated services efficiently without the overhead of full OS virtualization.

**Secrets vs Environment Variables**

- Environment variables (stored in a `.env` file) are convenient for non-sensitive configuration like domain names or usernames. For sensitive data such as passwords and API keys, Docker Secrets are preferred — they are stored in memory (tmpfs) inside the container and never written to the image layers or environment, making them significantly more secure. This project uses both: `.env` for general config and a `secrets/` folder (gitignored) for credentials.

**Docker Network vs Host Network**

- Using `network: host` makes a container share the host's network namespace directly, bypassing Docker's isolation entirely. A custom Docker bridge network (as used in this project) gives containers their own isolated network where they can communicate by service name (DNS resolution) without exposing internal ports to the outside world. The only exposed port is 443 on NGINX.

**Docker Named Volumes vs Docker Bind Mounts**

- Bind mounts map a specific host path into the container, making them tightly coupled to the host filesystem structure. Named Docker volumes are managed by Docker itself, are more portable, and are the recommended approach for persistent data in production-like setups. This project uses named volumes for the WordPress files and the MariaDB database, stored under `/home/aelmsafe/data` on the host.


## Instructions

### Prerequisites

- A Linux virtual machine (Debian or Ubuntu recommended), with:
    - `Docker` and `Docker Compose` installed
    - `make` installed

### Setup

- **0. Launch Debian/Ubuntu on the virtual machine**

- **1. Clone the repository, and change the working directory to it:**
```bash
git clone git@vogsphere-v2-bg.1337.ma:vogsphere/intra-uuid-9bdc5913-25aa-4ce6-ab23-57c0120071cf-7497923-aelmsafe inception
cd inception
```

- **2. Add your domain to `/etc/hosts` on the VM:**
```bash
echo "127.0.0.1 aelmsafe.42.fr" | sudo tee -a /etc/hosts
```

- **3. Create the `.env` file** at `srcs/.env` (like the example below):
```
MYSQL_USER = example_mysql_user
MYSQL_PASSWORD = example_mysql_password
MYSQL_DATABASE = example_mysql_database
MYSQL_ROOT_PASSWORD = example_mysql_root_password
DOMAIN_NAME = aelmsafe.42.fr
WP_ADMIN_USER = example_wordpress_admin_user
WP_ADMIN_PASSWORD = example_wordpress_admin_password
WP_USER = example_wordpress_user
WP_ADMIN_EMAIL = example_wordpress_admin_email
WP_USER_EMAIL = example_wordpress_user_email
WP_USER_PASSWORD = example_wordpress_user_password
```

- **3. Create the `.env` file** at `srcs/.env` (like the example below):
```


- **4. Build and start:**
```bash
make
```

- **5. Visit the site:**
```bash
Open your browser and go to `https://aelmsafe.42.fr`. Accept the self-signed certificate warning.
```

### Makefile targets

| Target | Description |
|---|---|
| `make` / `make all` | Build images and start all containers in background |
| `make down` | Stop containers |
| `make clean` | Stop containers and remove the project's network, and images. Then reclaim disk space by removing unused Docker objects |
| `make fclean` | Everything that `make clean` does + Remove mounted named volumes |
| `make re` | Full rebuild from scratch (runs `make fclean` + `make all`) |

---

## Resources

### Docker & Infrastructure
- [Docker official documentation](https://docs.docker.com/)
- [Docker Compose reference](https://docs.docker.com/compose/)
- [NGINX documentation](https://nginx.org/en/docs/)
- [MariaDB Docker Hub](https://hub.docker.com/_/mariadb)
- [How to Configure PHP-FPM with NGINX](https://www.digitalocean.com/community/tutorials/php-fpm-nginx)
- [PHP-FPM Configuration 101](https://myjeeva.com/php-fpm-configuration-101.html)
- [TLSv1.2/1.3 with NGINX](https://nginx.org/en/docs/http/ngx_http_ssl_module.html)
- [Docker Secrets documentation](https://docs.docker.com/compose/how-tos/use-secrets/)
- [Create a named Docker bind mount volume](https://cravencode.com/post/docker/create-named-docker-bind-mount/)

### AI Usage

Google's latest Gemini model was used in this project for the following tasks:

- **Documentation**: Generating the initial drafts of `README.md`, `USER_DOC.md`, and `DEV_DOC.md`, which were then reviewed and adjusted to match the actual project configuration.
- **Dockerfile patterns**: Getting an overview of best practices for running services as PID 1 (using `exec` form of `CMD`/`ENTRYPOINT`) and avoiding infinite-loop hacks.
- **Nginx SSL config**: Generating a starting nginx.conf with TLSv1.2/1.3 restrictions, reviewed and tested manually.
- **Wordpress php-fpm config**: Helping me understand the reasons behinf using php-fpm, its configuration files, reviewed and tested manually.
- **Debugging**: Explaining error messages encountered during `docker compose up` and suggesting fixes.

All AI-generated content was reviewed, understood, and validated before being included in the project. Nothing was blindly copy-pasted without comprehension.