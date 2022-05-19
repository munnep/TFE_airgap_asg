from diagrams import Cluster, Diagram, Edge
from diagrams.aws.compute import EC2, EC2AutoScaling
from diagrams.aws.network import Route53,VPC, PrivateSubnet, PublicSubnet, InternetGateway, NATGateway, ElbApplicationLoadBalancer
from diagrams.onprem.compute import Server
from diagrams.aws.storage import SimpleStorageServiceS3Bucket
from diagrams.aws.database import RDSPostgresqlInstance

# Variables
title = "VPC with 2 public subnets and 2 private subnets \n Private subnet has a RDS PostgreSQL and a autoscaling group for TFE. \n Single application loadbalancer which is high available and therefore in both public subnets"
outformat = "png"
filename = "diagram_tfe_asg"
direction = "TB"


with Diagram(
    name=title,
    direction=direction,
    filename=filename,
    outformat=outformat,
) as diag:
    # Non Clustered
    user = Server("user")
    route53=Route53("DNS record in AWS")

    # Cluster 
    with Cluster("vpc"):
        bucket_tfe = SimpleStorageServiceS3Bucket("TFE bucket")
        bucket_files = SimpleStorageServiceS3Bucket("TFE airgap files")
        igw_gateway = InternetGateway("igw")

        with Cluster("Availability Zone: eu-north-1b"):
            # Subcluster
            with Cluster("subnet_private2"):
                with Cluster("DB subnet"):
                            postgresql2 = RDSPostgresqlInstance("RDS different AZ")
            with Cluster("subnet_public2"):
                loadbalancer2 = ElbApplicationLoadBalancer("Application \n Load Balancer")
                        # Subcluster

        with Cluster("Availability Zone: eu-north-1a"):
            # Subcluster 
            with Cluster("subnet_public1"):
                loadbalancer1 = ElbApplicationLoadBalancer("Application \n Load Balancer")
                nat_gateway = NATGateway("nat_gateway")
            # Subcluster
            with Cluster("subnet_private1"):
                asg_tfe_server = EC2AutoScaling("Autoscaling Group \n Webserver")
                with Cluster("DB subnet"):
                        postgresql = RDSPostgresqlInstance("RDS Instance")
 
    # Diagram
    user >>  route53
    user >>  [ loadbalancer1, 
              loadbalancer2] >> asg_tfe_server 

    asg_tfe_server >> nat_gateway >> igw_gateway 

    asg_tfe_server >> [postgresql,
                       bucket_tfe, 
                       bucket_files]
    
    route53
diag
