all:
	mkdir -p /home/$(USER)/data/mariadb
	mkdir -p /home/$(USER)/data/wordpress
	docker compose -f srcs/docker-compose.yml up --build -d
up:
	docker compose up -d  --build --no-cache

down:
	docker compose -f srcs/docker-compose.yml down

build:
	docker compose -f srcs/docker compose build

logs:
	docker compose -f srcs/docker compose logs -f

clean:
	docker compose -f srcs/docker compose down --volumes --rmi all

fclean: clean
	sudo rm -rf /home/$(USER)/data/mariadb/*
	sudo rm -rf /home/$(USER)/data/wordpress/*
	docker compose -f srcs/docker system prune -af

re: fclean all

.PHONY: all up down build logs clean fclean re