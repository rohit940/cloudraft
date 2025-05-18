# 🚀 Cloudraft SRE Assignment – Solution

## 💾 Objective

Deploy a containerized app that exposes a `/counter` endpoint using Helm, ArgoCD, and KIND. The app should persist and increment a counter on each request. Investigate and resolve any issues affecting this behavior.

## 💠 Tools Used

- **KIND** – to create a local Kubernetes cluster  
- **ArgoCD** – to manage GitOps-based deployments  
- **Helm** – to package and deploy the containerized app  
- **NGINX Ingress** – to expose the app externally  
- **GitHub** – to host the Helm chart and configurations  

## 📦 Docker App Details

- Image: `ghcr.io/cloudraftio/metrics-app:1.4`  
- Port: `8080`  
- Endpoint: `/counter`  
- Secret Env Variable: `PASSWORD=MYPASSWORD` (set using Kubernetes secret)  

## 🔧 App Bug & Patch

### ❌ Issue:

The app crashes when accessed because the route `/counter` is implemented as `async def`, but it incorrectly uses a synchronous function `metrics()` with `await`, causing Python to raise a runtime error.

### ✅ Fix:

We patched the `app.py` file during container startup using `sed` commands:

```bash
command:
  - /bin/sh
  - -c
  - |
    set -e
    echo "Patching app.py..."
    sed -i \
      -e '/@app.route.*/\/counter/{n;s/async def/def/}' \
      -e 's/await\s\+metrics/metrics/' \
      /app/app.py
    echo "Starting app..."
    exec python /app/app.py
```

This patch ensures the application starts correctly without modifying the base image.

## 🧑‍💻 Full Step-by-Step Setup

1️⃣ **Create KIND Cluster**

```bash
kind create cluster --name cloudraft-cluster
```

Creates a local Kubernetes cluster named `cloudraft-cluster`.

2️⃣ **Install NGINX Ingress Controller**

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/kind/deploy.yaml
kubectl label node cloudraft-cluster-control-plane ingress-ready=true
```

Deploys ingress controller for KIND and labels node to enable ingress.

3️⃣ **Install ArgoCD**

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

ArgoCD is a declarative GitOps tool for Kubernetes.

4️⃣ **Port Forward ArgoCD Dashboard**

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Access ArgoCD UI at: https://localhost:8080

5️⃣ **Retrieve ArgoCD Initial Admin Password**

```bash
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d && echo
```

Use the above password with username `admin` to log in via UI or CLI.

6️⃣ **ArgoCD CLI Login**

```bash
argocd login localhost:8080 --username admin --password <retrieved-password> --insecure
```

7️⃣ **Add GitHub Repo to ArgoCD**

```bash
argocd repo add https://github.com/rohit940/cloudraft.git \
  --username rohit940 \
  --password <your-github-password-or-token>
```

Adds your GitHub repo to ArgoCD so it can pull Helm chart and manifests.

8️⃣ **Create ArgoCD Application Manifest**

Apply the manifest:

```bash
kubectl apply -f argocd/metrics-app.yaml -n argocd
```

9️⃣ **Setup Ingress Access**

Port-forward NGINX controller to test externally:

```bash
kubectl port-forward svc/ingress-nginx-controller -n ingress-nginx 8080:80
```

Test endpoint:

```bash
curl localhost:8080/counter
```

## 🔄 Behavior Testing

Created a script `result.sh` to test `/counter` repeatedly and put the results in `result.log`
This ensures the counter is incrementing correctly.

## ✅ Observations

After patching:

```
Counter value: 1
Counter value: 2
...
Counter value: 20
```

Before patch: App crashed on every call to `/counter`.

## 🧙‍♂️ Root Cause Summary

- Python app was using `async def` with a regular function (without async context).
- The app crashed due to improper async usage.
- We used `sed` to patch the container at runtime.

## 📁 Git Repo Structure

```
cloudraft/
├── charts/
│   └── metrics-app/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── deployment.yaml
│           ├── ingress.yaml
            ├── secret.yaml
│           └── service.yaml
├── argocd/
│   └── metrics-app.yaml
├── result.sh
├── result.log
└── Solution.md
```

## 📨 Submission

Submitted GitHub repo includes:

- Helm chart  
- ArgoCD Application manifest  
- NGINX ingress resource  
- Kind + ArgoCD bootstrap commands  
- Bug fix and explanation  
- Result logs and behavior testing  
- This solution.md file  

## 🌟 Bonus Points Highlights

- GitOps via ArgoCD  
- Secure secret handling  
- Runtime patching of containers  
- Troubleshooting and root cause analysis  
- CLI & UI integration for ArgoCD  
