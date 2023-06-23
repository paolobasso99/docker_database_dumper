# database_dumper build instructions
To build and push all images.

## Prepare environment
Configure you system to use [Docker Buildx](https://docs.docker.com/buildx/working-with-buildx/).

## Generate the images
### Generate build configuration
In order to modify the image name or any other configurable parameter edit the `docker-bake.hcl` file.

### Build the images
In order to only build the images locally run the following command:

```sh
docker buildx bake --pull -f docker-bake.hcl postgres-14
```

In order to publish directly to the repository run this command instead:

```sh
docker buildx bake --pull --push -f docker-bake.hcl postgres-14
```

If you just want to build one image to use locally you can use:
```sh
docker buildx build --load --pull --tag paolobasso/database_dumper:postgres-14 --platform linux/amd64 --target=postgres-14 .
```