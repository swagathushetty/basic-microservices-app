echo " Building all service images..."

# Build each service
services=("posts" "comments" "query" "moderation" "event-bus")

for service in "${services[@]}"; do
  echo "Building $service-service..."
  cd $service
  docker build -t $service-service .
  cd ..
  echo "$service-service built"
done

echo "All images built successfully!"

# List images
docker images | grep -E "posts-service|comments-service|query-service|moderation-service|event-bus-service"