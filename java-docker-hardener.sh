#!/bin/bash

# Java Docker Container Hardener
# Interactive script to generate secure, hardened Dockerfiles for Java applications

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print header
clear
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      Java Docker Container Hardener & Generator           ║${NC}"
echo -e "${BLUE}║      Build Secure, Minimal Java Container Images          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to prompt user with options
prompt_choice() {
    local prompt="$1"
    shift
    local options=("$@")

    echo -e "${YELLOW}${prompt}${NC}" >&2
    for i in "${!options[@]}"; do
        echo "  $((i+1)). ${options[$i]}" >&2
    done

    while true; do
        read -p "Enter choice [1-${#options[@]}]: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
            echo "$((choice-1))"
            return 0
        fi
        echo -e "${RED}Invalid choice. Please try again.${NC}" >&2
    done
}

# Function to get yes/no answer
prompt_yes_no() {
    local prompt="$1"
    while true; do
        read -p "${prompt} (y/n): " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer y or n.";;
        esac
    done
}

# Start collecting requirements
echo -e "${GREEN}Let's build your secure Java container!${NC}"
echo ""

# 1. Java Version
echo -e "${BLUE}Step 1: Select Java Version${NC}"
java_versions=("Java 8 (LTS)" "Java 11 (LTS)" "Java 17 (LTS)" "Java 21 (LTS)" "Java 23 (Latest)")
java_choice=$(prompt_choice "Which Java version do you need?" "${java_versions[@]}")

case $java_choice in
    0) JAVA_VERSION="8";;
    1) JAVA_VERSION="11";;
    2) JAVA_VERSION="17";;
    3) JAVA_VERSION="21";;
    4) JAVA_VERSION="23";;
esac

echo -e "${GREEN}✓ Selected: Java ${JAVA_VERSION}${NC}"
echo ""

# 2. JDK vs JRE
echo -e "${BLUE}Step 2: Runtime Type${NC}"
runtime_types=("JRE only (smaller, production)" "Full JDK (development/debugging)")
runtime_choice=$(prompt_choice "Do you need the full JDK or just JRE?" "${runtime_types[@]}")

if [ $runtime_choice -eq 0 ]; then
    RUNTIME_TYPE="jre"
    echo -e "${GREEN}✓ Selected: JRE (smaller footprint)${NC}"
else
    RUNTIME_TYPE="jdk"
    echo -e "${GREEN}✓ Selected: Full JDK${NC}"
fi
echo ""

# 3. Base Image Strategy
echo -e "${BLUE}Step 3: Security Level${NC}"
security_levels=(
    "Maximum Security (Distroless - no shell, minimal attack surface)"
    "High Security (Alpine - minimal Linux, small size)"
    "Balanced (Debian Slim - good compatibility)"
    "Standard (Ubuntu - maximum compatibility)"
)
security_choice=$(prompt_choice "Choose your security/compatibility level:" "${security_levels[@]}")

case $security_choice in
    0) 
        BASE_STRATEGY="distroless"
        echo -e "${GREEN}✓ Selected: Distroless (Maximum Security)${NC}"
        ;;
    1) 
        BASE_STRATEGY="alpine"
        echo -e "${GREEN}✓ Selected: Alpine (High Security, Small Size)${NC}"
        ;;
    2) 
        BASE_STRATEGY="debian"
        echo -e "${GREEN}✓ Selected: Debian Slim (Balanced)${NC}"
        ;;
    3) 
        BASE_STRATEGY="ubuntu"
        echo -e "${GREEN}✓ Selected: Ubuntu (Maximum Compatibility)${NC}"
        ;;
esac
echo ""

# 4. JDK Distribution
echo -e "${BLUE}Step 4: JDK Distribution${NC}"
jdk_distributions=(
    "Eclipse Temurin (recommended, well-maintained)"
    "Amazon Corretto (AWS-backed)"
    "Microsoft OpenJDK"
    "Azul Zulu"
)
jdk_choice=$(prompt_choice "Choose your JDK distribution:" "${jdk_distributions[@]}")

case $jdk_choice in
    0) JDK_DIST="temurin";;
    1) JDK_DIST="corretto";;
    2) JDK_DIST="microsoft";;
    3) JDK_DIST="zulu";;
esac

echo -e "${GREEN}✓ Selected: ${jdk_distributions[$jdk_choice]%% (*}${NC}"
echo ""

# 5. Application Type
echo -e "${BLUE}Step 5: Application Type${NC}"
app_types=(
    "Executable JAR (Spring Boot, etc.)"
    "WAR file (needs servlet container)"
    "Standard Java application (with dependencies)"
)
app_choice=$(prompt_choice "What type of Java application?" "${app_types[@]}")

