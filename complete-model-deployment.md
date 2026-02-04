# Deploy Intent Classifier on GCP (Compute Engine + MIG) using Cloud Shell

This guide shows how to deploy a **production-ready Intent Classifier ML API**
on **Google Cloud Platform (GCP)** using **Cloud Shell only**.

No Terraform.  
No Kubernetes.  
Pure `gcloud` CLI + Compute Engine.

---

## Architecture Overview

- GCP VPC Network
- Public Subnet
- Compute Engine Instance Template
- Managed Instance Group (Regional, Autoscaling)
- Gunicorn (app server)
- Nginx (reverse proxy)
- Flask-based ML API

---

## 0. Set Variables (Cloud Shell)

```bash
PROJECT_ID=$(gcloud config get-value project)
REGION=us-central1
ZONE1=us-central1-a
ZONE2=us-central1-b

NETWORK=intent-vpc
SUBNET=intent-public-subnet
TEMPLATE=intent-template
MIG=intent-mig


1. Create VPC Subnet (Public)

In GCP, a subnet is considered public when instances have external IPs.

gcloud compute networks subnets create intent-public-subnet \
  --network intent-vpc \
  --region us-central1 \
  --range 10.10.0.0/16

2. Create Firewall Rules
Allow HTTP (Port 80)
gcloud compute firewall-rules create allow-http \
  --network intent-vpc \
  --allow tcp:80 \
  --source-ranges 0.0.0.0/0

Allow SSH (Port 22)
gcloud compute firewall-rules create allow-ssh \
  --network intent-vpc \
  --allow tcp:22 \
  --source-ranges 0.0.0.0/0

3. Clone Application Repository
git clone https://github.com/Upshivam786/intent-classifier-gcp-cloudshell.git
cd Intent-classifier-model
git checkout virtual-machines


This branch contains:

userdata.sh

Gunicorn setup

Nginx configuration

4. Create Instance Template

This template defines how Compute Engine VMs are launched.

gcloud compute instance-templates create intent-template \
  --machine-type e2-medium \
  --network intent-vpc \
  --subnet projects/$PROJECT_ID/regions/us-central1/subnetworks/intent-public-subnet \
  --tags http-server \
  --image-family ubuntu-2204-lts \
  --image-project ubuntu-os-cloud \
  --metadata-from-file startup-script=userdata.sh \
  --boot-disk-size 10GB

5. Create Managed Instance Group (MIG)

The MIG provides high availability and autoscaling.

gcloud compute instance-groups managed create intent-mig \
  --base-instance-name intent-vm \
  --template intent-template \
  --size 1 \
  --zones us-central1-a,us-central1-b

6. Enable Autoscaling
gcloud compute instance-groups managed set-autoscaling intent-mig \
  --region us-central1 \
  --min-num-replicas 1 \
  --max-num-replicas 2 \
  --target-cpu-utilization 0.8

7. Verify Application on VM

SSH into a running instance:

gcloud compute instances list
gcloud compute ssh <INSTANCE_NAME> --zone us-central1-a


Test the ML API:

curl -X POST http://127.0.0.1:6000/predict \
  -H "Content-Type: application/json" \
  -d '{"text":"I want to cancel my subscription"}'

Example Response
{"intent":"complaint"}
