### Project page:
[Basic Dockerfile](https://roadmap.sh/projects/basic-dockerfile)

# How to use:
- Clone the repo:
```sh
git clone https://github.com/s1natex/Basic_Dockerfile
```
- Build the image:
```sh
docker build --build-arg USER_NAME="add-your-name" -t passgen .
```
- Run the image:
```sh
docker run -it passgen
```

# Flask api
A basic python api with flask dockerized and deployed with Docker compose

### Instructions:
- Clone and run:
```
git clone https://github.com/s1natex/Basic_Dockerfile
docker compose up
```
- Test it:
```
localhost:8080/get

curl -X POST http://localhost:8080/post \
     -H "Content-Type: application/json" \
     -d '{"name":"Natan","role":"DevOps"}'
```
