######################################################################
# How To Auto-Scale Kubernetes Clusters With Karpenter               #
# https://youtu.be/C-2v7HT-uSA                                       #
#                                                                    #
# Script below was inspired by podcast shared via youtube link above #
######################################################################


# Prerequisites
# 1. Create AWS account and provision an IAM user with admin permissions
# 2. Install [eksctl](https://eksctl.io/installation/)
# 3. Install [kubectl](https://kubernetes.io/docs/tasks/tools/)
# 4. Install [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
# 5. Install [helm](https://helm.sh/docs/intro/install/)

######################################################################
#                             Setup                                  #
######################################################################

export CLUSTER_NAME="nOps-eks-cluster-dev"

# Replace `[...]` with your access key ID
export AWS_ACCESS_KEY_ID=[...]

# Replace `[...]` with your secret access key
export AWS_SECRET_ACCESS_KEY=[...]

export AWS_DEFAULT_REGION=us-east-1


eksctl create cluster \
    --config-file ../manifests/cluster.yaml

export CLUSTER_ENDPOINT=$(aws eks describe-cluster \
    --name $CLUSTER_NAME \
    --query "cluster.endpoint" \
    --output json)

echo $CLUSTER_ENDPOINT

#################################################################################
#                         Karpenter Prerequisites                               #
#################################################################################

export SUBNET_IDS=$(\
    aws cloudformation describe-stacks \
    --stack-name eksctl-$CLUSTER_NAME-cluster \
    --query 'Stacks[].Outputs[?OutputKey==`SubnetsPrivate`].OutputValue' \
    --output text)

aws ec2 create-tags \
    --resources $(echo $SUBNET_IDS | tr ',' '\n') \
    --tags Key="kubernetes.io/cluster/$CLUSTER_NAME",Value=


aws cloudformation deploy \
    --stack-name Karpenter-$CLUSTER_NAME \
    --template-file ../manifests/karpenter.yaml \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides ClusterName=$CLUSTER_NAME

export AWS_ACCOUNT_ID=$(\
    aws sts get-caller-identity \
    --query Account \
    --output text)

eksctl create iamidentitymapping \
    --username system:node:{{EC2PrivateDNSName}} \
    --cluster  $CLUSTER_NAME \
    --arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/KarpenterNodeRole-$CLUSTER_NAME \
    --group system:bootstrappers \
    --group system:nodes

eksctl create iamserviceaccount \
    --cluster $CLUSTER_NAME \
    --name karpenter \
    --namespace karpenter \
    --attach-policy-arn arn:aws:iam::$AWS_ACCOUNT_ID:policy/KarpenterControllerPolicy-$CLUSTER_NAME \
    --approve

# Execute only if this is the first time using spot instances in this account
aws iam create-service-linked-role \
    --aws-service-name spot.amazonaws.com

######################################################################################
#                   Applications Without Cluster Autoscaler                          #
######################################################################################

aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_DEFAULT_REGION

kubectl get nodes

kubectl apply --filename ../manifests/app.yaml

kubectl get pods,nodes

##########################################################################
#                         Install Karpenter                              #
##########################################################################

helm repo add karpenter \
    https://charts.karpenter.sh

helm repo update

helm upgrade --install \
    karpenter karpenter/karpenter \
    --namespace karpenter \
    --create-namespace \
    --set serviceAccount.create=false \
    --version 0.5.0 \
    --set controller.clusterName=$CLUSTER_NAME \
    --set controller.clusterEndpoint=$CLUSTER_ENDPOINT \
    --wait

kubectl --namespace karpenter get all

############################################################################################
#                           Scale Up Kubernetes Cluster With Karpenter                     #
############################################################################################

kubectl apply \
    --filename ../manifests/provisioner.yaml

kubectl get pods,nodes

kubectl --namespace karpenter logs \
    --selector karpenter=controller

#############################################################################################
#               Scale Down The Kubernetes Cluster With Karpenter                            #
#############################################################################################

kubectl delete --filename ../manifests/app.yaml

kubectl --namespace karpenter logs \
    --selector karpenter=controller

kubectl get nodes

#############################################################################################
#                                         Destroy                                           #
#############################################################################################

helm --namespace karpenter \
    uninstall karpenter

eksctl delete iamserviceaccount \
    --cluster $CLUSTER_NAME \
    --name karpenter \
    --namespace karpenter

aws cloudformation delete-stack \
    --stack-name Karpenter-$CLUSTER_NAME

eksctl delete cluster \
    --name $CLUSTER_NAME \
    --region $AWS_DEFAULT_REGION