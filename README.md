## Overall Idea
- The node is not exposed to the internet so uses private subnet
- Two zones to make infra highly available
- Load balancers to expose services, the load balancer is on the public subnet and talk with node (EC2 instance with auto-scaling)
on the private subnet via the route tables
- In the same vein, node can reach out to the network via the NAT (on the public subnet) to download packages such as python
libraries, helm charts
- The load balancer connects to the internet via a IGW and the whole set up is in a VPC
- A word about the route tables:
2 of them to route traffic in/out of the cluster
1) Private -> Routes traffic from the NAT to the IGW for downloading packages from the internet, connected with private subnet
2) Public -> Routes traffic from the IGW to the load balancer to communicate with ingress.
- Load balancer

## Files
- locals.tf: local variables
- vpc.tf: creates a VPC to run the EKS and other components like NAT GW, IGW, load balancers etc
- subnets.tf: creates private and public subnets for both the availability zones
- igw.tf: creates an `igw` for the vpc
- nat.tf: creates a nat gw in the public subnet
- routes.tf: create the necessary route tables to manage the traffic
- eks.tf: creates the eks cluster, creates IAM role to assume the service and use it, the cluster does not have components
like metrics server, nginx controller, cloudwatch logs enabled by default, so they must be enabled separately. k8s will 
override the logs and as such as a best practice external logging solutions loki can also be used to get better results.
- node.tf: create the ec2 instance with the desired specs.
- helm-provider.tf: Install helm on nodes. Uses auth token to authenticate with k8s.
- metrics-server.tf: applies the helm chart to install metrics server
- cluster-autoscaler.tf: applies helm chart to crate the autoscaler
- aws-lb.tf: creates lb, reads the polices from a json file
- nginx-controller.tf: installs the nginx controller and an instance of the IngressClassResource which will be used to create
a nlb balancer to manage traffic into the cluster, NLB are cost-effective and use config map to point to different services
using the same load balancer
**Note**: Typically addons like storage drivers, CNI drivers use OIDC providers to link IAM roles with service accounts however
components like load balancer, cluster auto scaler can use pod identity association to authenticate themselves with other AWS
services like EC2, ELB using the service accounts associated with an IAM role.
A word about [pod identity association](pod_indentity_association.md) and also a good explanation from AWS docs can be found [here](https://aws.amazon.com/blogs/containers/amazon-eks-pod-identity-a-new-way-for-applications-on-eks-to-obtain-iam-credentials/)
Control plane logs are not enabled by default, however can be enabled by setting it in `eks.tf`
- cert-manger.tf: needed when using TLS with nginx controller to generate certs using cert-manager to encrypt the traffic

## Debugging
# Terraform
- Set env vars `TF_LOG` and `TF_LOG_PATH`
```bash
export TF_LOG='DEBUG'
export TF_LOG_PATH='/tmp/some_file'
```
Using `helm` directly
```commandline
helm install chart my-chart --debug
helm  upgrade --install chart my-chart --debug
```
- Investigate the `.tfstate` file
- Forward logs to tools like the ELK stack, splunk, grafana etc..
- Use validation block, an example below:
```terraform
variable "instance_type" {
  description = "Instance type t2.micro"
  type        = string
  default     = "t2.medium"
 
  validation {
   condition     = can(regex("^[Tt][2-3].(nano|micro|small)", var.instance_type))
   error_message = "Invalid Instance Type name. You can only choose - t2.nano,t2.micro,t2.small"
 }
}
```

- For errors `Error: cannot re-use a name that is still in use`, remove the secrets that have `helm` in the name
- To view all the values of a resource run the below command:
```commandline
terraform state show aws_eks_pod_identity_association.cluster_autoscaler
```
You an replace `aws_eks_pod_identity_association.cluster_autoscaler` with any other resource to view the details.

## EKS additional charts
Repo: https://github.com/aws/eks-charts/tree/master/stable
It has all the details including the configuration.
An example: https://github.com/aws/eks-charts/tree/master/stable/appmesh-prometheus#configuration
Every chart has templated values to override deployment object since it uses jinja as the templating language. Either
the values can be defined in `values` file or set using `set` keyword in `terraform` helm resource.

## Dockerfile
To create your own image for the test app, run
```commandline
docker buildx build -t image:tag . --platform=linux/amd64
```
Push to dockerhub to use it in the deployment