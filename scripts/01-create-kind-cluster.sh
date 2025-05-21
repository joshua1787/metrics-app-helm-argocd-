#!/bin/bash

set -eo pipefail

CLUSTER_NAME="metrics-cluster"
KIND_NODE_IMAGE="kindest/node:v1.27.3" # Specify a Kubernetes version

echo "🔥 Creating KIND cluster: ${CLUSTER_NAME} using image ${KIND_NODE_IMAGE}"

# Check if cluster already exists
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
  echo "Cluster '${CLUSTER_NAME}' already exists."
else
  # The --config - <<EOF part uses a "here document" to pass the configuration to kind
  kind create cluster --name "${CLUSTER_NAME}" --image "${KIND_NODE_IMAGE}" --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true" # Label the node for the NGINX Ingress Controller
  extraPortMappings: # Map ports from the host to the Kind node (control-plane)
  - containerPort: 80  # NGINX Ingress HTTP port on the Kind node
    hostPort: 80       # Expose on host port 80
    protocol: TCP
  - containerPort: 443 # NGINX Ingress HTTPS port on the Kind node
    hostPort: 443      # Expose on host port 443
    protocol: TCP
EOF
  echo "✅ KIND cluster ${CLUSTER_NAME} created."
fi

echo "☸️ Setting kubectl context to 'kind-${CLUSTER_NAME}'"
kubectl config use-context "kind-${CLUSTER_NAME}"

echo "📦 Installing NGINX Ingress Controller..."
# Using kubectl apply directly from the official manifest for a specific version.
# This manifest is specifically for KIND and includes the necessary configurations.
# Check for the latest stable version: https://github.com/kubernetes/ingress-nginx/releases
INGRESS_NGINX_VERSION="v1.10.0" # Use a specific, recent version
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/${INGRESS_NGINX_VERSION}/deploy/static/provider/kind/deploy.yaml

echo "⏳ Waiting for NGINX Ingress Controller to be ready..."
# This can take a few minutes for the pods to download images and start.
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

echo "✅ NGINX Ingress Controller installed and ready."
echo "🎉 KIND cluster '${CLUSTER_NAME}' with Ingress is ready to use!"
echo "👉 Current context is set to 'kind-${CLUSTER_NAME}'."
echo "👉 You can access services exposed via Ingress at http://localhost (e.g. http://localhost/counter)"