case $app_choice in
    0) APP_TYPE="jar";;
    1) APP_TYPE="war";;
    2) APP_TYPE="standard";;
esac
echo ""

# 6. Additional Security Features
echo -e "${BLUE}Step 6: Additional Security Hardening${NC}"
echo ""

if prompt_yes_no "Run as non-root user?"; then
    NONROOT=true
    echo -e "${GREEN}✓ Will create non-root user${NC}"
else
    NONROOT=false
fi

if prompt_yes_no "Add security scanning metadata (labels)?"; then
    ADD_LABELS=true
    echo -e "${GREEN}✓ Will add security labels${NC}"
else
    ADD_LABELS=false
fi

if prompt_yes_no "Minimize installed packages (remove caches, docs)?"; then
    MINIMIZE=true
    echo -e "${GREEN}✓ Will minimize image${NC}"
else
    MINIMIZE=false
fi

if prompt_yes_no "Add health check?"; then
    ADD_HEALTHCHECK=true
    read -p "Health check URL path (e.g., /health): " HEALTHCHECK_PATH
    HEALTHCHECK_PATH=${HEALTHCHECK_PATH:-/health}
    echo -e "${GREEN}✓ Will add health check${NC}"
else
    ADD_HEALTHCHECK=false
fi

echo ""

# 7. Application Details
echo -e "${BLUE}Step 7: Application Details${NC}"
read -p "Application JAR/WAR filename (default: app.jar): " APP_FILE
APP_FILE=${APP_FILE:-app.jar}

read -p "Exposed port (default: 8080): " APP_PORT
APP_PORT=${APP_PORT:-8080}

read -p "JVM memory limit (e.g., 512m, 1g, default: 512m): " JVM_MEMORY
JVM_MEMORY=${JVM_MEMORY:-512m}

echo ""

# Generate Dockerfile
echo -e "${BLUE}Generating your hardened Dockerfile...${NC}"
echo ""

DOCKERFILE="Dockerfile.hardened"

# Start building the Dockerfile
cat > "$DOCKERFILE" << 'DOCKERFILE_START'
# Generated by Java Docker Container Hardener
# This Dockerfile follows security best practices for Java containers

DOCKERFILE_START

# Determine base image
case $BASE_STRATEGY in
    "distroless")
        if [ "$RUNTIME_TYPE" = "jre" ]; then
            echo "FROM gcr.io/distroless/java${JAVA_VERSION}-debian12:nonroot" >> "$DOCKERFILE"
        else
            echo "# Note: Distroless doesn't provide full JDK images, using Debian Slim" >> "$DOCKERFILE"
            echo "FROM eclipse-temurin:${JAVA_VERSION}-jdk-jammy" >> "$DOCKERFILE"
        fi
        ;;
    "alpine")
        if [ "$JDK_DIST" = "temurin" ]; then
            echo "FROM eclipse-temurin:${JAVA_VERSION}-${RUNTIME_TYPE}-alpine" >> "$DOCKERFILE"
        elif [ "$JDK_DIST" = "corretto" ]; then
            echo "FROM amazoncorretto:${JAVA_VERSION}-alpine" >> "$DOCKERFILE"
        else
            echo "FROM eclipse-temurin:${JAVA_VERSION}-${RUNTIME_TYPE}-alpine" >> "$DOCKERFILE"
        fi
        ;;
    "debian")
        if [ "$JDK_DIST" = "temurin" ]; then
            echo "FROM eclipse-temurin:${JAVA_VERSION}-${RUNTIME_TYPE}-jammy" >> "$DOCKERFILE"
        elif [ "$JDK_DIST" = "corretto" ]; then
            echo "FROM amazoncorretto:${JAVA_VERSION}-al2023" >> "$DOCKERFILE"
        else
            echo "FROM eclipse-temurin:${JAVA_VERSION}-${RUNTIME_TYPE}-jammy" >> "$DOCKERFILE"
        fi
        ;;
    "ubuntu")
        echo "FROM eclipse-temurin:${JAVA_VERSION}-${RUNTIME_TYPE}-jammy" >> "$DOCKERFILE"
        ;;
esac

echo "" >> "$DOCKERFILE"

# Add labels if requested
if [ "$ADD_LABELS" = true ]; then
    cat >> "$DOCKERFILE" << 'LABELS'
# Security and metadata labels
LABEL org.opencontainers.image.title="Hardened Java Application"
LABEL org.opencontainers.image.description="Security-hardened Java container"
LABEL security.hardening="enabled"
LABEL security.scan="required"

LABELS
fi

# Add user creation if non-root and not distroless
if [ "$NONROOT" = true ] && [ "$BASE_STRATEGY" != "distroless" ]; then
    cat >> "$DOCKERFILE" << 'NONROOT'
# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser -u 1001 appuser

NONROOT
fi

