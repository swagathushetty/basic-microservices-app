#!/bin/bash

# deploy-all.sh
# First-time deployment script
# Builds all images AND deploys all Kubernetes configs
# Usage: ./deploy-all.sh

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
  echo -e "${BLUE}==>${NC} $1"
}

print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}!${NC} $1"
}

echo ""
echo "=========================================="
echo "  Deploy All Microservices to Kubernetes"
echo "=========================================="
echo ""

# Step 1: Check if k8s directory exists
print_step "Checking k8s directory..."
if [ ! -d "./k8s" ]; then
  print_error "k8s/ directory not found!"
  print_warning "Make sure you're in the basic-app directory"
  exit 1
fi
print_success "Found k8s/ directory"
echo ""

# Step 2: Build all Docker images
print_step "Building all Docker images..."
echo ""

services=("posts" "comments" "query" "moderation" "event-bus")

for service in "${services[@]}"; do
  print_step "Building $service-service..."

  if [ ! -d "./$service" ]; then
    print_error "Directory ./$service not found!"
    exit 1
  fi

  docker build -t $service-service:latest ./$service

  if [ $? -eq 0 ]; then
    print_success "Built $service-service:latest"
  else
    print_error "Failed to build $service-service"
    exit 1
  fi
done

echo ""
print_success "All Docker images built!"
echo ""

# Step 3: Deploy to Kubernetes
print_step "Deploying all resources to Kubernetes..."
echo ""

kubectl apply -f k8s/

if [ $? -eq 0 ]; then
  print_success "All resources deployed!"
else
  print_error "Failed to deploy resources"
  exit 1
fi

echo ""
print_step "Waiting for deployments to be ready..."
sleep 5

echo ""

# Step 4: Show status
print_step "Deployment status:"
kubectl get deployments
echo ""

print_step "Service status:"
kubectl get services
echo ""

print_step "Pod status:"
kubectl get pods
echo ""

print_step "Ingress status:"
kubectl get ingress
echo ""

# Step 5: Final instructions
echo "=========================================="
print_success "Deployment complete!"
echo "=========================================="
echo ""

print_step "Your services are now running in Kubernetes!"
echo ""

print_step "Next steps:"
echo "  1. Wait for all pods to show 'Running' status"
echo "     kubectl get pods -w"
echo ""
echo "  2. Test the services:"
echo "     curl -X POST http://posts.com/posts/create \\"
echo "       -H \"Content-Type: application/json\" \\"
echo "       -d '{\"title\":\"Test Post\"}'"
echo ""
echo "  3. After code changes, rebuild with:"
echo "     ./rebuild-and-deploy.sh"
echo ""
echo "  4. To shut down everything:"
echo "     ./shutdown.sh"
echo ""

# Check if hosts file is configured
print_step "Checking hosts file configuration..."
if grep -q "posts.com" /etc/hosts 2>/dev/null; then
  print_success "Hosts file is configured (posts.com found)"
else
  print_warning "Don't forget to add to /etc/hosts:"
  echo "  sudo nano /etc/hosts"
  echo "  Add line: 127.0.0.1 posts.com"
fi

echo ""
