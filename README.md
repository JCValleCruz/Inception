*This project has been created as part of the 42 curriculum by jvalle-d.*

# Inception

## Description

Inception is a system administration project that focuses on Docker containerization. The goal is to create a small infrastructure composed of different services running in isolated Docker containers, orchestrated using Docker Compose. This project demonstrates key concepts in modern DevOps practices, including container orchestration, service isolation, network configuration, and secure credential management.

The infrastructure consists of three main services:
- **NGINX**: Web server with TLS encryption (TLSv1.2/TLSv1.3)
- **WordPress**: Content management system with PHP-FPM
- **MariaDB**: Relational database for WordPress

Each service runs in its own dedicated container with custom Dockerfiles, ensuring complete control over the build process and configuration.

## Instructions

### Prerequisites

- Docker and Docker Compose installed
- Linux-based system or virtual machine
- Sufficient disk space for volumes (in `/home/jvalle-d/data`)

### Setup

1. Clone this repository
2. Create the required directories for volumes:
   ```bash
   mkdir -p /home/jvalle-d/data/wordpress
   mkdir -p /home/jvalle-d/data/mariadb
   ```

3. Configure your `/etc/hosts` file to point the domain to localhost:
   ```bash
   echo "127.0.0.1 jvalle-d.42.fr" | sudo tee -a /etc/hosts
   ```

4. Create the secrets directory and files (not included in repository):
   ```bash
   mkdir -p secrets
   echo "your_root_password" > secrets/db_root_password.txt
   echo "your_db_password" > secrets/db_password.txt
   echo "WORDPRESS_ADMIN_PASSWORD=your_admin_password" > secrets/credentials.txt
   ```

5. Create the `.env` file in `srcs/` directory with your configuration (template provided)

### Running the Project

```bash
make        # Build and start all containers
make down   # Stop all containers
make clean  # Stop and remove containers and images
make fclean # Full cleanup including volumes
make re     # Rebuild everything from scratch
```

### Accessing the Services

- WordPress website: https://jvalle-d.42.fr
- WordPress admin panel: https://jvalle-d.42.fr/wp-admin

## Resources

### Documentation
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [MariaDB Documentation](https://mariadb.org/documentation/)
- [WordPress Documentation](https://wordpress.org/support/)
- [WP-CLI Documentation](https://wp-cli.org/)

### Tutorials
- [Docker Tutorial for Beginners](https://docker-curriculum.com/)
- [Docker Compose Tutorial](https://docs.docker.com/compose/gettingstarted/)
- [NGINX SSL Configuration](https://nginx.org/en/docs/http/configuring_https_servers.html)

### AI Usage
AI tools (Claude Code) were used for:
- Generating boilerplate Dockerfile configurations
- Creating initial nginx configuration templates
- Debugging shell scripts for database initialization
- Writing documentation structure and formatting
- Suggesting best practices for Docker security

All AI-generated content was reviewed, tested, and modified to meet project requirements and ensure full understanding.

## Project Description

### Docker vs Virtual Machines

**Virtual Machines (VMs):**
- Virtualize entire hardware stack
- Include full OS with kernel
- Higher resource overhead
- Slower startup times
- Complete isolation at hardware level

**Docker Containers:**
- Share host OS kernel
- Package only application and dependencies
- Minimal resource overhead
- Fast startup (seconds)
- Process-level isolation
- Better resource utilization

For this project, Docker is preferred because it allows rapid deployment, efficient resource usage, and easier service management while maintaining sufficient isolation for our needs.

### Secrets vs Environment Variables

**Environment Variables:**
- Stored in `.env` file
- Loaded at container runtime
- Visible in container inspect
- Suitable for non-sensitive configuration (domain names, database names)

**Docker Secrets:**
- Stored in separate files
- Mounted in memory at `/run/secrets/`
- Not visible in container inspect
- Suitable for sensitive data (passwords, API keys)
- Better security for production environments

This project uses both: secrets for credentials and environment variables for general configuration.

### Docker Network vs Host Network

**Docker Network (Bridge):**
- Isolated network for containers
- Containers communicate via service names
- Network segregation and security
- Port mapping required for external access

**Host Network:**
- Container shares host's network stack
- No network isolation
- Direct access to host ports
- Security risk

This project uses Docker network (bridge mode) to ensure proper isolation while allowing controlled communication between services.

### Docker Volumes vs Bind Mounts

**Docker Volumes:**
- Managed by Docker
- Stored in Docker's storage directory
- Better performance on some systems
- Easier to backup and migrate
- Platform-independent

**Bind Mounts:**
- Direct mapping to host filesystem path
- Full control over exact location
- Easier to access from host
- Dependent on host filesystem structure

This project uses bind mounts configured as volumes to store data in `/home/jvalle-d/data`, making it easy to access and backup data from the host system while maintaining the volume abstraction.

## Main Design Choices

1. **Debian Bullseye**: Chosen as base image for stability and wide package availability
2. **Custom Dockerfiles**: All images built from scratch to ensure complete control and understanding
3. **PHP-FPM**: Separate WordPress and NGINX to follow best practices (one service per container)
4. **WP-CLI**: Automated WordPress installation and configuration
5. **TLS 1.2/1.3 only**: Enhanced security by disabling older protocols
6. **Health checks via scripts**: Database initialization checks before WordPress setup
7. **Non-root processes**: Services run as appropriate users (www-data, mysql)

## Project Structure

```
.
├── Makefile
├── secrets/
│   ├── credentials.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── docker-compose.yml
    ├── .env
    └── requirements/
        ├── mariadb/
        │   ├── conf/
        │   ├── Dockerfile
        │   └── tools/
        ├── nginx/
        │   ├── conf/
        │   ├── Dockerfile
        │   └── tools/
        └── wordpress/
            ├── conf/
            ├── Dockerfile
            └── tools/
```
