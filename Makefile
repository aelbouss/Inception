all:
	mkdir -p /home/$(USER)/data/mariadb
	mkdir -p /home/$(USER)/data/wordpress
	mkdir -p /home/$(USER)/data/portainer
	docker compose -f srcs/docker-compose.yml up --build -d

up:
	mkdir -p /home/$(USER)/data/mariadb
	mkdir -p /home/$(USER)/data/wordpress
	mkdir -p /home/$(USER)/data/portainer
	docker compose -f srcs/docker-compose.yml up -d --build

down:
	docker compose -f srcs/docker-compose.yml down -v

build:
	docker compose -f srcs/docker-compose.yml build

logs:
	docker compose -f srcs/docker-compose.yml logs -f

clean:
	docker compose -f srcs/docker-compose.yml down --volumes --rmi all

fclean: clean
	sudo rm -rf /home/$(USER)/data/mariadb/* /home/$(USER)/data/wordpress/* /home/$(USER)/data/portainer/* 2>/dev/null || true
	docker system prune -af --volumes

re: fclean all

.PHONY: all up down build logs clean fclean re