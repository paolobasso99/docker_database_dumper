# database_dumper build instructions
To build and push all images.

## Prepare environment
* Configure you system to use [Docker Buildx](https://docs.docker.com/buildx/working-with-buildx/).
* Prepare crosscompile environment (see below).

### Prepare crosscompile environment
In order to work in Arch Linux the following initialization commands will be required:

```sh
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
docker buildx rm multibuilder
docker buildx create --name multibuilder --platform linux/amd64,linux/arm64/v8,linux/ppc64le,linux/s390x --driver docker-container --use
docker buildx inspect --bootstrap
```

## Generate the images
### Generate build configuration
In order to modify the image name or any other configurable parameter edit the `docker-bake.hcl` file.

### Build the images
In order to only build the images locally run the following command:

```sh
docker buildx bake --pull -f docker-bake.hcl
```

In order to publish directly to the repository run this command instead:

```sh
docker buildx bake --pull --push -f docker-bake.hcl
```

If you want to build the image for a specific platform use:
```sh
docker buildx build --pull --platform linux/arm64/v8 .
```
