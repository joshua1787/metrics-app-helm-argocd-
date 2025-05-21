#!/bin/bash

set -eo pipefail

ARGOCD_NAMESPACE="argocd"
ARGOCD_VERSION="v2.11.2" # Specify an ArgoCD version

install_argocd() {
    echo "📦 Installing ArgoCD version ${ARGOCD_VERSION}..."

    echo "   Creating namespace ${ARGOCD_NAMESPACE} if it doesn't exist..."
    kubectl get ns "${ARGOCD_NAMESPACE}" > /dev/null 2>&1 || kubectl create namespace "${ARGOCD_NAMESPACE}"

    echo "   Applying ArgoCD manifests..."
    kubectl apply -n "${ARGOCD_NAMESPACE}" -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"

    echo "⏳ Waiting for ArgoCD pods to be ready in namespace ${ARGOCD_NAMESPACE}..."
    # Wait for key deployments to be available
    kubectl wait --for=condition=available deployment/argocd-repo-server -n "${ARGOCD_NAMESPACE}" --timeout=300s
    kubectl wait --for=condition=available deployment/argocd-server -n "${ARGOCD_NAMESPACE}" --timeout=300s
    kubectl wait --for=condition=available deployment/argocd-applicationset-controller -n "${ARGOCD_NAMESPACE}" --timeout=300s # For full functionality

    echo "✅ ArgoCD installed successfully."

    echo ""
    echo "🔒 To get the initial ArgoCD admin password:"
    echo "   kubectl -n ${ARGOCD_NAMESPACE} get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d; echo"
    echo ""
    echo "💻 To access ArgoCD UI (port-forward in a new terminal):"
    echo "   kubectl port-forward svc/argocd-server -n ${ARGOCD_NAMESPACE} 8080:443"
    echo "   Then open https://localhost:8080 in your browser."
}

uninstall_argocd() {
    echo "🗑️ Uninstalling ArgoCD from namespace ${ARGOCD_NAMESPACE}..."
    kubectl delete -n "${ARGOCD_NAMESPACE}" -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml" --ignore-not-found=true
    echo "   Deleting namespace ${ARGOCD_NAMESPACE}..."
    kubectl delete namespace "${ARGOCD_NAMESPACE}" --ignore-not-found=true
    echo "✅ ArgoCD uninstalled."
}

# Check for command line argument
if [ "$1" == "uninstall" ]; then
    uninstall_argocd
else
    install_argocd
fi