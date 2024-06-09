# nOps-workshop-eks-with-karpenter

#### Launching EKS cluster with basic cheapest EC2 Instances using Karpenter with a specific tag set
---
## Prerequisites
1. Create AWS account
2. Create IAM terraform-provisioner user with [necessary permissions policies](https://github.com/AdamDubnytskyy/nOps-workshop/blob/main/iam/terraform-provisioner-permissions-policies.json).
3. Create and note down [AWS access key](https://us-east-1.console.aws.amazon.com/iam/home?region=us-east-1#/users/details/terraform-provisioner/create-access-key) which should be added to [GitHub repository secrets](https://github.com/AdamDubnytskyy/nOps-workshop/settings/secrets/actions/new).Three secrets are required to run GitHub workflows smoothly: _AWS_ACCESS_KEY_ID_, _AWS_SECRET_ACCESS_KEY_, _AWS_DEFAULT_REGION_.


### How To Auto-Scale Kubernetes Clusters With Karpenter
https://youtu.be/C-2v7HT-uSA

---
## Provision infrastructure
### CI
**Provision nOps eks cluster with eksctl** workflow automatically provisions infrastructure including VPC, subnets, NAT, IGW, EKS, node gorups, IAM, etc once workflow is triggered manually.

[eksctl](https://eksctl.io/) is leveraged to provision EKS cluster.

For karpenter troubleshooting, [see](https://karpenter.sh/docs/troubleshooting/).
### Scripts for manual setup
```
cd scripts
```
and run [karpenter-demo.sh](https://github.com/olehdubnytskyy/nOps-workshop-eks-with-karpenter/blob/main/scripts/karpenter-demo.sh) steps


## Decommission infrastructure
**Decommission EKS cluster** workflow provides capability to manually decommission infrastructure.

---
#### Simple IAM Role for providing Read Only Permission to EKS
See [guide](https://github.com/olehdubnytskyy/nOps-workshop-eks-with-karpenter/blob/main/scripts/iam.sh) to create IAM Role with readOnly access to EKS cluster