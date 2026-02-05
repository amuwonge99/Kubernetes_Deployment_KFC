Kubernetes For Cloud Project

The goal of this project was to show how a cloud-native application can be fully deployed using Terraform, Kubernetes manifests, and automation scripts that support continuous deployment.

Core Requirements
1. Can be AWS or Azure
2. Can be managed service or built from scratch
3. must be highly available and scalable (but manage costs)
4. must be capable of routing from the internet (but secured)
5. must be deployed from code
6. code must be stored in version control
7. Deployment of the cluster must be automated

Additional Requirements
1. Create a service that can  deploy applications/services onto a Kubernetes cluster
2. Deploy an application that uses a service and ingress
3. application must be capable of being routed from the internet
4. application must be monitored
5. you must be able to perform zero downtime deployment of the application

Design Choices
- I chose a managed service as it is more efficient than building from scratch, and I wanted to relieve myself the responsibility of cluster maintenance.
- I chose AWS over Azure because I had less experience with AWS, and wanted to challenge myself.

Architecture Overview
- Terraform - Infrastructure provisioning for cluster and networking
- Kubernetes manifest files (app-deployment.yaml, app-service.yaml) - Defines the app deployment and service 
- Shell scripts (deploy.sh, kube.sh) - To apply manifests and delply AWS resources
- A sample Node.js app (server.js) - App to be deployed to Kubernetes
- Dockerfile - The container image used in the cluster
