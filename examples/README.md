# Example Java Application

This directory contains a simple HTTP server for testing the Java Docker Container Hardener script.

## SimpleApp.java

A minimal Java HTTP server with:
- **Main endpoint** (`/`): Returns "Hello from Hardened Java Container!"
- **Health endpoint** (`/health`): Returns `{"status":"healthy"}`
- Configurable port via `PORT` environment variable (defaults to 8080)

## How to Use

### Prerequisites
- Docker (required - uses Docker to compile)
- Or a local JDK installation

### Compile to JAR

**Option 1: Using Docker (recommended)**
```bash
cd examples
docker run --rm -v "$PWD":/app -w /app eclipse-temurin:17-jdk bash -c "javac SimpleApp.java && echo 'Main-Class: SimpleApp' > manifest.txt && jar cvfm app.jar manifest.txt *.class && rm manifest.txt *.class"
mv app.jar ..
```

**Option 2: Using local JDK**
```bash
cd examples
javac SimpleApp.java
echo 'Main-Class: SimpleApp' > manifest.txt
jar cvfm app.jar manifest.txt *.class
rm manifest.txt *.class
mv app.jar ..
```

### Run the Hardener Script

Once `app.jar` is in the project root:
```bash
cd ..
./java-docker-hardener.sh
```

When prompted:
- Application JAR/WAR filename: `app.jar` (or just press Enter)
- Port: choose your desired port (e.g., 8080)

### Test the Container

```bash
docker compose up --build
```

Then visit:
- http://localhost:8080/ (or your chosen port)
- http://localhost:8080/health

## Clean Up

To remove the compiled JAR after testing:
```bash
rm app.jar
```
