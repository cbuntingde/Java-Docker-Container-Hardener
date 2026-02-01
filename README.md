# Java Docker Container Hardener

**Created by Chris Bunting** <cbuntingde@gmail.com>

An interactive script that generates secure, hardened Dockerfiles for Java applications based on your specific requirements.

## The Problem This Solves

According to a recent survey of Java developers:
- 48% prefer pre-hardened container images over managing security themselves
- 62% of container security mistakes come from human error
- 23% experienced container-related security incidents in the past year
- Most use bloated general-purpose distributions with unnecessary packages

This script automates the creation of minimal, secure Java containers following industry best practices.

## Features

✅ **Interactive Configuration** - Answer simple questions, get a production-ready Dockerfile  
✅ **Multiple Security Levels** - From maximum security (Distroless) to maximum compatibility (Ubuntu)  
✅ **Best Practice Enforcement** - Non-root users, minimal packages, proper labels  
✅ **Multiple JDK Options** - Eclipse Temurin, Amazon Corretto, Microsoft, Azul Zulu  
✅ **Complete Setup** - Generates Dockerfile, docker-compose.yml, .dockerignore, and documentation  
✅ **Security Scanning** - Includes scan script for Trivy, Grype, and Docker Scout  

## Quick Start

```bash
# Run the interactive script
./java-docker-hardener.sh

# Follow the prompts to configure your container
```

## What It Generates

The script creates:
- **Dockerfile.hardened** - Your custom hardened Dockerfile
- **docker-compose.hardened.yml** - Docker Compose configuration with security options
- **.dockerignore.hardened** - Optimized ignore file
- **DOCKER_README.md** - Complete documentation for your specific setup
- **scan-image.sh** - Security scanning script

## Configuration Options

### Java Version
- Java 8 (LTS)
- Java 11 (LTS)
- Java 17 (LTS)
- Java 21 (LTS)
- Java 23 (Latest)

### Runtime Type
- **JRE only** - Smaller, production-optimized (recommended)
- **Full JDK** - For development or debugging

### Security Levels

1. **Maximum Security (Distroless)**
   - No shell, no package manager
   - Minimal attack surface
   - Best for production

2. **High Security (Alpine)**
   - Minimal Linux distribution
   - Small size (~50MB)
   - Good compatibility

3. **Balanced (Debian Slim)**
   - Broad compatibility
   - Moderate size
   - Well-tested

4. **Standard (Ubuntu)**
   - Maximum compatibility
   - Larger size
   - Good for complex dependencies

### JDK Distributions
- Eclipse Temurin (recommended)
- Amazon Corretto
- Microsoft OpenJDK
- Azul Zulu

### Application Types
- **Executable JAR** - Spring Boot, Micronaut, Quarkus, or any standalone JAR
- **WAR file** - Traditional servlet container applications (Tomcat, Jetty)
- **Standard Java** - Applications with external dependencies/libraries

### Security Hardening Options
- ✅ Run as non-root user
- ✅ Security scanning metadata/labels
- ✅ Minimize installed packages
- ✅ Health checks
- ✅ JVM container-aware settings

## Example Output

For a Java 17 Spring Boot app with maximum security:

```dockerfile
FROM gcr.io/distroless/java17-debian12:nonroot

LABEL org.opencontainers.image.title="Hardened Java Application"
LABEL security.hardening="enabled"

WORKDIR /app
COPY app.jar /app/app.jar

EXPOSE 8080

ENV JAVA_OPTS="-Xmx512m -XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

ENTRYPOINT ["java"]
CMD ["-jar", "/app/app.jar"]
```

## Usage Example

```bash
# 1. Run the script
./java-docker-hardener.sh

# Example selections:
# - Java 17 (LTS)
# - JRE only
# - Maximum Security (Distroless)
# - Eclipse Temurin
# - Executable JAR
# - Yes to all security options

# 2. Place your JAR file
cp target/myapp.jar app.jar

# 3. Build the image
docker build -f Dockerfile.hardened -t myapp:secure .

# 4. Scan for vulnerabilities
./scan-image.sh myapp:secure

# 5. Run the container
docker run -p 8080:8080 myapp:secure
```

