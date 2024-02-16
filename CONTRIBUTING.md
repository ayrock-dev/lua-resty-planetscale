# CONTRIBUTING

> :warning: The following local development steps are experimental and highly subject to change.
>
> I am actively seeking improvements to the development/contribution loop.

## Project Structure

```
.
├── /dev
└── /lib
```

The library source code can be found in `/lib`

An example OpenResty nginx app for development can be found in `/dev`

## Setup Steps

To get started with local development, build the dockerfile.

```bash
docker build -f dev/Dockerfile -t lua-resty-planetscale .
```

Then, run the image.

```bash
docker run -p 8000:443 -v ./lib:/usr/local/openresty/site/plugins -v ./dev/conf:/usr/local/openresty/nginx/conf lua-resty-planetscale
```

:bulb: Note: Your database connection variables must be specified. If using the docker command above be sure to include:
`-e "DATABASE_URL=mysql://username:password@host.com/example"`. In standard usage, the connection string may be specified however is convenient for the application.

Then, test changes against the image locally.

```bash
curl https://127.0.0.1:8000
```

## Reloading Changes

Changes to the library source code (the `/lib` folder) require restarting the container (restarting `docker run ...`) to re-mount your source files in docker volumes.

You will only need to rebuild the Docker container (`docker build ...`) if you make changes to the `/dev` folder.
