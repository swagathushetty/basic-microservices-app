#!/bin/bash

# rebuild-and-deploy.sh
# Rebuilds all Docker images and restarts Kubernetes deployments
# Usage: ./rebuild-and-deploy.sh [service-name]
#   - No args: Rebuilds and restarts ALL services
#   - With service name: Rebuilds and restarts only that service

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Service definitions: directory, image name, deployment name
declare -A SERVICES=(
  ["posts"]="posts:posts-service:posts-depl"
  ["comments"]="comments:comments-service:comments-depl"
  ["query"]="query:query-service:query-depl"
  ["moderation"]="moderation:moderation-service:moderation-depl"
  ["event-bus"]="event-bus:event-bus-service:event-bus-depl"
)

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

# Function to rebuild a single service
rebuild_service() {
  local service_name=$1
  local service_info=${SERVICES[$service_name]}

  if [ -z "$service_info" ]; then
    print_error "Unknown service: $service_name"
    print_warning "Available services: ${!SERVICES[@]}"
    exit 1
  fi

  IFS=':' read -r dir image_name depl_name <<< "$service_info"

  print_step "Building $service_name..."

  if [ ! -d "./$dir" ]; then
    print_error "Directory ./$dir not found!"
    exit 1
  fi

  docker build -t $image_name:latest ./$dir

  if [ $? -eq 0 ]; then
    print_success "Built $image_name:latest"
  else
    print_error "Failed to build $image_name"
    exit 1
  fi
}

# Function to restart a single deployment
restart_deployment() {
  local service_name=$1
  local service_info=${SERVICES[$service_name]}

  IFS=':' read -r dir image_name depl_name <<< "$service_info"

  print_step "Restarting deployment $depl_name..."

  # Check if deployment exists first
  if ! kubectl get deployment $depl_name &> /dev/null; then
    print_warning "Deployment $depl_name doesn't exist yet!"
    print_step "Deploy it first with: kubectl apply -f k8s/"
    return 1
  fi

  kubectl rollout restart deployment $depl_name

  if [ $? -eq 0 ]; then
    print_success "Restarted $depl_name"
  else
    print_error "Failed to restart $depl_name"
    return 1
  fi
}

# Main script logic
echo ""
echo "=========================================="
echo "  Rebuild and Deploy Microservices"
echo "=========================================="
echo ""

# Check if specific service was requested
if [ $# -eq 1 ]; then
  SERVICE=$1
  print_warning "Building and restarting only: $SERVICE"
  echo ""

  rebuild_service $SERVICE
  restart_deployment $SERVICE

  echo ""
  print_success "Done! $SERVICE has been rebuilt and restarted."
  echo ""

  # Show pod status
  print_step "Pod status:"
  kubectl get pods | grep $SERVICE

else
  # Rebuild all services
  print_step "Rebuilding ALL Docker images..."
  echo ""

  for service in "${!SERVICES[@]}"; do
    rebuild_service $service
  done

  echo ""
  print_success "All images built successfully!"
  echo ""

  # Restart all deployments
  print_step "Restarting ALL Kubernetes deployments..."
  echo ""

  failed_restarts=()
  successful_restarts=()

  for service in "${!SERVICES[@]}"; do
    if restart_deployment $service; then
      successful_restarts+=($service)
    else
      failed_restarts+=($service)
    fi
  done

  echo ""

  # Summary
  if [ ${#failed_restarts[@]} -eq 0 ]; then
    print_success "All deployments restarted!"
  else
    print_warning "Some deployments were not restarted:"
    for service in "${failed_restarts[@]}"; do
      echo "  - $service"
    done
    echo ""
    print_step "To deploy missing services:"
    echo "  kubectl apply -f k8s/"
  fi

  echo ""

  # Show all pod status
  if [ ${#successful_restarts[@]} -gt 0 ]; then
    print_step "Waiting for pods to be ready..."
    sleep 3

    echo ""
    kubectl get pods
    echo ""

    print_step "You can watch pods restart with:"
    echo "  kubectl get pods -w"
  fi
fi

echo ""
echo "=========================================="
print_success "Done!"
echo "=========================================="
echo ""
