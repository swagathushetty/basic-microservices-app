#!/bin/bash

# shutdown.sh
# Shuts down all Kubernetes deployments and services
# Usage:
#   ./shutdown.sh           - Delete all app resources (keeps k8s running)
#   ./shutdown.sh --all     - Delete everything including k8s configs
#   ./shutdown.sh [service] - Delete only specific service

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Service definitions: deployment name, service name
declare -A SERVICES=(
  ["posts"]="posts-depl:posts-srv"
  ["comments"]="comments-depl:comments-srv"
  ["query"]="query-depl:query-srv"
  ["moderation"]="moderation-depl:moderation-srv"
  ["event-bus"]="event-bus-depl:event-bus-srv"
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

# Function to delete a single service
delete_service() {
  local service_name=$1
  local service_info=${SERVICES[$service_name]}

  if [ -z "$service_info" ]; then
    print_error "Unknown service: $service_name"
    print_warning "Available services: ${!SERVICES[@]}"
    exit 1
  fi

  IFS=':' read -r depl_name svc_name <<< "$service_info"

  print_step "Deleting $service_name..."

  # Delete deployment
  if kubectl get deployment $depl_name &> /dev/null; then
    kubectl delete deployment $depl_name
    print_success "Deleted deployment: $depl_name"
  else
    print_warning "Deployment $depl_name not found (already deleted?)"
  fi

  # Delete service
  if kubectl get service $svc_name &> /dev/null; then
    kubectl delete service $svc_name
    print_success "Deleted service: $svc_name"
  else
    print_warning "Service $svc_name not found (already deleted?)"
  fi
}

# Function to delete ingress
delete_ingress() {
  print_step "Deleting ingress..."

  if kubectl get ingress ingress-srv &> /dev/null; then
    kubectl delete ingress ingress-srv
    print_success "Deleted ingress: ingress-srv"
  else
    print_warning "Ingress not found (already deleted?)"
  fi
}

# Function to delete all from k8s directory
delete_all_configs() {
  print_step "Deleting all resources from k8s/ directory..."

  if [ -d "./k8s" ]; then
    kubectl delete -f ./k8s/ 2>/dev/null || true
    print_success "Deleted all resources from k8s/"
  else
    print_error "k8s/ directory not found!"
    exit 1
  fi
}

# Main script logic
echo ""
echo "=========================================="
echo "  Shutdown Microservices"
echo "=========================================="
echo ""

# Check for flags
if [ "$1" == "--all" ]; then
  print_warning "Deleting ALL resources from k8s/ directory..."
  echo ""

  delete_all_configs

  echo ""
  print_success "All resources deleted!"
  echo ""

  print_step "Remaining resources:"
  kubectl get deployments,services,ingress

elif [ $# -eq 1 ]; then
  # Delete specific service
  SERVICE=$1
  print_warning "Deleting only: $SERVICE"
  echo ""

  delete_service $SERVICE

  echo ""
  print_success "Done! $SERVICE has been deleted."
  echo ""

  print_step "Remaining pods:"
  kubectl get pods

else
  # Delete all services but not ingress
  print_step "Deleting ALL services and deployments..."
  echo ""

  for service in "${!SERVICES[@]}"; do
    delete_service $service
  done

  echo ""
  delete_ingress

  echo ""
  print_success "All services deleted!"
  echo ""

  print_step "Remaining resources:"
  kubectl get all

  echo ""
  print_step "To delete k8s config files from cluster:"
  echo "  ./shutdown.sh --all"
fi

echo ""
echo "=========================================="
print_success "Shutdown complete!"
echo "=========================================="
echo ""

# Show docker images (still exist locally)
print_step "Docker images (still cached locally):"
docker images | grep -E "service|REPOSITORY"
echo ""
print_warning "Note: Docker images are still cached locally"
print_step "To remove images: docker rmi <image-name>"
echo ""
