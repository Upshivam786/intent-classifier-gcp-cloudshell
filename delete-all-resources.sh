#!/bin/bash

# ==========================================
# Cleanup script for intent-classifier-gcp-cloudshell
# Safely deletes ONLY resources created by this project
# Idempotent: can be run multiple times safely
# ==========================================

set -e

PROJECT_ID=$(gcloud config get-value project)
REGION=us-central1

MIG=intent-mig
TEMPLATE=intent-template
SUBNET=intent-public-subnet
VPC=intent-vpc

echo "🔍 Using project: $PROJECT_ID"
echo "🌍 Region: $REGION"
echo "------------------------------------------"

# Delete Managed Instance Group (and VMs)
echo "🧹 Deleting Managed Instance Group..."
gcloud compute instance-groups managed delete $MIG \
  --region $REGION \
  --quiet \
  >/dev/null 2>&1 || echo "✔ Managed Instance Group already deleted"

# Delete Instance Template
echo "🧹 Deleting Instance Template..."
gcloud compute instance-templates delete $TEMPLATE \
  --quiet \
  >/dev/null 2>&1 || echo "✔ Instance template already deleted"

# Delete Firewall Rules
echo "🧹 Deleting Firewall Rules..."
gcloud compute firewall-rules delete allow-http allow-ssh \
  --quiet \
  >/dev/null 2>&1 || echo "✔ Firewall rules already deleted"

# Delete Subnet
echo "🧹 Deleting Subnet..."
gcloud compute networks subnets delete $SUBNET \
  --region $REGION \
  --quiet \
  >/dev/null 2>&1 || echo "✔ Subnet already deleted"

# Delete VPC Network
echo "🧹 Deleting VPC Network..."
gcloud compute networks delete $VPC \
  --quiet \
  >/dev/null 2>&1 || echo "✔ VPC network already deleted"

echo "------------------------------------------"
echo "✅ Cleanup completed successfully"
echo "💰 No billable resources from this project should remain"
