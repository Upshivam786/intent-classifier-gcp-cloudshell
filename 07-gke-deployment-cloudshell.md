# GKE Deployment using Google Cloud Shell

This document explains how to deploy the Intent Classifier application on  
Google Kubernetes Engine (GKE) using Google Cloud Shell.

---

## 1. Login and Set GCP Project

```bash
gcloud auth login
gcloud config set project bluet-terra

2. Set Default Region and Zone
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a

3. Enable Required APIs
gcloud services enable container.googleapis.com

4. Create GKE Cluster
gcloud container clusters create my-cluster \
  --num-nodes=2 \
  --machine-type=e2-standard-4 \
  --zone us-central1-a \
  --cluster-version=1.32 \
  --enable-ip-alias \
  --enable-autoupgrade \
  --enable-autorepair

5. Get Cluster Credentials (Cloud Shell)
gcloud container clusters get-credentials my-cluster \
  --zone us-central1-a \
  --project bluet-terra

6. Verify Cluster Access
kubectl get nodes
kubectl get pods -n kube-system

7. Clone Repository and Switch Branch
git clone https://github.com/iam-veeramalla/Intent-classifier-model.git
cd Intent-classifier-model
git switch kubernetes

8. Deploy Application to GKE
Create Namespace
kubectl apply -f 04-k8s-manifests/namespace.yml

Deploy Application
kubectl apply -f 04-k8s-manifests/deployment.yaml -n intent-namespace
kubectl apply -f 04-k8s-manifests/service.yaml -n intent-namespace


Verify:

kubectl get all -n intent-namespace

9. Test Application via NodePort
kubectl get nodes -o wide
kubectl get svc -n intent-namespace

curl -X POST http://<NODE_EXTERNAL_IP>:<NODE_PORT>/predict \
  -H "Content-Type: application/json" \
  -d '{"text":"Hi, Whats up?"}'


Expected response:

{"intent":"greeting"}

10. Install Traefik Ingress Controller
helm repo add traefik https://helm.traefik.io/traefik
helm repo update

helm install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace \
  --set rbac.enabled=true


Verify:

kubectl get pods -n traefik
kubectl get svc -n traefik
kubectl get clusterrole | grep traefik
kubectl get clusterrolebinding | grep traefik

11. Create Ingress Resource
kubectl apply -f 06-ingress.yaml


Verify:

kubectl get ingress -n intent-namespace

12. Test via Domain (Ingress)
curl -X POST \
  --resolve example.com:80:<TRAEFIK_EXTERNAL_IP> \
  http://example.com/predict \
  -H "Content-Type: application/json" \
  -d '{"text":"I want to cancel my subscription"}'


Expected response:

{"intent":"complaint"}


14. Cleanup
kubectl delete namespace intent-namespace
helm uninstall traefik -n traefik
kubectl delete namespace traefik
gcloud container clusters delete my-cluster --zone us-central1-a