# Minimize if requested
if [ "$MINIMIZE" = true ] && [ "$BASE_STRATEGY" != "distroless" ]; then
    cat >> "$DOCKERFILE" << 'MINIMIZE'
# Minimize attack surface
RUN if command -v apt-get &> /dev/null; then \
        apt-get update && \
        apt-get install -y --no-install-recommends ca-certificates && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*; \
    elif command -v apk &> /dev/null; then \
        apk add --no-cache ca-certificates; \
    fi

MINIMIZE
fi

# Set working directory
echo "" >> "$DOCKERFILE"
echo "# Set working directory" >> "$DOCKERFILE"
echo "WORKDIR /app" >> "$DOCKERFILE"
echo "" >> "$DOCKERFILE"

# Copy application
echo "# Copy application" >> "$DOCKERFILE"
echo "COPY ${APP_FILE} /app/${APP_FILE}" >> "$DOCKERFILE"
echo "" >> "$DOCKERFILE"

# Change ownership if non-root
if [ "$NONROOT" = true ]; then
    if [ "$BASE_STRATEGY" != "distroless" ]; then
        echo "RUN chown -R appuser:appuser /app" >> "$DOCKERFILE"
        echo "" >> "$DOCKERFILE"
    fi
fi

# Switch to non-root user
if [ "$NONROOT" = true ] && [ "$BASE_STRATEGY" != "distroless" ]; then
    echo "# Run as non-root user" >> "$DOCKERFILE"
    echo "USER appuser" >> "$DOCKERFILE"
    echo "" >> "$DOCKERFILE"
fi

# Expose port
echo "# Expose application port" >> "$DOCKERFILE"
echo "EXPOSE ${APP_PORT}" >> "$DOCKERFILE"
echo "" >> "$DOCKERFILE"

# Add health check if requested
if [ "$ADD_HEALTHCHECK" = true ]; then
    cat >> "$DOCKERFILE" << HEALTHCHECK
# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \\
    CMD curl -f http://localhost:${APP_PORT}${HEALTHCHECK_PATH} || exit 1

HEALTHCHECK
fi

# Set JVM options and application port
echo "# JVM Configuration" >> "$DOCKERFILE"
echo "ENV JAVA_OPTS=\"-Xmx${JVM_MEMORY} -XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0\"" >> "$DOCKERFILE"
echo "ENV PORT=\"${APP_PORT}\"" >> "$DOCKERFILE"
echo "" >> "$DOCKERFILE"

# Entrypoint
echo "# Run application" >> "$DOCKERFILE"
if [ "$BASE_STRATEGY" = "distroless" ]; then
    echo "ENTRYPOINT [\"java\"]" >> "$DOCKERFILE"
    echo "CMD [\"-jar\", \"/app/${APP_FILE}\"]" >> "$DOCKERFILE"
else
    echo "ENTRYPOINT [\"sh\", \"-c\", \"java \$JAVA_OPTS -jar /app/${APP_FILE}\"]" >> "$DOCKERFILE"
fi

# Generate docker-compose.yml for easy testing
COMPOSE_FILE="docker-compose.yml"
cat > "$COMPOSE_FILE" << COMPOSE
version: '3.8'

services:
  java-app:
    build:
      context: .
      dockerfile: ${DOCKERFILE}
    ports:
      - "${APP_PORT}:${APP_PORT}"
    environment:
      - PORT=${APP_PORT}
      - JAVA_OPTS=-Xmx${JVM_MEMORY} -XX:+UseContainerSupport
    restart: unless-stopped
    # Security options
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE

COMPOSE

# Generate .dockerignore
DOCKERIGNORE=".dockerignore.hardened"
cat > "$DOCKERIGNORE" << 'DOCKERIGNORE'
# Ignore unnecessary files
.git
.gitignore
*.md
target/
build/
.gradle/
.idea/
*.iml
.DS_Store
*.log

DOCKERIGNORE

# Generate README
README="DOCKER_README.md"
cat > "$README" << README_CONTENT
# Hardened Java Docker Container

## Configuration Summary

- **Java Version**: ${JAVA_VERSION}
- **Runtime**: ${RUNTIME_TYPE^^}
- **Base Strategy**: ${BASE_STRATEGY}
- **JDK Distribution**: ${JDK_DIST}
- **Non-root User**: ${NONROOT}
- **Security Labels**: ${ADD_LABELS}
- **Minimized**: ${MINIMIZE}

## Building the Container

