# User Documentation - Inception

This document explains how to use the Inception infrastructure as an end user or administrator.

## Services Provided

The Inception stack provides the following services:

### 1. WordPress Website
- **Purpose**: Content management system for creating and managing website content
- **Access**: https://jvalle-d.42.fr
- **Features**:
  - Create and edit posts
  - Manage pages
  - Upload media (images, videos)
  - Customize themes and plugins

### 2. WordPress Administration Panel
- **Purpose**: Backend interface for managing the website
- **Access**: https://jvalle-d.42.fr/wp-admin
- **Features**:
  - User management
  - Content creation and editing
  - Theme customization
  - Plugin installation
  - Settings configuration

### 3. MariaDB Database
- **Purpose**: Stores all WordPress data (posts, users, settings)
- **Access**: Internal only (not directly accessible from outside)
- **Note**: Data is persisted in volumes for reliability

## Starting and Stopping the Project

### Starting the Infrastructure

From the project root directory:

```bash
make
```

This command will:
1. Build all Docker images (first time only)
2. Create and start all containers
3. Set up the database
4. Configure WordPress
5. Make the website available at https://jvalle-d.42.fr

**First startup may take 2-5 minutes** while downloading base images and building containers.

### Stopping the Infrastructure

To stop all services while preserving data:

```bash
make stop
```

To stop and remove containers (data is preserved):

```bash
make down
```

### Restarting Services

If containers are stopped but not removed:

```bash
make start
```

To restart from scratch:

```bash
make re
```

**Warning**: `make re` will rebuild everything and may require reconfiguration.

## Accessing the Website

### Public Website

1. Open your web browser
2. Navigate to: `https://jvalle-d.42.fr`
3. Accept the self-signed certificate warning (this is normal for local development)
4. The WordPress website should now be visible

### Administration Panel

1. Navigate to: `https://jvalle-d.42.fr/wp-admin`
2. Enter your administrator credentials:
   - **Username**: jvalled (or as configured)
   - **Password**: See credentials file or contact administrator
3. Click "Log In"

### Additional User Access

A second user account exists for content authors:
- **Username**: wpuser2
- **Role**: Author (can create and edit own posts)
- **Password**: Contact administrator for credentials

## Managing Credentials

### Location of Credentials

Credentials are stored in two places:

1. **Secrets Directory** (`secrets/`):
   - `db_root_password.txt`: MariaDB root password
   - `db_password.txt`: WordPress database user password
   - `credentials.txt`: WordPress user credentials

2. **Environment File** (`srcs/.env`):
   - Domain name
   - Database configuration
   - Non-sensitive settings

### Changing Credentials

**Important**: Changing credentials requires rebuilding the infrastructure.

1. Stop all services:
   ```bash
   make down
   ```

2. Edit the credential files in `secrets/`

3. Remove old data:
   ```bash
   make fclean
   ```

4. Rebuild and restart:
   ```bash
   make
   ```

### Security Best Practices

- **Never commit** `secrets/` directory to version control
- **Never commit** `.env` file with real credentials
- Use strong passwords (minimum 12 characters, mixed case, numbers, symbols)
- Regularly update credentials
- Limit access to the server hosting the infrastructure

## Checking Service Status

### Verify All Services Are Running

```bash
docker-compose -f srcs/docker-compose.yml ps
```

Expected output should show three containers:
- `nginx` - Status: Up
- `wordpress` - Status: Up
- `mariadb` - Status: Up

### Check Individual Service Logs

**NGINX logs**:
```bash
docker logs nginx
```

**WordPress logs**:
```bash
docker logs wordpress
```

**MariaDB logs**:
```bash
docker logs mariadb
```

### Verify Network Connectivity

Test if the website responds:
```bash
curl -k https://jvalle-d.42.fr
```

You should see HTML output if the services are running correctly.

## Troubleshooting

### Website Not Accessible

1. Check if containers are running:
   ```bash
   docker ps
   ```

2. Verify domain configuration in `/etc/hosts`:
   ```bash
   cat /etc/hosts | grep jvalle-d.42.fr
   ```
   Should show: `127.0.0.1 jvalle-d.42.fr`

3. Check NGINX logs for errors:
   ```bash
   docker logs nginx
   ```

### Cannot Log In to WordPress

1. Verify credentials are correct
2. Check WordPress container logs:
   ```bash
   docker logs wordpress
   ```
3. Ensure MariaDB is running:
   ```bash
   docker ps | grep mariadb
   ```

### Database Connection Errors

1. Check MariaDB container status:
   ```bash
   docker logs mariadb
   ```

2. Verify WordPress can reach database:
   ```bash
   docker exec wordpress mysqladmin ping -hmariadb -uwpuser -p
   ```
   (Enter password when prompted)

### Container Keeps Restarting

1. Check container logs for errors:
   ```bash
   docker logs <container_name>
   ```

2. Ensure volumes directory exists:
   ```bash
   ls -la /home/jvalle-d/data/
   ```

3. Check for permission issues

### Full Reset

If nothing else works, perform a complete reset:

```bash
make fclean  # Remove everything including volumes
make         # Rebuild from scratch
```

**Warning**: This will delete all website content and database data!

## Data Backup

### Backing Up WordPress Content

WordPress files are stored in:
```
/home/jvalle-d/data/wordpress
```

To backup:
```bash
tar -czf wordpress-backup-$(date +%Y%m%d).tar.gz /home/jvalle-d/data/wordpress
```

### Backing Up Database

Database files are stored in:
```
/home/jvalle-d/data/mariadb
```

To backup:
```bash
tar -czf mariadb-backup-$(date +%Y%m%d).tar.gz /home/jvalle-d/data/mariadb
```

Alternatively, use mysqldump:
```bash
docker exec mariadb mysqldump -u root -p wordpress > wordpress-backup-$(date +%Y%m%d).sql
```

## Support

For technical issues:
1. Check this documentation
2. Review container logs
3. Consult the developer documentation (DEV_DOC.md)
4. Contact the system administrator
