# docker_database_dumper
![GitHub Repo stars](https://img.shields.io/github/stars/paolobasso99/docker_database_dumper?label=GITHUB%20STARS&style=for-the-badge)
![Docker Pulls](https://img.shields.io/docker/pulls/paolobasso/database_dumper?style=for-the-badge)

Periodically dump a MySQL/MariaDB or PostgreSQL database to the local system and keep only a maximum number of dumps with a Docker container. Supports [healthchecks.io](https://healthchecks.io/). 

Links:
- [Source code on GitHub](https://github.com/paolobasso99/docker_database_dumper)
- [Image on DockerHub](https://hub.docker.com/r/paolobasso/database_dumper/)

### Supported tags
- `mariadb` for a MariaDB database
- `mysql` for a MySQL database
- For postgres use the correct version:
  - `postgres-16` for PostgreSQL 16
  - `postgres-15` for PostgreSQL 15
  - `postgres-14` for PostgreSQL 14
  - `postgres-13` for PostgreSQL 13
  - `postgres-12` for PostgreSQL 12

## Why
I wanted a simple container which periodically backup my MySQL and PostgreSQL databases. I wanted to be allerted of failures using [healthchecks.io](https://healthchecks.io/).

I use this image together with a classic file backup setup which saves all the dumps in an incremental way on a remote server.

## Usage
Docker:
```sh
docker run -e DUMPER_HOST=db_container -e DUMPER_PORT=5432 -e DUMPER_DATABASE=db_name
-e DUMPER_USER=user -e DUMPER_PASSWORD=password 
-e PUID=1000 -e PGID=1000 
-v ./dumps:/dumps paolobasso/database_dumper:postgres-15
```

Docker Compose:
```yaml
version: '3.8'

services:
  postgres_db:
    image: postgres:15
    restart: unless-stopped
    container_name: postgres_db
    volumes:
      - ./postgres/db:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=mydatabase
      - POSTGRES_USER=myuser
      - POSTGRES_PASSWORD=${DUMPER_PASSWORD}
    networks:
      - db

  database_dumper_postgres:
    image: paolobasso/database_dumper:postgres-14
    restart: unless-stopped
    depends_on:
      - postgres_db
    container_name: database_dumper_postgres
    volumes:
      - ./postgres/dumps:/dumps
    environment:
      - PGID=1000
      - PUID=1000
      - DUMPER_DATABASE=mydatabase
      - DUMPER_HOST=postgres_db
      - DUMPER_USER=myuser
      - DUMPER_PASSWORD=${DUMPER_PASSWORD}
      - DUMPER_KEEP=7
      - DUMPER_SCHEDULE=0 3 * * *
      - DUMPER_HEALTHCHECKS_URL=${DUMPER_HEALTHCHECKS_URL}
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
| DUMPER_DATABASE         | The name of the database to dump.                                                          |                  |
| DUMPER_HOST             | Database connection parameter; host to connect to.                                         |                  |
| DUMPER_PASSWORD         | Database connection parameter; password to connect with.                                   |                  |
| DUMPER_PORT             | Database connection parameter; port to connect to.                                         | `3306` or `5432` |
| DUMPER_USER             | Database connection parameter; user to connect with.                                       |                  |
| DUMPER_SCHEDULE         | [Cron-schedule](https://en.wikipedia.org/wiki/Cron) specifying the interval between dumps. | `0 3 * * *`      |
| DUMPER_KEEP             | The number of dumps to keep.                                                               | `7`              |
| DUMPER_HEALTHCHECKS_URL | The url to an [healthchecks.io](https://healthchecks.io/) endpoint.                        |                  |

### User / Group Identifiers
To find the correct values of `PUID` and `PGID` use `id user` as below:
```bash
$ id username
  uid=1000(username) gid=1000(username) groups=1000(username)
```

### Setting up healthchecks
If you want to use [healthchecks.io](https://healthchecks.io/) in order to be informed if the dump fails you need to set the environment variable `DUMPER_HEALTHCHECKS_URL`.

### Making a dump instantly
Run a one off dump:
```sh
docker run DUMPER_HOST=db_container -e DUMPER_PORT=5432 -e DUMPER_DATABASE=db_name
-e DUMPER_USER=user -e DUMPER_PASSWORD=password 
-e PUID=1000 -e PGID=1000 
-v ./dumps:/dumps --entrypoint=/dump.sh
paolobasso/database_dumper:postgres-15
```

If the container is running in a deamon mode (i.e. using docker-compose) but you want to run a backup instantly and don't wait for the schedule then:
```sh
docker exec database_dumper /dump.sh
```

