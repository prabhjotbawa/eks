# Pod identity association
Pod identity association is a feature in Kubernetes that allows pods to securely access other cloud resources without having to manage separate credentials.

## Purpose
1. Secure access: Allows pods to access cloud services and resources without storing credentials in the cluster.
2. Simplified management: Eliminates the need to manually manage and rotate access keys for pods.
3. Fine-grained control: Enables assigning specific permissions to individual pods or groups of pods.

## How it works
The pod is associated with a cloud identity (e.g. IAM role in AWS, managed identity in Azure)
- The cloud provider validates the pod's identity and provides temporary credentials
- The pod can then use these credentials to access allowed cloud resources

This feature is particularly useful in cloud-native Kubernetes deployments where pods frequently need to interact with other cloud services securely.
The service account token (secret) is mounted on to the pod, which can then authenticate with other services using the IAM role permissions.
The service account itself is also associated with a role to perform CRUD operations as applicable.

## Example
1. IAM Role Creation:
   Create an IAM role in AWS with permissions to access the specific S3 bucket.

2. Service Account Configuration:
   Create a service account and associate it with the IAM role.

   ```yaml
   apiVersion: v1
   kind: ServiceAccount
   metadata:
     name: s3-access-sa
     annotations:
       eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/S3AccessRole
   ```
   Terraform equivalent of above can be seen [here](cluster-autoscaler.tf)

3. Pod Definition:
   Create a pod that uses this service account.

   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: s3-access-pod
   spec:
     serviceAccountName: s3-access-sa
     containers:
     - name: app
       image: my-app-image
   ```
NB: The pod could also mount the secret as a volume and read from it. Eg:

```yaml
    volumeMounts:
    - mountPath: /tmp/k8s-webhook-server/serving-certs
      name: cert
      readOnly: true
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-jl8f9
      readOnly: true
    - mountPath: /var/run/secrets/pods.eks.amazonaws.com/serviceaccount
      name: eks-pod-identity-token
      readOnly: true
  dnsPolicy: ClusterFirst
  enableServiceLinks: true
  nodeName: ip-10-0-20-47.us-east-2.compute.internal
  preemptionPolicy: PreemptLowerPriority
  priority: 2000000000
  priorityClassName: system-cluster-critical
  restartPolicy: Always
  schedulerName: default-scheduler
  securityContext:
    fsGroup: 65534
  serviceAccount: aws-load-balancer-controller
  serviceAccountName: aws-load-balancer-controller
  terminationGracePeriodSeconds: 10
  tolerations:
  - effect: NoExecute
    key: node.kubernetes.io/not-ready
    operator: Exists
    tolerationSeconds: 300
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
    tolerationSeconds: 300
  volumes:
  - name: eks-pod-identity-token
    projected:
      defaultMode: 420
      sources:
      - serviceAccountToken:
          audience: pods.eks.amazonaws.com
          expirationSeconds: 86400
          path: eks-pod-identity-token
  - name: cert
    secret:
      defaultMode: 420
      secretName: aws-load-balancer-tls
```

The cert volume points to a secret which is mounted in the container and can be used to interact with the service which
trusts the cert (can be IAM, EC2 etc, as per the IAM role)

4. Pod Operation:
   When the pod runs:
   - It automatically receives temporary AWS credentials.
   - These credentials are made available to the pod via environment variables and/or the AWS SDK.
   - The application in the pod can now use these credentials to access the S3 bucket without any additional configuration.

5. Access S3:
   Your application code can now access S3 using standard AWS SDK calls, like:

   ```python
   import boto3

   s3 = boto3.client('s3')
   s3.put_object(Bucket='my-bucket', Key='my-file', Body='Hello World')
   ```