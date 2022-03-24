# docker_database_dumper
![GitHub Repo stars](https://img.shields.io/github/stars/paolobasso99/docker_database_dumper?label=GITHUB%20STARS&style=for-the-badge)
![Docker Pulls](https://img.shields.io/docker/pulls/paolobasso/database_dumper?style=for-the-badge)
![Docker Image Size (tag)](https://img.shields.io/docker/image-size/paolobasso/database_dumper/latest?style=for-the-badge)

Periodically dump a MySQL or PostgreSQL database to the local system and keep only a maximum number of dumps with a Docker container. Supports [healthchecks.io](https://healthchecks.io/). 

Links:
- [Source code on GitHub](https://github.com/paolobasso99/docker_database_dumper)
- [Image on DockerHub](https://hub.docker.com/r/paolobasso/database_dumper/)

## Why
I wanted a simple container which periodically backup my MySQL and PostgreSQL databases. I wanted to be allerted of failures using [healthchecks.io](https://healthchecks.io/).

I use this image together with a classic file backup setup which saves all the dumps in an incremental way on a remote server.

## Usage
Docker:
```sh
docker run -e DUMPER_TYPE=mysql DUMPER_HOST=db_container -e DUMPER_PORT=5432 -e DUMPER_DATABASE=db_name
-e DUMPER_USER=user -e DUMPER_PASSWORD=password 
-e PUID=1000 -e PGID=1000 
-v ./dumps:/dumps paolobasso/database_dumper:latest
```

Docker Compose:
```yaml
version: '3.8'

services:
  mysql_db:
    image: mariadb:10
    restart: unless-stopped
    container_name: mysql_db
    volumes:
      - ./db:/var/lib/mariadb/data
    environment:
      - DUMPER_DATABASE=mydatabase
      - DUMPER_USER=myuser
      - DUMPER_PASSWORD=${DUMPER_PASSWORD}
      - MYSQL_ROOT_PASSWORD=${DUMPER_PASSWORD}
    networks:
      - db

  database_dumper:
    image: paolobasso/database_dumper:latest
    restart: unless-stopped
    depends_on:
      - mysql_db
    container_name: database_dumper
    volumes:
      - ./dumps:/dumps
    environment:
      - PGID=1000
      - PUID=1000
      - DUMPER_TYPE=mysql
      - DUMPER_DATABASE=mydatabase
      - DUMPER_HOST=mysql_db
      - DUMPER_PORT=3306
      - DUMPER_USER=myuser
      - DUMPER_PASSWORD=${DUMPER_PASSWORD}
      - DUMPER_KEEP=2
      - DUMPER_SCHEDULE=* * * * *
      - DUMPER_HEALTHCHECKS_URL=${BACKUP_HEALTHCHECKS_URL}
    networks:
      - db

networks:
  db:
    driver: bridge
```

### Environment Variables
| Variable                | Description                                                                                | Default          |
| ----------------------- | ------------------------------------------------------------------------------------------ | ---------------- |
| PUID                    | The UserID of the user who will own the dumps.                                             |                  |
| PGID                    | The GroupID of the user who will own the dumps.                                            |                  |
| DUMPER_TYPE             | The type of the database. Can be: `mysql` or `postgres`.                                   |                  |
| DUMPER_DATABASE         | The name of the database to dump.                                                          |                  |
| DUMPER_HOST             | Database connection parameter; host to connect to.                                         |                  |
| DUMPER_PASSWORD         | Database connection parameter; password to connect with.                                   |                  |
| DUMPER_PORT             | Database connection parameter; port to connect to.                                         | `3306` or `5432` |
| DUMPER_USER             | Database connection parameter; user to connect with.                                       |                  |
| DUMPER_SCHEDULE         | [Cron-schedule](https://en.wikipedia.org/wiki/Cron) specifying the interval between dumps. | `0 3 * * *`      |
| DUMPER_KEEP             | The number of dumps to keep.                                                               | `7`              |
| DUMPER_HEALTHCHECKS_URL | The url to an [healthchecks.io](https://healthchecks.io/) application.                     |                  |

### User / Group Identifiers
To find the correct values of `PUID` and `PGID` use `id user` as below:
```bash
$ id username
  uid=1000(username) gid=1000(username) groups=1000(username)
```

### Setting up healthchecks
If you want to use [healthchecks.io](https://healthchecks.io/) in order to be informed if the dump fails you need to set the environment variable `DUMPER_HEALTHCHECKS_URL`.

### Making a dump instantly
Run a one of dump:
```sh
docker run -e DUMPER_TYPE=mysql DUMPER_HOST=db_container -e DUMPER_PORT=5432 -e DUMPER_DATABASE=db_name
-e DUMPER_USER=user -e DUMPER_PASSWORD=password 
-e PUID=1000 -e PGID=1000 
-v ./dumps:/dumps --entrypoint=/dump.sh
paolobasso/database_dumper:latest
```

If the container is running in a deamon mode (i.e. using docker-compose) but you want to run a backup instantly and don't wait for the schedule then:
```sh
docker exec database_dumper /dump.sh
```