## Security Best Practices Implemented

### 1. Minimal Base Images
- Only includes necessary runtime components
- Reduces attack surface by 80%+ compared to full OS images

### 2. Non-Root Execution
- Containers run as unprivileged user
- Limits damage from container breakout

### 3. No Unnecessary Packages
- Removes package managers, build tools, docs
- Fewer components = fewer vulnerabilities

### 4. Container-Aware JVM
- Uses `-XX:+UseContainerSupport`
- Respects cgroup memory limits
- Better resource utilization

### 5. Read-Only Filesystem
- Docker Compose includes `read_only: true`
- Only /tmp is writable

### 6. Dropped Capabilities
- Removes all Linux capabilities
- Only adds what's strictly necessary

### 7. Health Checks
- Built-in container health monitoring
- Automatic restart on failure

## Image Size Comparison

| Base Image | Approximate Size | Use Case |
|------------|-----------------|----------|
| Distroless | 120-150 MB | Maximum security, production |
| Alpine | 150-180 MB | High security, small size |
| Debian Slim | 200-250 MB | Balanced approach |
| Ubuntu | 300-400 MB | Maximum compatibility |

## Security Scanning

The generated `scan-image.sh` script supports:

### Trivy (Recommended)
```bash
trivy image myapp:secure
```

### Grype
```bash
grype myapp:secure
```

### Docker Scout
```bash
docker scout cves myapp:secure
```

## Advanced Usage

### Custom JVM Options

Edit the generated Dockerfile to add specific JVM flags:

```dockerfile
ENV JAVA_OPTS="-Xmx1g -XX:+UseG1GC -XX:+HeapDumpOnOutOfMemoryError"
```

### Multi-Stage Builds

Combine with the script output for even smaller images:

```dockerfile
# Build stage
FROM eclipse-temurin:17-jdk-alpine AS build
WORKDIR /build
COPY . .
RUN ./gradlew build

# Runtime (generated by script)
FROM gcr.io/distroless/java17-debian12:nonroot
COPY --from=build /build/target/app.jar /app/app.jar
# ... rest from generated Dockerfile
```

### Secrets Management

Never hardcode secrets! Use environment variables:

```bash
docker run -e DB_PASSWORD_FILE=/run/secrets/db_pass \
    -v ./secrets:/run/secrets:ro \
    myapp:secure
```

## Troubleshooting

### "No shell" errors with Distroless
Distroless has no shell. To debug:
```bash
# Use debug variant with busybox
FROM gcr.io/distroless/java17-debian12:debug-nonroot
```

### Permission denied errors
Check ownership if using non-root:
```bash
RUN chown -R appuser:appuser /app
```

### Out of memory errors
Increase container memory or tune JVM:
```bash
docker run -m 1g -e JAVA_OPTS="-Xmx800m" myapp:secure
```

## Production Deployment

### Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: java-app
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        fsGroup: 1001
      containers:
      - name: app
        image: myapp:secure
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop: ["ALL"]
```

### Docker Swarm

```bash
docker service create \
    --name myapp \
    --publish 8080:8080 \
    --replicas 3 \
    --update-parallelism 1 \
    --update-delay 10s \
    myapp:secure
```

## Continuous Security

1. **Regular Scans** - Run security scans in CI/CD
2. **Update Base Images** - Rebuild monthly for patches
3. **Monitor CVEs** - Subscribe to security advisories
4. **SBOM Generation** - Track dependencies

```bash
# Generate SBOM
docker sbom myapp:secure
```

## Contributing

Feel free to enhance the script with:
- Additional JDK distributions
- More security hardening options
- Platform-specific optimizations
- Better vulnerability scanning integration

## Resources

- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)
- [Google Distroless Images](https://github.com/GoogleContainerTools/distroless)
- [Eclipse Temurin](https://adoptium.net/)
- [OWASP Container Security](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)

## License

This script is provided as-is for educational and production use.
