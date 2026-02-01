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