\`\`\`bash
# Recommended: Build and run with docker compose
docker compose up --build

# Or build separately
docker compose build

# Or build manually with docker
docker build -f ${DOCKERFILE} -t my-java-app:hardened .
\`\`\`

## Running the Container

\`\`\`bash
# Recommended: Use docker compose
docker compose up

# Or with docker-compose (older syntax)
docker-compose up

# Or run directly with docker
docker run -p ${APP_PORT}:${APP_PORT} my-java-app:hardened
\`\`\`

## Security Scanning

Before deploying, scan for vulnerabilities:

\`\`\`bash
# Using Trivy
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \\
    aquasec/trivy image my-java-app:hardened

# Using Grype
grype my-java-app:hardened

# Using Docker Scout
docker scout cves my-java-app:hardened
\`\`\`

## Security Best Practices Applied

1. **Minimal Base Image**: Using ${BASE_STRATEGY} for reduced attack surface
2. **Non-root User**: $([ "$NONROOT" = true ] && echo "✓ Enabled" || echo "✗ Disabled")
3. **No Unnecessary Packages**: $([ "$MINIMIZE" = true ] && echo "✓ Enabled" || echo "✗ Disabled")
4. **Security Labels**: $([ "$ADD_LABELS" = true ] && echo "✓ Enabled" || echo "✗ Disabled")
5. **Health Checks**: $([ "$ADD_HEALTHCHECK" = true ] && echo "✓ Enabled" || echo "✗ Disabled")

## Next Steps

1. Place your ${APP_FILE} in the same directory as the Dockerfile
2. Build the image using the command above
3. Run security scans before deployment
4. Test the application thoroughly
5. Deploy to your container orchestration platform

## Environment Variables

The following environment variables can be customized:
- **PORT**: Application port (default: ${APP_PORT})
- **JAVA_OPTS**: JVM memory and performance settings

\`\`\`bash
# Customize both port and JVM settings
docker run -e PORT=${APP_PORT} -e JAVA_OPTS="-Xmx1g -XX:+UseG1GC" -p ${APP_PORT}:${APP_PORT} my-java-app:hardened
\`\`\`

## Monitoring

- Application exposed on port: ${APP_PORT}
$([ "$ADD_HEALTHCHECK" = true ] && echo "- Health check endpoint: ${HEALTHCHECK_PATH}" || echo "")

README_CONTENT

# Generate security scanning script
SCAN_SCRIPT="scan-image.sh"
cat > "$SCAN_SCRIPT" << 'SCAN_SCRIPT'
#!/bin/bash

# Security scanning script for Docker images

IMAGE_NAME=${1:-"my-java-app:hardened"}

echo "🔍 Scanning image: $IMAGE_NAME"
echo ""

# Check if Trivy is available
if command -v trivy &> /dev/null; then
    echo "Running Trivy scan..."
    trivy image --severity HIGH,CRITICAL "$IMAGE_NAME"
    echo ""
else
    echo "⚠️  Trivy not found. Install with:"
    echo "   brew install aquasecurity/trivy/trivy  (macOS)"
    echo "   Or: docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image $IMAGE_NAME"
    echo ""
fi

# Check if Grype is available
if command -v grype &> /dev/null; then
    echo "Running Grype scan..."
    grype "$IMAGE_NAME"
    echo ""
else
    echo "⚠️  Grype not found. Install with:"
    echo "   curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin"
    echo ""
fi

# Check Docker Scout
if docker scout version &> /dev/null 2>&1; then
    echo "Running Docker Scout scan..."
    docker scout cves "$IMAGE_NAME"
else
    echo "⚠️  Docker Scout not available. Enable in Docker Desktop settings."
fi

SCAN_SCRIPT
chmod +x "$SCAN_SCRIPT"

# Print summary
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Successfully generated your hardened Docker configuration!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Generated Files:${NC}"
echo "  📄 ${DOCKERFILE} - Your hardened Dockerfile"
echo "  📄 ${COMPOSE_FILE} - Docker Compose configuration"
echo "  📄 ${DOCKERIGNORE} - Docker ignore file"
echo "  📄 ${README} - Documentation and instructions"
echo "  📄 ${SCAN_SCRIPT} - Security scanning script"
echo ""
echo -e "${YELLOW}Configuration Summary:${NC}"
echo "  Java Version: ${JAVA_VERSION}"
echo "  Runtime: ${RUNTIME_TYPE^^}"
echo "  Base Image: ${BASE_STRATEGY}"
echo "  JDK: ${JDK_DIST}"
echo "  Port: ${APP_PORT}"
echo "  Memory: ${JVM_MEMORY}"
echo "  Non-root: ${NONROOT}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Place your ${APP_FILE} in this directory"
echo "  2. Build & Run: docker compose up --build"
echo "     Or manually: docker build -f ${DOCKERFILE} -t my-java-app:hardened ."
echo "  3. Scan: ./${SCAN_SCRIPT} my-java-app:hardened"
echo "  4. Run: docker compose up (or docker-compose up)"
echo ""
echo -e "${GREEN}Happy containerizing! 🐳${NC}"
