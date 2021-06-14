# ef-eks-fargate

## enable logging

```bash
kubectl apply -f k8s/aws-logging.yaml
```

## Deploy EKS Clsuter

```bash
terraform apply
sh bin/patch_dsn.sh
# sh bin/deploy_alb_ctr.sh
```
wait until `coredns` pod becomes available.

## Create alb controller

```bash
kubectl apply -f k8s/alb/service-account.yaml
kubectl apply -f k8s/alb/cert-manager.yaml
kubectl apply -f k8s/alb/rbac.yaml
kubectl apply -f k8s/alb/alb-controller.yaml
```

## Create EFS Driver

```bash
sh bin/deploy_efs_service_account.sh
kubectl apply -f k8s/efs/driver.yaml
kubectl apply -f k8s/efs/pv.yaml


# sh bin/create_efs.sh

# follow the instruction https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html to create mount target
```
