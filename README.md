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
- Load balancer routes traffic to nginx controller pod which interacts with cert manager to secure traffic

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
services like EC2, ELB using the service accounts associated with an IAM role however pod identity association is newer and seems 
to be simpler and a good replacement.
A word about [pod identity association](../../gitprojects/interview/pod_indentity_association.md) and also a good explanation from AWS docs can be found [here](https://aws.amazon.com/blogs/containers/amazon-eks-pod-identity-a-new-way-for-applications-on-eks-to-obtain-iam-credentials/)
Control plane logs are not enabled by default, however can be enabled by setting it in `eks.tf`
- cert-manger.tf: needed when using TLS with nginx controller to generate certs using cert-manager to encrypt the traffic
- storage: ebs (ReadWriteOnce), efs (ReadWriteMany) - can be used to write data concurrently

## Connecting with AWS
Export keys, also the session id if MFA is enabled:

```bash
export AWS_ACCESS_KEY_ID=<Get it from the AWS account>
export AWS_SECRET_ACCESS_KEY=<Get it from the AWS account>
export AWS_SESSION_TOKEN=<For MFA based accounts>

```
Similar to `oc login` run the below command to get caller identity
```commandline
aws sts get-caller-identity
```
Update the kubeconfig:
```commandline
aws eks update-kubeconfig --region us-east-2 --name staging-mydemocluster
```

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

- Targeting resources
```bash
terraform destroy -target=aws_eks_addon.pod_identity # resource.name
terraform apply -target=aws_eks_addon.pod_identity
```

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

## Some best practices followed
- Used `depends_on` to handle dependencies that terraform doesn't know, eg: nginx depends on lbc since the latter is needed
to create a load balancer. If I were to remove `lbc`, `nginx` will also get removed though so must be used with caution.
- Used `postcondition` to check resources.

## A note about IAM roles
Throughout we use IAM roles for specific operations to implement the rule of least privilege. IAM roles use temporary tokens
so they are more secure in an event if the token got leaked. Let's take the example of the IAM role of [eks](./eks.tf)
Important aspects of the role:
Assume Role Policy:
The assume_role_policy attribute defines who or what can assume this role. It's written in JSON format.
Policy details:
a. "Version": "2012-10-17" - This is a standard version number for AWS IAM policy documents.
b. "Statement": This contains an array of policy statements. In this case, there's only one statement.
c. The statement details:

"Effect": "Allow" - This statement allows the specified action.
"Action": "sts:AssumeRole" - The allowed action is to assume this role.
"Principal": { "Service": "eks.amazonaws.com" } - This specifies who can assume the role. In this case, it's the EKS service.


HEREDOC Syntax:
The <<POLICY and POLICY at the end are using Terraform heredoc syntax to include a multi-line string.

What this role does:
This IAM role is specifically created for Amazon EKS (Elastic Kubernetes Service). It allows the EKS service to assume this role, which is a crucial part of setting up an EKS cluster.
When an EKS cluster is created, AWS needs permissions to create and manage resources on our (or the logged on user's) behalf (like EC2 instances, security groups, etc.). This role provides the trust relationship that allows EKS to do that.

### What's STS??

The "sts" in "sts:AssumeRole" refers to AWS Security Token Service (STS). Further explanation:

AWS Security Token Service (STS):
STS is a web service that enables you to request temporary, limited-privilege credentials for AWS Identity and Access Management (IAM) users or for users that are authenticated (federated users).
I am authenticated using the `admin` user token. However, I don't want to use that with EKS, so we use STS instead.

AssumeRole Action:
"AssumeRole" is one of the primary actions provided by STS. When we assume a role, STS returns temporary security credentials that we can use to access AWS resources that we might not normally have access to.
How it works in this context:
In the above IAM role, "sts:AssumeRole" is allowing the EKS service (eks.amazonaws.com) to assume this role. This means:
1. When AWS needs to perform actions on behalf of the EKS cluster, it uses STS to assume this role.
2. STS provides temporary credentials that allow EKS to act with the permissions granted to this role.
3. This process happens automatically in the background when EKS needs to create or manage resources for your cluster.
Why use STS:

Security: It allows for fine-grained, temporary access without needing to create and manage long-term credentials.
Flexibility: It enables cross-account access and federation with external identity providers.
Principle of least privilege: Services or users can get only the permissions they need, when they need them.


Other common STS actions:

AssumeRoleWithWebIdentity: Used for web identity federation
AssumeRoleWithSAML: Used with SAML-based federation
GetSessionToken: Used to get temporary credentials for an IAM user

A simple [diagram](sts.mmd) to illustrate how STS works in this context:

1. EKS service requests to assume the role from STS.
2. STS checks with the IAM role to see if EKS is allowed to assume it.
3. The IAM role (configured as we saw earlier) allows this.
4. STS provides temporary credentials to EKS.
5. EKS can then use these credentials to access necessary AWS resources.

The actual permissions which EKS can perform are defined in the `resource "aws_iam_role_policy_attachment" "eks` resource. IAM role is to
define the trust relationship. Here we the permissions defined in `arn:aws:iam::aws:policy/AmazonEKSClusterPolicy`. See below:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags",
                "ec2:DescribeInstances",
                "ec2:DescribeRouteTables",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSubnets",
                "ec2:DescribeVolumes",
                "ec2:DescribeVpcs",
                "eks:DescribeCluster",
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:DescribeTargetGroups",
                "elasticloadbalancing:DescribeTargetHealth"
            ],
            "Resource": "*"
        }
    ]
}
```
This policy allows EKS to:

1. Describe (view) various EC2 resources like instances, route tables, security groups, etc.
2. Create tags on EC2 resources.
3. Describe its own cluster.
4. View information about Elastic Load Balancers.

It doesn't include permissions to modify or delete these resources, adhering to the principle of least privilege.

## TO DO
Figure out why nginx service (load balancer) deletion doesn't remove the LB.
Workaround: Remove the `nginx-service-controller` resource and run `terraform destroy`
This can be automated to query the resource, remove it before running the `terraform destroy` command.