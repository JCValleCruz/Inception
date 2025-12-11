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
