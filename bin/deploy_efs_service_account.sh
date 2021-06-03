CLUSTER_NAME=${1:-elk}
echo "create for $CLUSTER_NAME"

eksctl create iamserviceaccount \
    --name $CLUSTER_NAME-efs-csi-controller-sa \
    --namespace kube-system \
    --cluster $CLUSTER_NAME \
    --attach-policy-arn arn:aws:iam::264100014405:policy/${CLUSTER_NAME}_efs_csi_driverpolicy \
    --approve \
    --override-existing-serviceaccounts