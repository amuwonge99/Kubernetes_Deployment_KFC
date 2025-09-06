#!/bin/bash

AWS_REGION="${AWS_REGION:-eu-west-2}"
ACCOUNT_ID="108302758118"
CLUSTER_NAME="our-eks-cluster"
REPO_NAME="your-app-name"
IMAGE_TAG="latest"
ECR_URL="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG"

echo "Discovering nodegroup and IAM role..."
NODEGROUP_NAME=$(aws eks list-nodegroups \
  --cluster-name $CLUSTER_NAME \
  --region $AWS_REGION \
  --query "nodegroups[0]" \
  --output text)

if [ -z "$NODEGROUP_NAME" ] || [ "$NODEGROUP_NAME" == "None" ]; then
  echo "No nodegroups found in cluster $CLUSTER_NAME"
  exit 1
fi

NODE_ROLE_NAME=$(aws eks describe-nodegroup \
  --cluster-name $CLUSTER_NAME \
  --nodegroup-name $NODEGROUP_NAME \
  --region $AWS_REGION \
  --query "nodegroup.nodeRole" \
  --output text | awk -F'/' '{print $NF}')

echo "Using nodegroup: $NODEGROUP_NAME"
echo "Using IAM role: $NODE_ROLE_NAME"

echo "Building Docker image, please wait (not like you have an option)"
docker buildx build --platform linux/amd64 -t $REPO_NAME:$IMAGE_TAG .

echo "Tagging image for ECR, you're welcome"
docker tag $REPO_NAME:$IMAGE_TAG $ECR_URL

echo "Logging in to AWS ECR (because you're too lazy to do it yourself)"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

echo "Pushing image to ECR. Don't rush me!!"
docker push $ECR_URL

echo "Attaching ECR pull policy to EKS node IAM role because I'm big brained"
aws iam attach-role-policy \
  --role-name $NODE_ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly \
  --region $AWS_REGION || true

echo "Applying Kubernetes manifests"
kubectl apply -f app-deployment.yaml
kubectl apply -f app-service.yaml

echo "Restarting Kubernetes deployment 🙄"
kubectl rollout restart deployment app || echo "Deployment 'app' not found"

echo "I'm getting the LoadBalancer URL, patince young jedi"
LB_URL=""
for i in {1..30}; do
  LB_URL=$(kubectl get svc app-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
  if [ -n "$LB_URL" ]; then break; fi
  echo "Still waiting... ($i/30)"
  sleep 10
done

if [ -n "$LB_URL" ]; then
  echo "If it doesn't work, slap yourself: http://$LB_URL"
else
  echo "LoadBalancer not ready after 5 minutes"
fi
