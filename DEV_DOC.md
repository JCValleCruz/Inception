# Developer Documentation - Inception

This document provides technical information for developers who want to understand, modify, or extend the Inception infrastructure.

## Environment Setup from Scratch

### Prerequisites

1. **Linux System or Virtual Machine**
   - Recommended: Debian 11 (Bullseye) or Ubuntu 20.04+
   - Minimum 2GB RAM, 20GB disk space

2. **Install Docker**
   ```bash
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   sudo usermod -aG docker $USER
   ```
   Log out and log back in for group changes to take effect.

3. **Install Docker Compose**
   ```bash
   sudo apt-get update
   sudo apt-get install docker-compose-plugin
   ```

4. **Install Make**
   ```bash
   sudo apt-get install make
   ```

### Initial Configuration

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd inception
   ```

2. **Create data directories**
   ```bash
   mkdir -p /home/jvalle-d/data/wordpress
   mkdir -p /home/jvalle-d/data/mariadb
   sudo chown -R $USER:$USER /home/jvalle-d/data
   ```

3. **Create secrets directory and files**
   ```bash
   mkdir -p secrets

   # Database root password
   echo "your_secure_root_password" > secrets/db_root_password.txt

   # Database user password
   echo "your_secure_db_password" > secrets/db_password.txt

   # WordPress credentials
   cat > secrets/credentials.txt << EOF
   WORDPRESS_ADMIN_PASSWORD=your_secure_admin_password
   EOF

   chmod 600 secrets/*
   ```

4. **Create and configure .env file**
   ```bash
   cp srcs/.env.example srcs/.env  # If example exists
   # Or create manually with required variables
   ```

5. **Configure domain resolution**
   ```bash
   echo "127.0.0.1 jvalle-d.42.fr" | sudo tee -a /etc/hosts
   ```

## Building and Launching the Project

### Using Makefile (Recommended)

The Makefile provides convenient commands for all operations:

```bash
# Build images and start containers
make

# Build images only
make build

# Start containers (must be built first)
make up

# Stop containers
make stop

# Start stopped containers
make start

# Stop and remove containers
make down

# Clean up containers and images
make clean

# Full cleanup including volumes
make fclean

# Rebuild everything from scratch
make re
```

### Using Docker Compose Directly

If you need more control or want to see verbose output:

```bash
cd srcs/

# Build all images
docker-compose build

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# View running containers
docker-compose ps
```

### Build Process Details

1. **Image Building**: Each Dockerfile builds from Debian Bullseye
   - MariaDB: Installs MariaDB server, configures for network access
   - WordPress: Installs PHP-FPM, WP-CLI, configures WordPress
   - NGINX: Installs NGINX, generates SSL certificate, configures reverse proxy

2. **Network Creation**: Docker creates `inception_network` bridge network

3. **Volume Mounting**: Bind mounts created to host directories

4. **Container Startup Order**:
   - MariaDB starts first
   - WordPress waits for MariaDB to be ready
   - NGINX starts after WordPress is ready

## Managing Containers and Volumes

### Container Management

**List all containers**:
```bash
docker ps -a
```

**Inspect a container**:
```bash
docker inspect <container_name>
```

**Execute commands in a container**:
```bash
docker exec -it <container_name> bash
```

**View container logs**:
```bash
docker logs <container_name>
docker logs -f <container_name>  # Follow log output
docker logs --tail 100 <container_name>  # Last 100 lines
```

**Restart a specific container**:
```bash
docker restart <container_name>
```

**Stop a specific container**:
```bash
docker stop <container_name>
```

**Remove a container**:
```bash
docker rm <container_name>
```

### Volume Management

**List volumes**:
```bash
docker volume ls
```

**Inspect a volume**:
```bash
docker volume inspect <volume_name>
```

**Remove unused volumes**:
```bash
docker volume prune
```

**Access volume data directly**:
```bash
ls -la /home/jvalle-d/data/wordpress
ls -la /home/jvalle-d/data/mariadb
```

### Network Management

**List networks**:
```bash
docker network ls
```

**Inspect the project network**:
```bash
docker network inspect srcs_inception_network
```

**Test connectivity between containers**:
```bash
docker exec wordpress ping mariadb
docker exec nginx ping wordpress
```

## Useful Development Commands

### MariaDB Commands

**Access MariaDB shell**:
```bash
docker exec -it mariadb mysql -u root -p
```

**Check database status**:
```bash
docker exec mariadb mysqladmin -u root -p status
```

**List databases**:
```bash
docker exec mariadb mysql -u root -p -e "SHOW DATABASES;"
```

**Export database**:
```bash
docker exec mariadb mysqldump -u root -p wordpress > backup.sql
```

**Import database**:
```bash
docker exec -i mariadb mysql -u root -p wordpress < backup.sql
```

### WordPress Commands

**Access WordPress container**:
```bash
docker exec -it wordpress bash
```

**WP-CLI commands** (inside container):
```bash
wp user list
wp plugin list
wp theme list
wp db check
wp cache flush
```

**Check PHP-FPM status**:
```bash
docker exec wordpress ps aux | grep php-fpm
```

### NGINX Commands

**Test NGINX configuration**:
```bash
docker exec nginx nginx -t
```

**Reload NGINX** (after config changes):
```bash
docker exec nginx nginx -s reload
```

**View access logs**:
```bash
docker exec nginx cat /var/log/nginx/access.log
```

**View error logs**:
```bash
docker exec nginx cat /var/log/nginx/error.log
```

## Data Storage and Persistence

### Data Locations

All persistent data is stored in `/home/jvalle-d/data/`:

1. **WordPress Files** (`/home/jvalle-d/data/wordpress`):
   - WordPress core files
   - Themes
   - Plugins
   - Uploaded media
   - wp-config.php

2. **MariaDB Data** (`/home/jvalle-d/data/mariadb`):
   - Database files
   - Transaction logs
   - Configuration

### How Persistence Works

The `docker-compose.yml` defines volumes with bind mounts:

```yaml
volumes:
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/jvalle-d/data/wordpress
```

This ensures:
- Data survives container restarts
- Data can be accessed directly from host
- Easy backup and restore
- Data persists even if containers are removed

### Backup Strategy

**Automated backup script example**:

```bash
#!/bin/bash
BACKUP_DIR="/backups/inception-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup volumes
cp -r /home/jvalle-d/data/wordpress "$BACKUP_DIR/"
cp -r /home/jvalle-d/data/mariadb "$BACKUP_DIR/"

# Backup configuration
cp -r secrets "$BACKUP_DIR/"
cp srcs/.env "$BACKUP_DIR/"

# Create archive
tar -czf "$BACKUP_DIR.tar.gz" "$BACKUP_DIR"
rm -rf "$BACKUP_DIR"

echo "Backup created: $BACKUP_DIR.tar.gz"
```

## Architecture Overview

### Service Architecture

```
                    Internet
                       |
                    [Port 443]
                       |
                   [NGINX Container]
                   - TLS Termination
                   - Reverse Proxy
                       |
                   [Port 9000]
                       |
                 [WordPress Container]
                 - PHP-FPM
                 - WP-CLI
                       |
                   [Port 3306]
                       |
                 [MariaDB Container]
                 - Database Server
```

### Network Flow

1. Client connects to `https://jvalle-d.42.fr:443`
2. NGINX handles TLS and forwards to WordPress via FastCGI
3. WordPress processes PHP and queries MariaDB
4. MariaDB returns data to WordPress
5. WordPress generates HTML
6. NGINX returns response to client

### Container Communication

Containers communicate using Docker's internal DNS:
- `nginx` → `wordpress:9000` (FastCGI)
- `wordpress` → `mariadb:3306` (MySQL protocol)

No containers expose ports to host except NGINX (443).

## Dockerfile Details

### NGINX Dockerfile

```dockerfile
FROM debian:bullseye              # Base image
RUN apt-get update && ...         # Install NGINX and OpenSSL
RUN openssl req -x509 ...         # Generate self-signed certificate
COPY conf/nginx.conf ...          # Copy configuration
EXPOSE 443                        # Expose HTTPS port
CMD ["nginx", "-g", "daemon off;"] # Run NGINX in foreground
```

**Key Points**:
- Self-signed certificate for local development
- TLS 1.2 and 1.3 only
- Configured as reverse proxy to PHP-FPM

### MariaDB Dockerfile

```dockerfile
FROM debian:bullseye
RUN apt-get update && ...         # Install MariaDB
COPY conf/50-server.cnf ...       # MySQL configuration
COPY tools/init-db.sh ...         # Initialization script
EXPOSE 3306
CMD ["/usr/local/bin/init-db.sh"] # Custom entrypoint
```

**Key Points**:
- Custom initialization script
- Reads secrets for passwords
- Creates database and user on first run
- Runs mysqld in foreground (no daemon mode)

### WordPress Dockerfile

```dockerfile
FROM debian:bullseye
RUN apt-get update && ...         # Install PHP-FPM and extensions
RUN curl -O ... wp-cli.phar ...   # Install WP-CLI
COPY conf/www.conf ...            # PHP-FPM configuration
COPY tools/setup-wordpress.sh ... # Setup script
EXPOSE 9000
CMD ["/usr/local/bin/setup-wordpress.sh"]
```

**Key Points**:
- PHP-FPM listens on port 9000
- WP-CLI for automated setup
- Waits for database before configuring
- Creates admin and regular user

## Troubleshooting Development Issues

### Build Failures

**Problem**: Dockerfile build fails

**Solutions**:
- Check internet connection (needed to download packages)
- Verify base image availability: `docker pull debian:bullseye`
- Check Dockerfile syntax
- Review build logs carefully

### Container Won't Start

**Problem**: Container exits immediately

**Solutions**:
```bash
# Check exit code and reason
docker ps -a
docker logs <container_name>

# Common issues:
# - CMD not running in foreground (add -F, -g "daemon off", etc.)
# - Missing dependencies
# - Configuration errors
```

### Network Issues

**Problem**: Containers can't communicate

**Solutions**:
```bash
# Verify network exists
docker network ls

# Check container network settings
docker inspect <container_name> | grep NetworkMode

# Test connectivity
docker exec wordpress ping mariadb
docker exec nginx ping wordpress
```

### Volume Permission Issues

**Problem**: Permission denied errors

**Solutions**:
```bash
# Check directory ownership
ls -la /home/jvalle-d/data/

# Fix permissions
sudo chown -R $USER:$USER /home/jvalle-d/data/

# Inside container, check process user
docker exec <container> ps aux
```

### Database Connection Fails

**Problem**: WordPress can't connect to MariaDB

**Solutions**:
```bash
# Verify MariaDB is running
docker exec mariadb mysqladmin ping

# Check MariaDB logs
docker logs mariadb

# Verify credentials match
docker exec mariadb mysql -u wpuser -p -e "SELECT 1;"

# Check network connectivity
docker exec wordpress ping mariadb
```

## Modifying the Project

### Adding a New Service

1. Create directory structure:
   ```bash
   mkdir -p srcs/requirements/newservice/{conf,tools}
   ```

2. Create Dockerfile:
   ```bash
   touch srcs/requirements/newservice/Dockerfile
   ```

3. Add service to `docker-compose.yml`:
   ```yaml
   newservice:
     build: ./requirements/newservice
     networks:
       - inception_network
     restart: unless-stopped
   ```

4. Rebuild:
   ```bash
   make re
   ```

### Changing Ports

Edit `docker-compose.yml` ports section:
```yaml
ports:
  - "8443:443"  # Change host port to 8443
```

Update `/etc/hosts` if needed.

### Updating Environment Variables

1. Edit `srcs/.env`
2. Restart containers:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

### Modifying Configurations

After changing configuration files:

```bash
# Rebuild affected service
docker-compose build <service_name>

# Restart service
docker-compose up -d <service_name>
```

## Security Considerations

- **Never commit secrets** to version control
- Use strong passwords for all accounts
- Keep base images updated: `docker pull debian:bullseye`
- Use Docker secrets for sensitive data
- Limit container privileges
- Regular security audits: `docker scan <image_name>`
- Monitor container logs for suspicious activity

## Performance Optimization

- Use `.dockerignore` files to reduce context size
- Multi-stage builds if needed for smaller images
- Optimize layer caching (put changing content last)
- Clean up apt cache: `rm -rf /var/lib/apt/lists/*`
- Use specific image tags, not `latest`

## Additional Resources

- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)
- [Docker Compose File Reference](https://docs.docker.com/compose/compose-file/)
- [NGINX Configuration Guide](https://nginx.org/en/docs/)
- [MariaDB Administration](https://mariadb.com/kb/en/mariadb-administration/)
- [WP-CLI Commands](https://developer.wordpress.org/cli/commands/)
