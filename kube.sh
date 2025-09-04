#!/bin/bash

# Setting variables
AWS_REGION="eu-west-2"
ACCOUNT_ID="108302758118"
REPO_NAME="your-app-name"
IMAGE_TAG="latest"
ECR_URL="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG"
NODE_ROLE_NAME="default-eks-node-group-20250903223335782000000002"  # update if it changes

echo "Building Docker image for linux/amd64..."
docker buildx build --platform linux/amd64 -t $REPO_NAME:$IMAGE_TAG .

echo "Tagging image for the ECR..."
docker tag $REPO_NAME:$IMAGE_TAG $ECR_URL

echo "Logging in to AWS ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

echo "Pushing image to ECR..."
docker push $ECR_URL

echo "Attaching ECR pull policy to EKS node IAM role..."
aws iam attach-role-policy \
  --role-name $NODE_ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly \
  --region $AWS_REGION

echo "Restarting Kubernetes deployment..."
kubectl rollout restart deployment app

echo "Getting LoadBalancer URL..."
LB_URL=$(kubectl get svc app-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "If it doesn't work, slap yourself: http://$LB_URL"
