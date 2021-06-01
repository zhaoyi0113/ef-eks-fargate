# ef-eks-fargate

## Deploy EKS Clsuter

```bash
terraform apply
sh bin/patch_dsn.sh
sh bin/deploy_alb_ctr.sh
```

## Create alb controller

```bash
kubectl apply -f k8s/service-account.yaml
kubectl apply -f k8s/rdbc-role.yaml
kubectl apply -f k8s/alb-controller.yaml
```
