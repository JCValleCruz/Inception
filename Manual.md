# Manual de Estudio - Proyecto Inception

*Documento de estudio y aprendizaje técnico para el proyecto Inception de 42*

## Índice

1. [Introducción](#introducción)
2. [Fundamentos de Docker](#fundamentos-de-docker)
3. [Docker Compose](#docker-compose)
4. [Arquitectura del Proyecto](#arquitectura-del-proyecto)
5. [Análisis de cada Servicio](#análisis-de-cada-servicio)
6. [Conceptos Clave](#conceptos-clave)
7. [Configuraciones Críticas](#configuraciones-críticas)
8. [Scripts de Automatización](#scripts-de-automatización)
9. [Redes y Comunicación](#redes-y-comunicación)
10. [Persistencia de Datos](#persistencia-de-datos)
11. [Seguridad](#seguridad)
12. [Debugging y Troubleshooting](#debugging-y-troubleshooting)
13. [Preguntas de Evaluación](#preguntas-de-evaluación)

---

## Introducción

Este manual explica todos los conceptos técnicos del proyecto **Inception**, un ejercicio de administración de sistemas que utiliza Docker para crear una infraestructura de servicios web.

### ¿Qué es Inception?

Inception es un proyecto que simula un entorno de producción web completo utilizando contenedores Docker. El objetivo es comprender:

- **Containerización**: Cómo aislar servicios en contenedores
- **Orquestación**: Cómo hacer que múltiples servicios trabajen juntos
- **Redes**: Cómo los servicios se comunican entre sí
- **Persistencia**: Cómo conservar datos importantes
- **Seguridad**: Cómo proteger credenciales y comunicaciones

### Stack Tecnológico

- **NGINX**: Servidor web y proxy reverso
- **WordPress**: Sistema de gestión de contenido (CMS)
- **MariaDB**: Base de datos relacional
- **PHP-FPM**: Procesador FastCGI para PHP
- **Docker**: Plataforma de contenedores
- **Docker Compose**: Orquestador de contenedores

---

## Fundamentos de Docker

### ¿Por qué Docker?

**Antes de Docker:**
```
Aplicación → Sistema Operativo → Hardware
```
- Problemas: "Funciona en mi máquina", dependencias, configuración

**Con Docker:**
```
Aplicación + Dependencias → Contenedor → Docker Engine → OS → Hardware
```
- Ventajas: Portabilidad, aislamiento, reproducibilidad

### Conceptos Fundamentales

#### 1. Imagen vs Contenedor

**Imagen** = Plantilla inmutable
- Como un "molde" o "clase" en programación
- Contiene el código, dependencias, configuración
- Se construye con un `Dockerfile`

**Contenedor** = Instancia ejecutable de una imagen
- Como un "objeto" instanciado de la "clase"
- Tiene estado, puede escribir datos
- Se puede parar, iniciar, eliminar

```bash
# Analogía con POO
# Imagen = class MiApp { ... }
# Contenedor = new MiApp()
docker build -t mi-imagen .     # Crear imagen
docker run mi-imagen           # Crear y ejecutar contenedor
```

#### 2. Dockerfile

Es un archivo de texto que contiene instrucciones para construir una imagen:

```dockerfile
FROM debian:bullseye          # Imagen base
RUN apt-get update           # Ejecutar comando durante build
COPY archivo.txt /app/       # Copiar archivos del host
WORKDIR /app                 # Directorio de trabajo
EXPOSE 80                    # Puerto que expone el contenedor
CMD ["nginx", "-g", "daemon off;"]  # Comando por defecto
```

**Capas (Layers):**
- Cada instrucción crea una capa
- Las capas se cachean para acelerar builds
- Optimización: instrucciones que cambian menos al principio

#### 3. Volúmenes

**Problema**: Los contenedores son efímeros (al eliminarlos, pierdes los datos)

**Solución**: Volúmenes
- **Bind Mounts**: Mapea directorio del host al contenedor
- **Named Volumes**: Docker maneja el almacenamiento
- **Anonymous Volumes**: Temporales

```yaml
volumes:
  - /host/path:/container/path    # Bind mount
  - named_volume:/container/path  # Named volume
```

#### 4. Redes

Los contenedores por defecto están aislados. Para comunicarse necesitan una red:

```yaml
networks:
  mi_red:
    driver: bridge
```

Los contenedores en la misma red pueden comunicarse usando nombres de servicio.

### Docker vs Máquinas Virtuales

| Aspecto | VM | Docker |
|---------|-----|--------|
| **Kernel** | Cada VM tiene su kernel | Comparten el kernel del host |
| **Tamaño** | GB | MB |
| **Velocidad** | Arranque lento (minutos) | Arranque rápido (segundos) |
| **Aislamiento** | Completo (hardware) | Proceso-nivel |
| **Overhead** | Alto | Bajo |
| **Uso típico** | Aislamiento fuerte | Microservicios, CI/CD |

---

## Docker Compose

### ¿Qué es Docker Compose?

Una herramienta para definir y ejecutar aplicaciones multi-contenedor usando YAML.

**Sin Compose:**
```bash
docker network create mi-red
docker run -d --network mi-red --name db mariadb
docker run -d --network mi-red --name app wordpress
docker run -d --network mi-red -p 80:80 --name web nginx
```

**Con Compose:**
```yaml
# docker-compose.yml
services:
  db:
    image: mariadb
  app:
    image: wordpress
  web:
    image: nginx
    ports:
      - "80:80"
networks:
  default:
    driver: bridge
```

```bash
docker-compose up -d  # ¡Un solo comando!
```

### Anatomía de docker-compose.yml

```yaml
version: '3.8'  # Opcional desde v1.27.0

services:           # Define los contenedores
  nginx:
    build:          # Construir desde Dockerfile
      context: ./requirements/nginx
      dockerfile: Dockerfile
    image: nginx:latest
    container_name: nginx
    ports:
      - "443:443"   # host:contenedor
    volumes:
      - wordpress_data:/var/www/html
    networks:
      - inception_network
    depends_on:     # Orden de inicio
      - wordpress
    restart: unless-stopped
    env_file:
      - .env        # Cargar variables de entorno

networks:           # Define redes personalizadas
  inception_network:
    driver: bridge

volumes:            # Define volúmenes nombrados
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/jvalle-d/data/wordpress

secrets:            # Define secretos (Docker Swarm)
  db_password:
    file: ./secrets/db_password.txt
```

### Comandos Esenciales

```bash
# Construir imágenes
docker-compose build

# Iniciar servicios
docker-compose up -d

# Ver logs
docker-compose logs -f

# Parar servicios
docker-compose stop

# Parar y eliminar contenedores
docker-compose down

# Ver estado de servicios
docker-compose ps

# Ejecutar comando en servicio
docker-compose exec nginx bash

# Escalar servicios
docker-compose up -d --scale web=3
```

---

## Arquitectura del Proyecto

### Vista de Alto Nivel

```
Internet
    ↓
[Port 443 HTTPS]
    ↓
┌─────────────────┐
│ NGINX Container │  ← Único punto de entrada
│ - TLS 1.2/1.3   │
│ - Reverse Proxy │
└─────────────────┘
    ↓ [FastCGI :9000]
┌─────────────────┐
│WordPress Container│
│ - PHP-FPM       │
│ - WP-CLI        │
└─────────────────┘
    ↓ [MySQL :3306]
┌─────────────────┐
│MariaDB Container│
│ - Database      │
│ - Storage       │
└─────────────────┘
```

### Flujo de una Petición

1. **Cliente** → HTTPS request → `jvalle-d.42.fr:443`
2. **NGINX** → Termina TLS, analiza request
3. **NGINX** → Forward a PHP-FPM vía FastCGI → `wordpress:9000`
4. **WordPress** → Procesa PHP, consulta BD → `mariadb:3306`
5. **MariaDB** → Retorna datos → WordPress
6. **WordPress** → Genera HTML → NGINX
7. **NGINX** → Envía respuesta → Cliente

### Red de Contenedores

```yaml
networks:
  inception_network:
    driver: bridge
```

**Bridge Network** crea una red privada donde:
- Los contenedores pueden comunicarse por nombre
- `nginx` puede alcanzar `wordpress`
- `wordpress` puede alcanzar `mariadb`
- Solo `nginx` expone puertos al host

### Persistencia de Datos

```yaml
volumes:
  wordpress_data:
    driver_opts:
      type: none
      o: bind
      device: /home/jvalle-d/data/wordpress

  mariadb_data:
    driver_opts:
      type: none
      o: bind
      device: /home/jvalle-d/data/mariadb
```

**Bind Mounts** mapean directorios del host:
- `/home/jvalle-d/data/wordpress` ↔ `/var/www/html` (en wordpress container)
- `/home/jvalle-d/data/mariadb` ↔ `/var/lib/mysql` (en mariadb container)

---

## Análisis de cada Servicio

### NGINX Service

#### Propósito
- **Servidor Web**: Sirve archivos estáticos
- **Proxy Reverso**: Redirige requests a PHP-FPM
- **Terminación TLS**: Maneja HTTPS

#### Dockerfile Key Points
```dockerfile
FROM debian:bullseye

# Instalar NGINX y OpenSSL
RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Crear directorio para SSL
RUN mkdir -p /etc/nginx/ssl

# Generar certificado auto-firmado
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=ES/ST=Madrid/L=Madrid/O=42/OU=42Madrid/CN=jvalle-d.42.fr"

# Copiar configuración personalizada
COPY conf/nginx.conf /etc/nginx/nginx.conf

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
```

#### Configuración Crítica (nginx.conf)
```nginx
events {
    worker_connections 1024;
}

http {
    upstream php-fpm {
        server wordpress:9000;  # Conecta a container WordPress
    }

    server {
        listen 443 ssl;
        server_name jvalle-d.42.fr;

        # Solo TLS 1.2 y 1.3
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_certificate /etc/nginx/ssl/nginx.crt;
        ssl_certificate_key /etc/nginx/ssl/nginx.key;

        root /var/www/html;
        index index.php index.html;

        location ~ \.php$ {
            fastcgi_pass php-fpm;           # Envía PHP a WordPress
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include fastcgi_params;
        }

        location / {
            try_files $uri $uri/ /index.php?$query_string;
        }
    }
}
```

**¿Por qué daemon off?**
```bash
# En un contenedor, el proceso principal (PID 1) NO debe salir
# Si nginx ejecuta en background (daemon), el contenedor termina
CMD ["nginx", "-g", "daemon off;"]  # Ejecuta en foreground
```

#### Conceptos Importantes

**FastCGI**: Protocolo para comunicación web server ↔ application server
- NGINX maneja requests HTTP
- PHP-FPM procesa código PHP
- Más eficiente que CGI tradicional

**Reverse Proxy**: NGINX actúa como intermediario
```
Cliente → NGINX → WordPress (backend)
Cliente ← NGINX ← WordPress (response)
```

**SSL/TLS Termination**: NGINX maneja el cifrado
- Cliente envía HTTPS → NGINX
- NGINX descifra → HTTP interno → WordPress
- Beneficio: WordPress no necesita manejar SSL

### MariaDB Service

#### Propósito
- **Almacenar datos de WordPress**: Posts, usuarios, configuración
- **Proveer interfaz SQL**: Para que WordPress consulte datos
- **Persistencia**: Datos sobreviven reinicios de contenedores

#### Dockerfile Key Points
```dockerfile
FROM debian:bullseye

# Instalar MariaDB
RUN apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Configuración para permitir conexiones remotas
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

# Script de inicialización
COPY tools/init-db.sh /usr/local/bin/init-db.sh
RUN chmod +x /usr/local/bin/init-db.sh

# Crear directorio para socket MySQL
RUN mkdir -p /var/run/mysqld && \
    chown -R mysql:mysql /var/run/mysqld && \
    chmod 777 /var/run/mysqld

EXPOSE 3306

CMD ["/usr/local/bin/init-db.sh"]
```

#### Script de Inicialización (init-db.sh)
```bash
#!/bin/bash

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB database..."

    # Instalar BD con estructura inicial
    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    # Leer contraseñas desde secrets
    MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
    MYSQL_PASSWORD=$(cat /run/secrets/db_password)

    # Configurar usuarios y permisos usando heredoc
    mysqld --user=mysql --bootstrap << EOF
USE mysql;
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

    echo "MariaDB database initialized successfully."
else
    echo "MariaDB database already exists."
fi

# Ejecutar MariaDB en foreground
exec mysqld --user=mysql --console
```

#### Configuración de Red (50-server.cnf)
```ini
[mysqld]
bind-address = 0.0.0.0        # Permite conexiones desde cualquier IP
port = 3306
socket = /var/run/mysqld/mysqld.sock
skip-networking = false        # Permitir conexiones TCP/IP
```

#### Conceptos Importantes

**mysql_install_db**: Crea estructura inicial de BD
- Crea tabla `mysql.user` para usuarios
- Establece permisos básicos
- Necesario en primera ejecución

**Bootstrap Mode**: Modo especial para configuración inicial
```bash
mysqld --bootstrap < commands.sql
```
- Ejecuta comandos SQL sin servidor completo
- Útil para setup inicial

**GRANT Syntax**:
```sql
GRANT ALL PRIVILEGES ON database.* TO 'user'@'host';
```
- `'%'` = cualquier host
- `'localhost'` = solo local
- `'wordpress.inception_network'` = host específico

**Heredoc en Bash**:
```bash
command << EOF
línea 1
línea 2
EOF
```
- Permite multilínea sin escapes
- `EOF` es delimitador (puede ser cualquier palabra)

### WordPress Service

#### Propósito
- **CMS**: Interfaz para crear contenido web
- **PHP Processing**: Ejecutar código PHP
- **Integración con BD**: Conectar con MariaDB

#### Dockerfile Key Points
```dockerfile
FROM debian:bullseye

# Instalar PHP-FPM y extensiones necesarias
RUN apt-get update && apt-get install -y \
    php7.4-fpm \
    php7.4-mysql \
    php7.4-curl \
    php7.4-gd \
    php7.4-intl \
    php7.4-mbstring \
    php7.4-soap \
    php7.4-xml \
    php7.4-xmlrpc \
    php7.4-zip \
    curl \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Descargar e instalar WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# Configurar PHP-FPM
RUN mkdir -p /run/php && \
    chown -R www-data:www-data /run/php

COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf

# Script de configuración
COPY tools/setup-wordpress.sh /usr/local/bin/setup-wordpress.sh
RUN chmod +x /usr/local/bin/setup-wordpress.sh

WORKDIR /var/www/html

EXPOSE 9000

CMD ["/usr/local/bin/setup-wordpress.sh"]
```

#### PHP-FPM Configuration (www.conf)
```ini
[www]
user = www-data
group = www-data
listen = 0.0.0.0:9000          ; Escucha en todas las interfaces
listen.owner = www-data
listen.group = www-data
pm = dynamic                   ; Gestión dinámica de procesos
pm.max_children = 50
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
```

#### Script de Setup (setup-wordpress.sh)
```bash
#!/bin/bash

cd /var/www/html

if [ ! -f wp-config.php ]; then
    echo "Setting up WordPress..."

    # Leer contraseña desde secrets
    MYSQL_PASSWORD=$(cat /run/secrets/db_password)

    # Esperar a que MariaDB esté listo
    while ! mysqladmin ping -h"${WORDPRESS_DB_HOST%:*}" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent; do
        echo "Waiting for MariaDB..."
        sleep 2
    done

    # Descargar WordPress
    wp core download --allow-root

    # Crear configuración
    wp config create \
        --dbname="${WORDPRESS_DB_NAME}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="${WORDPRESS_DB_HOST}" \
        --allow-root

    # Instalar WordPress
    wp core install \
        --url="https://${DOMAIN_NAME}" \
        --title="Inception" \
        --admin_user="${WORDPRESS_ADMIN_USER}" \
        --admin_password="$(cat /run/secrets/credentials | grep WORDPRESS_ADMIN_PASSWORD | cut -d'=' -f2)" \
        --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
        --allow-root

    # Crear usuario adicional
    wp user create "${WORDPRESS_USER}" "${WORDPRESS_USER_EMAIL}" \
        --role=author \
        --allow-root

    # Ajustar permisos
    chown -R www-data:www-data /var/www/html
    chmod -R 755 /var/www/html

    echo "WordPress setup completed."
else
    echo "WordPress already configured."
fi

# Ejecutar PHP-FPM en foreground
exec /usr/sbin/php-fpm7.4 -F
```

#### Conceptos Importantes

**WP-CLI**: Command Line Interface para WordPress
```bash
wp core download      # Descargar archivos WP
wp config create     # Crear wp-config.php
wp core install      # Instalar WP (crear tablas BD)
wp user create       # Crear usuarios
```

**PHP-FPM**: FastCGI Process Manager
- Maneja procesos PHP de forma eficiente
- Escucha en puerto 9000
- NGINX envía requests PHP vía FastCGI

**Health Checks**: Esperar servicios dependientes
```bash
while ! mysqladmin ping -h"$HOST" -u"$USER" -p"$PASS" --silent; do
    echo "Waiting for MariaDB..."
    sleep 2
done
```

**Parsing Variables**:
```bash
WORDPRESS_DB_HOST=mariadb:3306
HOST="${WORDPRESS_DB_HOST%:*}"    # mariadb (quita :3306)
PORT="${WORDPRESS_DB_HOST#*:}"    # 3306 (quita mariadb:)
```

---

## Conceptos Clave

### 1. PID 1 y Procesos en Contenedores

En contenedores, el proceso principal debe:
- **No terminar**: Si PID 1 termina, el contenedor muere
- **Manejar señales**: Responder a SIGTERM para shutdown limpio
- **Ejecutar en foreground**: No hacer fork/daemon

```dockerfile
# ❌ Incorrecto
CMD ["nginx"]                    # nginx hace fork, PID 1 termina

# ✅ Correcto
CMD ["nginx", "-g", "daemon off;"]  # nginx ejecuta en foreground
```

**Comandos problemáticos para PID 1:**
```bash
tail -f /var/log/nginx/access.log   # Hack, no es robusto
sleep infinity                      # Hack, no hace nada útil
while true; do sleep 1; done        # Hack, consume CPU
```

### 2. Secrets vs Environment Variables

#### Environment Variables (.env)
```bash
DOMAIN_NAME=jvalle-d.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
```

**Características:**
- Visibles en `docker inspect`
- Visibles en `/proc/1/environ`
- Adecuadas para configuración no sensible

#### Docker Secrets
```yaml
secrets:
  db_password:
    file: ./secrets/db_password.txt

services:
  mariadb:
    secrets:
      - db_password
```

**Características:**
- Montadas en `/run/secrets/` (tmpfs, memoria)
- No visibles en `docker inspect`
- Adecuadas para datos sensibles

**Leer secrets en scripts:**
```bash
PASSWORD=$(cat /run/secrets/db_password)
```

### 3. Redes Docker

#### Bridge Network (Por defecto)
```yaml
networks:
  inception_network:
    driver: bridge
```

**Características:**
- Red privada aislada
- DNS automático por nombre de servicio
- NAT para acceso externo

#### Host Network (Prohibido en el proyecto)
```yaml
network_mode: host  # ❌ No usar
```
- Contenedor usa stack de red del host directamente
- Sin aislamiento de red
- Riesgo de seguridad

#### Resolución DNS Interna
```bash
# Dentro del contenedor wordpress:
ping mariadb           # Resuelve a IP del contenedor mariadb
curl http://nginx:80   # Conecta al contenedor nginx
```

### 4. Volumes vs Bind Mounts vs tmpfs

#### Named Volumes
```yaml
volumes:
  db_data:
    # Docker manage la ubicación
```
- Docker controla ubicación
- Mejor para datos que no necesitas acceder desde host

#### Bind Mounts
```yaml
volumes:
  - /host/path:/container/path
```
- Mapeo directo de directorio host
- Útil para desarrollo y acceso desde host

#### Bind Mounts como Named Volumes (Usado en proyecto)
```yaml
volumes:
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/jvalle-d/data/wordpress
```
- Combina flexibilidad de bind mount con abstracción de volume
- Ubicación específica pero manteniendo la sintaxis de volumes

#### tmpfs Mounts
```yaml
tmpfs:
  - /tmp:noexec,nosuid,size=100m
```
- Montado en memoria RAM
- Volátil (se pierde al parar contenedor)
- Útil para datos temporales sensibles

### 5. Restart Policies

```yaml
restart: unless-stopped
```

**Opciones:**
- `no`: No reiniciar automáticamente
- `always`: Siempre reiniciar si para
- `on-failure`: Solo si falla (exit code ≠ 0)
- `unless-stopped`: Reiniciar excepto si se paró manualmente

### 6. Dependencies y Startup Order

```yaml
depends_on:
  - mariadb
  - wordpress
```

**Important**: `depends_on` solo controla orden de inicio, NO espera que el servicio esté listo.

**Solución**: Health checks en scripts
```bash
# En setup-wordpress.sh
while ! mysqladmin ping -h"$DB_HOST" -u"$USER" -p"$PASS" --silent; do
    echo "Waiting for MariaDB..."
    sleep 2
done
```

---

## Configuraciones Críticas

### Makefile
```makefile
all: build up

build:
	docker compose -f srcs/docker-compose.yml build

up:
	docker compose -f srcs/docker-compose.yml up -d

down:
	docker compose -f srcs/docker-compose.yml down

stop:
	docker compose -f srcs/docker-compose.yml stop

start:
	docker compose -f srcs/docker-compose.yml start

clean: down
	docker system prune -af
	docker volume prune -f

fclean: clean
	docker volume rm srcs_wordpress_data srcs_mariadb_data 2>/dev/null || true

re: fclean all

.PHONY: all build up down stop start clean fclean re
```

**Comandos clave:**
- `docker system prune -af`: Elimina imágenes, contenedores, redes no usadas
- `docker volume prune -f`: Elimina volúmenes no usados
- `2>/dev/null || true`: Suprimir errores si volume no existe

### Archivo .env
```bash
# Domain Configuration
DOMAIN_NAME=jvalle-d.42.fr

# Data Directory
DATA_DIR=/home/$USER/data

# MySQL/MariaDB Setup
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=wpdbpassword123
MYSQL_ROOT_PASSWORD=rootpassword123
MYSQL_ROOT_PASSWORD_FILE=/run/secrets/db_root_password
MYSQL_PASSWORD_FILE=/run/secrets/db_password

# WordPress Setup
WORDPRESS_DB_HOST=mariadb:3306
WORDPRESS_DB_NAME=wordpress
WORDPRESS_DB_USER=wpuser
WORDPRESS_TABLE_PREFIX=wp_

# WordPress Admin User
WORDPRESS_ADMIN_USER=jvalled
WORDPRESS_ADMIN_EMAIL=jvalle-d@student.42malaga.com
WORDPRESS_ADMIN_PASS=fYGsROXgRTo7j1&mmk

# WordPress Regular User
WORDPRESS_USER=wpuser2
WORDPRESS_USER_EMAIL=wpuser2@student.42.fr
```

### /etc/hosts Configuration
```bash
127.0.0.1 jvalle-d.42.fr
```

**¿Por qué necesario?**
- El dominio `jvalle-d.42.fr` debe resolverse a localhost
- Sin esto, el navegador no puede encontrar el sitio
- En producción, esto se haría con DNS real

---

## Scripts de Automatización

### Setup WordPress Script

**Análisis línea por línea:**

```bash
#!/bin/bash
cd /var/www/html
```
- Shebang: especifica intérprete
- Cambiar al directorio de trabajo de WordPress

```bash
if [ ! -f wp-config.php ]; then
```
- Verificar si WordPress ya está configurado
- `! -f` = archivo NO existe

```bash
MYSQL_PASSWORD=$(cat /run/secrets/db_password)
```
- Command substitution: `$(comando)`
- Leer contraseña desde secret montado en memoria

```bash
while ! mysqladmin ping -h"${WORDPRESS_DB_HOST%:*}" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent; do
    echo "Waiting for MariaDB..."
    sleep 2
done
```
- **Loop de espera**: hasta que BD esté lista
- `${WORDPRESS_DB_HOST%:*}`: parameter expansion, quita `:3306` de `mariadb:3306`
- `mysqladmin ping`: comando para verificar si BD responde

```bash
wp core download --allow-root
```
- `--allow-root`: WP-CLI por defecto no ejecuta como root
- Descarga archivos core de WordPress

```bash
wp config create \
    --dbname="${WORDPRESS_DB_NAME}" \
    --dbuser="${MYSQL_USER}" \
    --dbpass="${MYSQL_PASSWORD}" \
    --dbhost="${WORDPRESS_DB_HOST}" \
    --allow-root
```
- Crea `wp-config.php` con configuración BD
- `\` para continuar comando en nueva línea

```bash
wp core install \
    --url="https://${DOMAIN_NAME}" \
    --title="Inception" \
    --admin_user="${WORDPRESS_ADMIN_USER}" \
    --admin_password="$(cat /run/secrets/credentials | grep WORDPRESS_ADMIN_PASSWORD | cut -d'=' -f2)" \
    --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
    --allow-root
```
- **Pipeline complex**: `cat | grep | cut`
  - `grep WORDPRESS_ADMIN_PASSWORD`: busca línea con esa clave
  - `cut -d'=' -f2`: usa `=` como delimitador, toma campo 2

```bash
wp user create "${WORDPRESS_USER}" "${WORDPRESS_USER_EMAIL}" \
    --role=author \
    --allow-root
```
- Crea segundo usuario con rol "author"
- Author puede crear posts pero no gestionar sitio

```bash
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
```
- **Permisos críticos**: archivos deben pertenecer a `www-data`
- `755`: propietario rwx, grupo rx, otros rx

```bash
exec /usr/sbin/php-fpm7.4 -F
```
- `exec`: reemplaza proceso actual
- `-F`: ejecuta en foreground (no daemon)

### Init Database Script

```bash
if [ ! -d "/var/lib/mysql/mysql" ]; then
```
- Verificar si BD está inicializada
- Directorio `mysql` contiene tablas del sistema

```bash
mysql_install_db --user=mysql --datadir=/var/lib/mysql
```
- Crear estructura inicial de MariaDB
- `--user=mysql`: ejecutar como usuario mysql
- `--datadir`: donde almacenar archivos de BD

```bash
mysqld --user=mysql --bootstrap << EOF
USE mysql;
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF
```
- **Heredoc con EOF**: permite SQL multilínea
- **Bootstrap mode**: ejecuta SQL durante inicialización
- `'user'@'%'`: usuario desde cualquier host
- `GRANT ALL PRIVILEGES`: permisos completos en BD wordpress

```bash
exec mysqld --user=mysql --console
```
- `--console`: logs a stdout (no archivos)
- Permite que Docker capture logs

---

## Redes y Comunicación

### Docker Network Deep Dive

#### Cómo se comunican los contenedores

1. **DNS Resolution**:
```bash
# Dentro de contenedor nginx:
nslookup wordpress
# Retorna: wordpress.srcs_inception_network
```

2. **IP Assignment**:
```bash
docker network inspect srcs_inception_network
```
```json
{
    "Containers": {
        "mariadb": {
            "IPv4Address": "172.18.0.2/16"
        },
        "wordpress": {
            "IPv4Address": "172.18.0.3/16"
        },
        "nginx": {
            "IPv4Address": "172.18.0.4/16"
        }
    }
}
```

3. **Port Mapping**:
```yaml
nginx:
  ports:
    - "443:443"    # Solo nginx expone puerto al host
```

#### Flujo de Comunicación

**Request HTTP/S Normal:**
1. Browser → `https://jvalle-d.42.fr:443`
2. OS → lookup `/etc/hosts` → `127.0.0.1`
3. Browser → `https://127.0.0.1:443`
4. Docker → forward to nginx container
5. nginx → SSL termination
6. nginx → `fastcgi_pass wordpress:9000`
7. Docker DNS → resolve `wordpress` → `172.18.0.3`
8. nginx → FastCGI request → `172.18.0.3:9000`
9. WordPress → procesa PHP
10. WordPress → conecta BD: `mysqli_connect('mariadb', 'wpuser', 'pass', 'wordpress')`
11. Docker DNS → resolve `mariadb` → `172.18.0.2`
12. WordPress → MySQL query → `172.18.0.2:3306`

#### Network Security

**Aislamiento**:
- Contenedores en different networks NO pueden comunicarse
- Solo contenedores en `inception_network` se ven entre sí

**Port Exposure**:
```yaml
# ❌ Expondrías BD directamente
mariadb:
  ports:
    - "3306:3306"

# ✅ Solo interno
mariadb:
  expose:
    - "3306"
```

### FastCGI Protocol

#### ¿Qué es FastCGI?

FastCGI es un protocolo binario para comunicación entre web server y application server.

**CGI tradicional** (lento):
```
1. Request → Web Server
2. Web Server → fork() nuevo proceso
3. Ejecutar script PHP
4. Script termina
5. Response ← Web Server
```

**FastCGI** (rápido):
```
1. Pool de procesos PHP ya ejecutándose
2. Request → Web Server
3. Web Server → envía request a proceso existente
4. Proceso PHP responde
5. Response ← Web Server
6. Proceso PHP sigue vivo para próximo request
```

#### Configuración NGINX ↔ PHP-FPM

**NGINX side** (nginx.conf):
```nginx
location ~ \.php$ {
    fastcgi_pass wordpress:9000;    # Dirección del pool PHP-FPM
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_param QUERY_STRING $query_string;
    fastcgi_param REQUEST_METHOD $request_method;
    # ... más parámetros ...
    include fastcgi_params;
}
```

**PHP-FPM side** (www.conf):
```ini
[www]
listen = 0.0.0.0:9000        ; Escuchar en todas las interfaces
pm = dynamic                 ; Gestión dinámica de procesos
pm.max_children = 50         ; Máximo 50 procesos hijo
pm.start_servers = 2         ; Empezar con 2 procesos
pm.min_spare_servers = 1     ; Mínimo 1 proceso en espera
pm.max_spare_servers = 3     ; Máximo 3 procesos en espera
```

#### Variables FastCGI Importantes

```nginx
fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
```
- `$document_root`: `/var/www/html`
- `$fastcgi_script_name`: `/index.php`
- Resultado: `/var/www/html/index.php`

**PHP $_SERVER variables**:
```php
<?php
echo $_SERVER['SCRIPT_FILENAME']; // /var/www/html/index.php
echo $_SERVER['SERVER_NAME'];     // jvalle-d.42.fr
echo $_SERVER['HTTPS'];           // on
?>
```

---

## Persistencia de Datos

### Tipos de Storage en Docker

#### 1. Container Layer (Ephemeral)
```dockerfile
RUN echo "data" > /tmp/file.txt
```
- Datos se pierden al eliminar contenedor
- Útil para archivos temporales

#### 2. Bind Mounts
```yaml
volumes:
  - /host/data:/container/data
```
- Mapeo directo host ↔ contenedor
- Host controla ubicación

#### 3. Named Volumes
```yaml
volumes:
  my_data:
    driver: local
```
- Docker controla ubicación
- Mejor portabilidad entre hosts

#### 4. Bind Mount + Named Volume (Proyecto)
```yaml
volumes:
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/jvalle-d/data/wordpress

services:
  wordpress:
    volumes:
      - wordpress_data:/var/www/html
```
- Combina lo mejor de ambos mundos
- Ubicación específica pero abstracción de volume

### Directorios Críticos

#### WordPress Data (`/var/www/html`)
```
/var/www/html/
├── index.php                 # Entry point de WordPress
├── wp-config.php            # Configuración (BD, keys, etc.)
├── wp-content/              # Contenido customizable
│   ├── themes/              # Temas
│   ├── plugins/             # Plugins
│   └── uploads/             # Media subida por usuarios
├── wp-admin/                # Panel administrativo
└── wp-includes/             # Core WordPress (no tocar)
```

**Archivos importantes:**
- `wp-config.php`: Configuración BD, security keys
- `wp-content/`: TODO el contenido personalizado
- `.htaccess`: Reglas de rewrite (si se usa Apache)

#### MariaDB Data (`/var/lib/mysql`)
```
/var/lib/mysql/
├── mysql/                   # Tablas del sistema
│   ├── user.frm            # Estructura tabla usuarios
│   └── user.MYD            # Datos de usuarios
├── wordpress/               # BD del proyecto
│   ├── wp_posts.frm        # Estructura posts
│   ├── wp_posts.MYD        # Datos posts
│   └── wp_users.MYD        # Datos usuarios WP
├── ibdata1                  # InnoDB shared tablespace
├── ib_logfile0             # Transaction log
└── mysql.sock              # Socket para conexiones locales
```

**Tipos de archivos:**
- `.frm`: Estructura de tablas (formato)
- `.MYD`: Datos de tablas MyISAM
- `.MYI`: Índices MyISAM
- `ibdata*`: Datos InnoDB
- `ib_logfile*`: Logs de transacciones

### Backup & Restore

#### Backup WordPress
```bash
# Archivos
tar -czf wp-files-$(date +%Y%m%d).tar.gz /home/jvalle-d/data/wordpress

# BD desde contenedor
docker exec mariadb mysqldump -u root -p wordpress > wp-db-$(date +%Y%m%d).sql
```

#### Restore WordPress
```bash
# Parar servicios
make down

# Restaurar archivos
tar -xzf wp-files-20231201.tar.gz -C /

# Restaurar BD
make up -d mariadb  # Solo BD
docker exec -i mariadb mysql -u root -p wordpress < wp-db-20231201.sql
make up -d          # Resto servicios
```

#### Backup Script Automatizado
```bash
#!/bin/bash
BACKUP_DIR="/backups/inception-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup volumes
cp -r /home/jvalle-d/data "$BACKUP_DIR/"

# Backup config
cp -r secrets "$BACKUP_DIR/"
cp srcs/.env "$BACKUP_DIR/"

# DB dump
docker exec mariadb mysqldump -u root -p${MYSQL_ROOT_PASSWORD} wordpress > "$BACKUP_DIR/wordpress.sql"

# Comprimir
tar -czf "$BACKUP_DIR.tar.gz" "$BACKUP_DIR"
rm -rf "$BACKUP_DIR"

echo "Backup created: $BACKUP_DIR.tar.gz"
```

---

## Seguridad

### Docker Security Best Practices

#### 1. Non-Root User
```dockerfile
# ❌ Ejecutar como root
CMD ["/bin/bash"]

# ✅ Ejecutar como usuario específico
USER www-data
CMD ["php-fpm"]
```

**En el proyecto:**
- nginx: ejecuta como `nginx`
- php-fpm: ejecuta como `www-data`
- mysql: ejecuta como `mysql`

#### 2. Secrets Management

**❌ Hardcoded secrets:**
```yaml
environment:
  MYSQL_ROOT_PASSWORD: secretpassword123
```

**✅ External secrets:**
```yaml
secrets:
  db_password:
    file: ./secrets/db_password.txt

services:
  mariadb:
    secrets:
      - db_password
```

**Dentro del contenedor:**
```bash
# Secrets se montan en tmpfs (memoria)
ls -la /run/secrets/
-r--r--r-- 1 root root 16 Dec 11 23:34 db_password

# No están en environment
env | grep -i password
# (vacío)
```

#### 3. Network Isolation

```yaml
networks:
  frontend:    # Solo nginx
  backend:     # nginx + wordpress
  database:    # wordpress + mariadb
```

**En el proyecto** (simplificado):
```yaml
networks:
  inception_network:  # Todos los servicios
```

#### 4. Least Privilege

**File permissions:**
```bash
# WordPress files
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Secrets
chmod 600 secrets/*
```

**Container capabilities:**
```yaml
security_opt:
  - no-new-privileges:true   # Prevenir escalación
cap_drop:
  - ALL                      # Drop all capabilities
cap_add:
  - NET_BIND_SERVICE         # Solo si necesita port < 1024
```

### SSL/TLS Configuration

#### Certificate Generation
```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=ES/ST=Madrid/L=Madrid/O=42/OU=42Madrid/CN=jvalle-d.42.fr"
```

**Parámetros:**
- `-x509`: Crear certificado auto-firmado
- `-nodes`: Sin password para clave privada
- `-days 365`: Válido por 1 año
- `-newkey rsa:2048`: Generar clave RSA 2048-bit
- `-subj`: Subject sin input interactivo

#### NGINX SSL Config
```nginx
server {
    listen 443 ssl;

    # Certificados
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;

    # Protocolos seguros únicamente
    ssl_protocols TLSv1.2 TLSv1.3;

    # Ciphers seguros
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    ssl_prefer_server_ciphers off;

    # HSTS (opcional)
    add_header Strict-Transport-Security "max-age=31536000" always;
}
```

#### ¿Por qué TLS 1.2/1.3 solamente?

**Protocolos obsoletos/inseguros:**
- SSL 2.0/3.0: Vulnerabilidades conocidas
- TLS 1.0/1.1: Cifrados débiles, vulnerabilidades

**TLS 1.2/1.3:**
- Cifrados fuertes (AES-GCM, ChaCha20)
- Perfect Forward Secrecy
- Protección contra ataques conocidos

### Credential Security

#### Environment Variables vs Secrets

**Environment variables** (visible en inspect):
```bash
docker inspect wordpress | grep -A 10 "Env"
# Muestra todas las variables de entorno
```

**Secrets** (no visible):
```bash
docker inspect wordpress | grep -i secret
# No muestra contenido de secrets
```

#### Password Policies

**Strong passwords:**
- Mínimo 12 caracteres
- Mayúsculas, minúsculas, números, símbolos
- No palabras de diccionario
- Únicos por servicio

**En el proyecto:**
```bash
# Generar password segura
openssl rand -base64 32

# O usando pwgen
pwgen -s 16 1
```

#### Secret Rotation

**Cambiar secrets:**
1. Parar servicios: `make down`
2. Actualizar archivos en `secrets/`
3. Limpiar volúmenes: `make fclean`
4. Reconstruir: `make`

**Importante**: Cambiar secrets requiere reinicializar BD (perde datos).

---

## Debugging y Troubleshooting

### Debugging Tools

#### 1. Container Logs
```bash
# Logs en tiempo real
docker logs -f nginx
docker logs -f wordpress
docker logs -f mariadb

# Últimas N líneas
docker logs --tail 50 wordpress

# Logs con timestamps
docker logs -t wordpress

# Logs desde cierto tiempo
docker logs --since "2023-12-01T10:00:00" nginx
```

#### 2. Container Inspection
```bash
# Información completa del contenedor
docker inspect wordpress

# Solo IP address
docker inspect wordpress | jq '.[0].NetworkSettings.IPAddress'

# Solo mounts
docker inspect wordpress | jq '.[0].Mounts'

# Solo environment variables
docker inspect wordpress | jq '.[0].Config.Env'
```

#### 3. Proceso Debugging
```bash
# Procesos en contenedor
docker exec wordpress ps aux

# Uso de memoria/CPU
docker stats

# Shell interactivo
docker exec -it wordpress bash

# Ejecutar comando específico
docker exec wordpress wp user list --allow-root
```

#### 4. Network Debugging
```bash
# Listar redes
docker network ls

# Inspeccionar red
docker network inspect srcs_inception_network

# Test conectividad
docker exec nginx ping wordpress
docker exec wordpress ping mariadb

# Test puerto específico
docker exec wordpress nc -zv mariadb 3306
```

### Common Issues & Solutions

#### Issue 1: Container Exits Immediately
```bash
# Check exit code
docker ps -a
# STATUS: Exited (0) or Exited (1)

# Check logs
docker logs container_name
```

**Common causes:**
- CMD/ENTRYPOINT ejecuta en background (daemon)
- Missing dependencies
- Configuration errors
- Permission issues

**Solutions:**
```dockerfile
# Ensure foreground execution
CMD ["nginx", "-g", "daemon off;"]
CMD ["php-fpm", "-F"]
CMD ["mysqld", "--console"]
```

#### Issue 2: Cannot Connect to Database
```bash
# Test from WordPress container
docker exec wordpress mysqladmin ping -h mariadb -u wpuser -p

# Check MariaDB user table
docker exec mariadb mysql -u root -p -e "SELECT User, Host FROM mysql.user;"

# Check grants
docker exec mariadb mysql -u root -p -e "SHOW GRANTS FOR 'wpuser'@'%';"
```

**Common causes:**
- User doesn't exist: `CREATE USER ...`
- Wrong host permission: `'user'@'%'` vs `'user'@'localhost'`
- Wrong password: Check secrets consistency
- Database doesn't exist: `CREATE DATABASE ...`

**Solutions:**
```sql
CREATE USER 'wpuser'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'%';
FLUSH PRIVILEGES;
```

#### Issue 3: WordPress Shows Database Error
```bash
# Check wp-config.php
docker exec wordpress cat /var/www/html/wp-config.php | grep DB_

# Test connection manually
docker exec wordpress php -r "
$link = mysqli_connect('mariadb', 'wpuser', 'password', 'wordpress');
if (!$link) {
    die('Connection failed: ' . mysqli_connect_error());
}
echo 'Connected successfully';
mysqli_close($link);
"
```

#### Issue 4: NGINX 502 Bad Gateway
```bash
# Check if php-fpm is running
docker exec wordpress ps aux | grep php-fpm

# Check php-fpm logs
docker exec wordpress tail /var/log/php7.4-fpm.log

# Test php-fpm port
docker exec nginx nc -zv wordpress 9000
```

**Common causes:**
- PHP-FPM not running
- Wrong FastCGI configuration
- PHP syntax errors
- Resource exhaustion

#### Issue 5: Permission Denied Errors
```bash
# Check file ownership
docker exec wordpress ls -la /var/www/html/

# Check running user
docker exec wordpress whoami
docker exec wordpress ps aux

# Fix ownership
docker exec wordpress chown -R www-data:www-data /var/www/html
docker exec wordpress chmod -R 755 /var/www/html
```

#### Issue 6: Volumes Not Mounting
```bash
# Check volume mounts
docker inspect wordpress | jq '.[0].Mounts'

# Check host directory
ls -la /home/jvalle-d/data/wordpress

# Check SELinux (if enabled)
sestatus
# If enabled, may need: chcon -Rt svirt_sandbox_file_t /home/jvalle-d/data
```

### Debugging Workflow

#### 1. Identify the Problem
```bash
# Overview
docker-compose ps
docker-compose logs

# Identify failing service
docker logs failing_service
```

#### 2. Isolate the Service
```bash
# Test service individually
docker run --rm -it service_image bash

# Check build process
docker build --no-cache -t debug_image ./path/to/dockerfile
```

#### 3. Test Connectivity
```bash
# Network connectivity
docker network ls
docker network inspect network_name

# DNS resolution
docker exec container nslookup service_name
docker exec container ping service_name

# Port connectivity
docker exec container nc -zv target_host target_port
```

#### 4. Check Configuration
```bash
# Environment variables
docker exec container env

# Configuration files
docker exec container cat /etc/config/file

# Secrets
docker exec container ls -la /run/secrets/
docker exec container cat /run/secrets/secret_name
```

#### 5. Process Analysis
```bash
# Running processes
docker exec container ps aux

# Resource usage
docker stats container

# System calls (advanced)
docker exec container strace -p PID
```

---

## Preguntas de Evaluación

### Preguntas Conceptuales

#### 1. Docker Fundamentals

**P: ¿Cuál es la diferencia entre una imagen y un contenedor?**

R: Una imagen es una plantilla inmutable que contiene el código, dependencias y configuración necesarios para ejecutar una aplicación. Un contenedor es una instancia ejecutable de esa imagen que tiene estado y puede escribir datos.

**P: ¿Por qué usamos `daemon off` en nginx?**

R: En un contenedor, el proceso principal (PID 1) no debe terminar. Si nginx ejecuta en modo daemon (background), el proceso padre termina y el contenedor se cierra. `daemon off` hace que nginx ejecute en foreground como PID 1.

**P: ¿Qué es un volumen bind mount?**

R: Es un mapeo directo entre un directorio del host y un directorio del contenedor. Permite que los datos persistan más allá del ciclo de vida del contenedor y sean accesibles desde el host.

#### 2. Arquitectura de la Aplicación

**P: Describe el flujo de una petición HTTP desde el cliente hasta la base de datos.**

R:
1. Cliente → HTTPS request → nginx:443
2. nginx → SSL termination → FastCGI to wordpress:9000
3. wordpress → MySQL query → mariadb:3306
4. mariadb → return data → wordpress
5. wordpress → generate HTML → nginx
6. nginx → HTTPS response → client

**P: ¿Por qué WordPress y nginx están en contenedores separados?**

R: Siguiendo el principio de "un servicio por contenedor", esto permite:
- Escalabilidad independiente
- Aislamiento de fallos
- Actualizaciones independientes
- Mejor debuging
- Reutilización de componentes

#### 3. Networking

**P: ¿Cómo se comunican los contenedores entre sí?**

R: Docker crea una red bridge automática con DNS interno. Los contenedores pueden referirse entre sí por nombre de servicio (ej: `wordpress`, `mariadb`), que Docker resuelve a las IPs internas correspondientes.

**P: ¿Por qué solo nginx expone puertos al host?**

R: Siguiendo el principio de "single point of entry", nginx actúa como gateway/proxy único. Esto mejora la seguridad al no exponer servicios internos directamente y permite terminación SSL centralizada.

#### 4. Seguridad

**P: ¿Cuál es la diferencia entre secrets y environment variables?**

R:
- Environment variables: visibles en `docker inspect`, adecuadas para configuración no sensible
- Secrets: montados en `/run/secrets/` (tmpfs), no visibles en inspect, adecuados para passwords/keys

**P: ¿Por qué usamos solo TLS 1.2 y 1.3?**

R: Las versiones anteriores (SSL 2.0/3.0, TLS 1.0/1.1) tienen vulnerabilidades conocidas y cifrados débiles. TLS 1.2/1.3 ofrecen cifrados fuertes, perfect forward secrecy y protección contra ataques conocidos.

#### 5. Persistencia de Datos

**P: ¿Qué sucede con los datos si eliminas un contenedor?**

R: Los datos en el container layer se pierden. Solo persisten los datos en volúmenes externos (bind mounts o named volumes). Por eso montamos `/var/www/html` y `/var/lib/mysql` como volúmenes.

**P: ¿Cómo funciona el sistema de volúmenes en este proyecto?**

R: Usamos bind mounts configurados como named volumes. Los datos se almacenan en `/home/jvalle-d/data/` del host y se montan en las rutas correspondientes de los contenedores, combinando control de ubicación con abstracción de volumes.

### Preguntas Técnicas

#### 1. Scripts

**P: Explica el propósito del health check en setup-wordpress.sh**

R:
```bash
while ! mysqladmin ping -h"${WORDPRESS_DB_HOST%:*}" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent; do
    echo "Waiting for MariaDB..."
    sleep 2
done
```
WordPress depende de MariaDB. Este loop espera hasta que la base de datos esté lista para conexiones antes de intentar configurar WordPress, evitando errores de conexión.

**P: ¿Qué hace `${WORDPRESS_DB_HOST%:*}`?**

R: Es parameter expansion en bash. Si `WORDPRESS_DB_HOST=mariadb:3306`, esta expresión quita todo desde `:` hacia la derecha, resultando en `mariadb`. Es útil para extraer solo el hostname sin el puerto.

#### 2. Comandos Docker

**P: ¿Cuál es la diferencia entre `docker-compose down` y `docker-compose stop`?**

R:
- `stop`: Para los contenedores pero los mantiene (se pueden reiniciar con `start`)
- `down`: Para y elimina contenedores, pero mantiene volúmenes e imágenes

**P: ¿Qué hace `make fclean`?**

R: Hace limpieza completa:
1. Para y elimina contenedores (`down`)
2. Elimina imágenes unused (`docker system prune -af`)
3. Elimina volúmenes unused (`docker volume prune -f`)
4. Elimina volúmenes específicos del proyecto

#### 3. Configuraciones

**P: Explica la configuración de PHP-FPM `pm = dynamic`**

R: Gestión dinámica de procesos hijo:
- `pm.start_servers`: Procesos iniciales
- `pm.min_spare_servers`: Mínimo procesos en espera
- `pm.max_spare_servers`: Máximo procesos en espera
- `pm.max_children`: Límite total de procesos
- Ajusta automáticamente según carga

**P: ¿Por qué es importante `fastcgi_param SCRIPT_FILENAME`?**

R: Le dice a PHP-FPM qué archivo PHP ejecutar. Sin esto, PHP-FPM no sabría qué script procesar cuando recibe un request de nginx.

### Preguntas de Troubleshooting

#### 1. Problemas Comunes

**P: El contenedor WordPress sale inmediatamente. ¿Cómo lo debugeas?**

R:
1. `docker logs wordpress` - verificar errores
2. `docker ps -a` - verificar exit code
3. Posibles causas: script falla, dependencias missing, permisos
4. Test manual: `docker run --rm -it wordpress_image bash`

**P: WordPress muestra "Error establishing database connection". ¿Qué verificas?**

R:
1. MariaDB está running: `docker ps | grep mariadb`
2. Conectividad de red: `docker exec wordpress ping mariadb`
3. Credenciales correctas: comparar `.env` con `secrets/`
4. Usuario existe: `docker exec mariadb mysql -u root -p -e "SELECT User, Host FROM mysql.user;"`
5. Base de datos existe: `SHOW DATABASES;`

#### 2. Diagnóstico

**P: ¿Cómo verificas que la configuración SSL de nginx es correcta?**

R:
```bash
# Test configuración
docker exec nginx nginx -t

# Verificar certificados
docker exec nginx openssl x509 -in /etc/nginx/ssl/nginx.crt -text -noout

# Test conexión SSL
openssl s_client -connect jvalle-d.42.fr:443

# Test desde cliente
curl -k https://jvalle-d.42.fr
```

**P: Los volúmenes no montan correctamente. ¿Qué verificas?**

R:
1. Directorio host existe: `ls -la /home/jvalle-d/data/`
2. Permisos correctos: `ls -la /home/jvalle-d/`
3. SELinux (si enabled): `getenforce`
4. Docker inspect: `docker inspect wordpress | jq '.[0].Mounts'`
5. Space disponible: `df -h /home/jvalle-d/`

### Preguntas de Optimización

**P: ¿Cómo optimizarías el build time de las imágenes?**

R:
1. **Layer caching**: instrucciones que cambian menos al principio
2. **.dockerignore**: excluir archivos innecesarios
3. **Multi-stage builds**: si necesitas tools de build pero no en runtime
4. **Base image**: usar imágenes más específicas (nginx:alpine vs debian:bullseye)
5. **Cleanup**: `rm -rf /var/lib/apt/lists/*` después de instalar packages

**P: ¿Cómo mejorarías la seguridad?**

R:
1. **Non-root users**: todos los servicios con usuario específico
2. **Read-only containers**: donde sea posible
3. **Drop capabilities**: `cap_drop: [ALL]`
4. **Security scan**: `docker scan image_name`
5. **Network segmentation**: redes separadas por función
6. **Resource limits**: CPU/memory limits
7. **Image signing**: verificar integridad de imágenes base

---

## Conclusión

Este manual cubre los conceptos fundamentales del proyecto Inception y Docker en general. Para profundizar:

### Documentación Oficial
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/)
- [WordPress Developer Documentation](https://developer.wordpress.org/)

### Próximos Pasos
1. **Práctica**: Experimenta modificando configuraciones
2. **Monitoring**: Agrega logs centralizados (ELK stack)
3. **CI/CD**: Automatiza builds y deployments
4. **Production**: Health checks, load balancing, auto-scaling
5. **Security**: Implementa scanning automático, secrets rotation

### Conceptos Avanzados
- **Multi-stage builds** para optimizar tamaño de imágenes
- **Docker Swarm** para orquestación en cluster
- **Kubernetes** para orquestación a gran escala
- **Service mesh** (Istio) para microservicios complejos
- **Container security** con herramientas como Falco

¡El dominio de estos conceptos te preparará para entornos DevOps modernos!