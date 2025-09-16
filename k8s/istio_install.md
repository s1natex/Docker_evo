# Initial setup: install Istio control plane
```
kubectl create namespace istio-system
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update
helm install istio-base istio/base -n istio-system
helm install istiod istio/istiod -n istio-system --wait
```
# Label namespace for sidecar injection and restart workloads
```
kubectl label namespace passgen-app istio-injection=enabled --overwrite
kubectl -n passgen-app rollout restart deploy/pass-gen
kubectl -n passgen-app rollout restart deploy/frontend
kubectl -n passgen-app get pods -w
```
# Apply Istio mTLS and gateway manifests
```
kubectl apply -f k8s/istio-mtls.yaml
kubectl apply -f k8s/frontend-gateway.yaml
```
# Verify pods have sidecars
```
kubectl -n passgen-app get pods -o wide
```
# Apply gateway and Find the Istio ingress port
```
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update
helm install istio-ingress istio/gateway -n istio-system --wait

kubectl -n istio-system get svc | grep -i ingress

# verify "Ok" response
kubectl -n passgen-app exec deploy/frontend -c frontend -- \
  node -e "fetch('http://pass-gen:5000/health').then(r=>r.text()).then(t=>console.log(t)).catch(e=>{console.error(e);process.exit(1)})"

kubectl -n passgen-app patch gateway frontend-gateway --type='merge' -p \
'{"spec":{"selector":{"istio":"ingress"}}}'

# verify
kubectl -n passgen-app get gateway frontend-gateway -o jsonpath='{.spec.selector}'; echo

kubectl -n istio-system port-forward svc/istio-ingress 8080:80
# in another terminal:
curl -v http://127.0.0.1:8080/health

# show ports
kubectl -n istio-system get svc istio-ingress

# hit via LB (Docker Desktop maps to localhost)
curl -v http://localhost/

# or via the NodePort backing port 80 (from your output it was 32036)
curl -v http://localhost:32036/

# access frontend
http://localhost/
```
# Call backend from frontend pod(Linux)
```
kubectl -n passgen-app exec -it deploy/frontend -c frontend -- \
  sh -lc "apk add --no-cache curl >/dev/null 2>&1 || true; curl -sS http://pass-gen:5000/health"
```
# Install Kiali dashboard
```
helm repo add kiali https://kiali.org/helm-charts
helm repo update
helm install kiali-server kiali/kiali-server -n istio-system --set auth.strategy=anonymous --wait
```
# Port-forward Kiali
```
kubectl -n istio-system port-forward svc/kiali 20001:20001
```
# Open http://localhost:20001, Graph → Namespace: passgen-app → Display → Security

# Clean up app resources
```
kubectl delete -n passgen-app -f k8s/frontend-service-nodeport.yaml --ignore-not-found
kubectl delete -n passgen-app -f k8s/frontend-deployment.yaml --ignore-not-found
kubectl delete -n passgen-app -f k8s/pass-gen-service.yaml --ignore-not-found
kubectl delete -n passgen-app -f k8s/pass-gen-deployment.yaml --ignore-not-found
kubectl delete -n passgen-app -f k8s/serviceaccount.yaml --ignore-not-found
kubectl delete -n passgen-app -f k8s/istio-mtls.yaml --ignore-not-found
kubectl delete -n passgen-app -f k8s/frontend-gateway.yaml --ignore-not-found
kubectl delete gateway frontend-gateway -n passgen-app --ignore-not-found
kubectl delete virtualservice frontend-vs -n passgen-app --ignore-not-found
kubectl delete namespace passgen-app --ignore-not-found --wait

# Clean up Istio add-ons and control plane
helm uninstall kiali-server -n istio-system || true
helm uninstall istio-ingress -n istio-system || true
helm uninstall istiod -n istio-system || true
helm uninstall istio-base -n istio-system || true
kubectl delete namespace istio-system --ignore-not-found --wait

# Remove injection label if namespace still exists
kubectl label namespace passgen-app istio-injection- --overwrite 2>/dev/null || true

# Kill port-forwards
pkill -f "kubectl.*port-forward" 2>/dev/null || true

# Final checks
kubectl get ns | grep -E 'passgen-app|istio-system' || echo "No app/istio namespaces."
kubectl get all -A | grep -E 'pass-gen|frontend|istio' || echo "No app/istio workloads."
```