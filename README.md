# 🚀 **SRE Assignment - Metrics App Deployment**

Welcome to the **Metrics App Deployment** repository! This project demonstrates a fully functional **Kubernetes-based containerized application** deployed using **Helm**, **ArgoCD**, and **KIND**. The app exposes a `/counter` endpoint that increments with each call, and the entire setup follows best practices for deployment, monitoring, and root cause analysis.

## 🌟 **Objective**
Deploy a containerized app that exposes a `/counter` endpoint using **Helm**, **ArgoCD**, and **KIND**. Investigate the behavior of the app, identify issues, and provide detailed root cause analysis.

---

## 🔧 **Technologies Used**
- **Kubernetes** (via KIND for local setup)
- **Helm** (for packaging the application)
- **ArgoCD** (for GitOps-based deployment)
- **NGINX Ingress Controller** (for external access)
- **Docker** (for containerization)

---

## 📋 **Task Breakdown**
### 1. **Helm Chart Creation**
The `metrics-app` Helm chart is designed to deploy the app with the necessary configurations:
- **Docker Image**: `ghcr.io/cloudraftio/metrics-app:1.4`
- **Environment Variable**: `PASSWORD` (set to `MYPASSWORD`)
- **Port**: `8080`
- **Counter Endpoint**: `/counter`

### 2. **Local KIND Cluster Setup**
- **KIND**: Kubernetes in Docker for local cluster setup.
- **ArgoCD**: Used for continuous deployment directly from a Git repository.
- **Ingress**: NGINX ingress to expose the app externally at `/counter`.

### 3. **App Deployment via ArgoCD**
- GitOps principles were followed using ArgoCD to deploy the Helm chart into the Kubernetes cluster.
- Ensured security by passing the `PASSWORD` variable securely through Kubernetes secrets.

### 4. **Ingress Setup**
- Configured an **NGINX Ingress Controller** to expose the app externally at `http://localhost/counter`.
- Validated by accessing the `/counter` endpoint multiple times.

---

## 🚀 **Steps for Deployment**

### 1. **Helm Chart Creation**
1. Create the Helm chart:
    ```bash
    helm create metrics-app
    ```

2. Modify `values.yaml`:
    ```yaml
    image:
      repository: ghcr.io/cloudraftio/metrics-app
      tag: "1.4"
    env:
      PASSWORD: "MYPASSWORD"
    ```

3. Update `deployment.yaml` for secure environment variable passing:
    ```yaml
    env:
      - name: PASSWORD
        valueFrom:
          secretKeyRef:
            name: password-secret
            key: password
    ```

4. Create the Kubernetes Secret:
    ```yaml
    apiVersion: v1
    kind: Secret
    metadata:
      name: password-secret
    type: Opaque
    data:
      password: {{ .Values.env.PASSWORD | b64enc | quote }}
    ```

### 2. **Set Up Local KIND Cluster**
1. Install **KIND**:
    ```bash
    curl -Lo ./kind https://github.com/kubernetes-sigs/kind/releases/download/v0.18.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
    ```

2. Create the cluster:
    ```bash
    kind create cluster --name metrics-cluster
    ```

3. Install **ArgoCD**:
    ```bash
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    ```

4. Forward ArgoCD UI:
    ```bash
    kubectl port-forward svc/argocd-server -n argocd 8080:443
    ```

### 3. **App Deployment via ArgoCD**
1. Push the Helm chart to your Git repository.
2. Create the ArgoCD application manifest (`metrics-app.yaml`):
    ```yaml
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: metrics-app
    spec:
      destination:
        namespace: default
        server: 'https://kubernetes.default.svc'
      source:
        repoURL: '<Your Git Repo URL>'
        path: 'metrics-app'
        targetRevision: HEAD
        helm:
          values: |
            image:
              repository: ghcr.io/cloudraftio/metrics-app
              tag: "1.4"
      project: default
    ```

3. Apply the application:
    ```bash
    kubectl apply -f metrics-app.yaml
    ```

### 4. **Set Up Ingress**
1. Install **NGINX Ingress Controller**:
    ```bash
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
    ```

2. Create the Ingress resource:
    ```yaml
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: metrics-app-ingress
    spec:
      rules:
      - host: localhost
        http:
          paths:
          - path: /counter
            pathType: Prefix
            backend:
              service:
                name: metrics-app
                port:
                  number: 8080
    ```

3. Apply the Ingress:
    ```bash
    kubectl apply -f metrics-app-ingress.yaml
    ```

---

## 🧪 **Testing & Validation**

1. **Test `/counter` endpoint**:
    ```bash
    curl localhost/counter
    ```

    Expected output:
    ```
    Counter value: 1
    ```

2. **Automate multiple calls**:
    ```bash
    for i in $(seq 0 20)
    do 
      time curl localhost:8080/counter
    done
    ```

3. **Expected Behavior**:
   - The counter should increment with each call.
   - Monitor for slow responses or errors.

---

## 🛠️ **Root Cause Analysis**

### **Potential Issues:**
1. **Ingress Issues**:
   - Symptoms: `/counter` endpoint not accessible.
   - Solution: Verify the NGINX ingress controller setup.

2. **Counter Not Incrementing**:
   - Symptoms: Counter value does not increment.
   - Solution: Check app logs for state management issues.

3. **Slow Response**:
   - Symptoms: Inconsistent or slow responses.
   - Solution: Investigate resource bottlenecks in Kubernetes (e.g., CPU, memory).

### **Logs & Debugging**:
To debug the app:
```bash
kubectl logs -f deployment/metrics-app
