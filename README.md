# ef-eks-fargate

## Deploy EKS Clsuter

```bash
terraform apply
sh bin/patch_dsn.sh
sh bin/deploy_alb_ctr.sh
```

## Create alb controller

```bash
#kubectl apply -f k8s/service-account.yaml
kubectl apply -f k8s/alb/rbac-role.yaml
kubectl apply -f k8s/alb/alb-controller.yaml
```

## Create EFS Driver

```bash
sh bin/deploy_efs_service_account.sh
kubectl apply -f k8s/efs/driver.yaml


# sh bin/create_efs.sh

# follow the instruction https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html to create mount target
```
