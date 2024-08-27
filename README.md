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
Note: Typically addons like storage drivers, CNI drivers use OIDC providers to link IAM roles with service accounts however
components like metrics server, cluster auto scaler can use pod identity association to authenticate
Control plane logs are not enabled by default, however can be enabled by setting it in `eks.tf`
- cert-manger.tf: needed when using TLS with nginx controller to generate certs using cert-manager to encrypt the traffic