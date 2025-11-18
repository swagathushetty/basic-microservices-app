# Port-forward posts (terminal 1):
kubectl port-forward service/posts-srv 4001:4001

# Create post:
curl -X POST http://localhost:4001/posts \
  -H "Content-Type: application/json" \
  -d '{"title":"My Post"}'
# Returns: {"id":"xyz123","title":"My Post"}

# Add comment (use the ID from above):
curl -X POST http://localhost:4001/posts/xyz123/comments \
  -H "Content-Type: application/json" \
  -d '{"content":"Great post!"}'

# Port-forward query (terminal 2):
kubectl port-forward service/query-srv 4003:4003

# Check aggregated data:
curl http://localhost:4003/posts




--------------------------------
# check logs


kubectl logs deployment/event-bus-depl

kubectl logs deployment/query-depl