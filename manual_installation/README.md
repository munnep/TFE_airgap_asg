# Manual steps

This document describes the manual steps for creating a autoscaling group with TFE behind an application load balancer which you can then connect to over the internet. The TFE is in a private subnet

See below diagram for how the setup is:
![](../diagram/diagram_tfe_asg.png)

## network
- Create a VPC with cidr block ```10.233.0.0/16```  
![](media/2021-12-08-13-51-43.png)  
- Create 4 subnets. 2 public subnets and 2 private subnet
    - patrick-public1-subnet (ip: ```10.233.1.0/24``` availability zone: ```eu-north-1a```)  
    - patrick-public2-subnet (ip: ```10.233.2.0/24``` availability zone: ```eu-north-1b```)  
    - patrick-private1-subnet (ip: ```10.233.11.0/24``` availability zone: ```eu-north-1a```)  
    - patrick-private2-subnet (ip: ```10.233.12.0/24``` availability zone: ```eu-north-1b```)  
![](media/20220520112620.png)  
- create an internet gateway and attach to VPC  
![](media/2021-12-08-14-07-45.png)    
![](media/2021-12-08-14-08-09.png)  
- create a nat gateway which you attach to ```patrick-public1-subnet```   
![](media/2021-12-08-15-20-55.png)  
- create routing table for public  
![](media/2021-12-08-14-10-55.png)  
   - edit the routing table for internet access to the internet gateway
   ![](media/2021-12-08-14-12-18.png)  
- create routing table for private  
   ![](media/2021-12-08-14-13-32.png)  
   - edit the routing table for internet access to the nat gateway  
   ![](media/2021-12-08-14-14-41.png)   
- attach routing tables to subnets  
    - patrick-public-route to public subnets      
    ![](media/2021-12-08-14-16-18.png)      
    - patrick-private-route to private subnet   
     ![](media/2021-12-08-14-17-53.png)    
- create a security group that allows https, 8800 
port 5432 for PostgreSQL database   
![](media/20220520145617.png)    
- 

## create the RDS postgresql instance
Creating the RDS postgreSQL instance to use with TFE instance

- PostgreSQL instance version 12    
![](media/20220520114000.png)    
![](media/20220520114021.png)    
![](media/20220520114058.png)    
![](media/20220520114149.png)    
![](media/20220520114220.png)    
![](media/20220520130636.png)    


endpoint: ```patrick-manual-tfe.cvwddldymexr.eu-north-1.rds.amazonaws.com```

# AWS to use
- create a bucket patrick-tfe-manual and patrick-tfe-software
 ![](media/20220520114455.png)   
 ![](media/20220520114508.png)    
- upload the following files to patrick-tfe-software
![](media/20220520123941.png)    

- create IAM policy to access the buckets from the created instance
- create a new policy
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:DeleteObject",
                "s3:GetBucketLocation"
            ],
            "Resource": [
                "arn:aws:s3:::patrick-tfe-manual",
                "arn:aws:s3:::patrick-tfe-software",
                "arn:aws:s3:::*/*"
            ]
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "s3:ListAllMyBuckets",
            "Resource": "*"
        }
    ]
}
```

- create a new role  
![](media/20220520124616.png)    
![](media/20220520124635.png)    
![](media/20220520124711.png)    


## closer look
- attach the role to the instance  
![](media/20220510160613.png)  
![](media/20220510104028.png)    
- you should now be able to upload a file to the s3 bucket
```
ubuntu@ip-10-233-1-81:~$ aws s3 cp test.txt s3://patrick-tfe-manual/test.txt
upload: ./test.txt to s3://patrick-tfe-manual/test.txt
```

## certificates
import certificates
![](media/20220520124850.png)    
![](media/20220520124941.png)    
![](media/20220520125011.png)    

## Auto-launch scaling group
- Auto Scaling - Launch Configurations  
![](media/20220520125432.png)  
- Create launch configuration. 
![](media/20220520125530.png)  
![](media/20220520125655.png)    
```
#!/bin/bash

# Download all the software and files needed
aws s3 cp s3://patrick-tfe-software/610.airgap /tmp/610.airgap
aws s3 cp s3://patrick-tfe-software/license.rli /tmp/license.rli
aws s3 cp s3://patrick-tfe-software/replicated.tar.gz /tmp/replicated.tar.gz

# directory for decompress the file
sudo mkdir -p /opt/tfe
pushd /opt/tfe
sudo tar xzf /tmp/replicated.tar.gz


cat > /tmp/tfe_settings.json <<EOF
{
   "aws_instance_profile": {
        "value": "1"
    },
    "enc_password": {
        "value": "Password#1"
    },
    "hairpin_addressing": {
        "value": "1"
    },
    "hostname": {
        "value": "patrick-tfe.bg.hashicorp-success.com"
    },
    "pg_dbname": {
        "value": "tfe"
    },
    "pg_netloc": {
        "value": "patrick-manual-tfe.cvwddldymexr.eu-north-1.rds.amazonaws.com"
    },
    "pg_password": {
        "value": "Password#1"
    },
    "pg_user": {
        "value": "postgres"
    },
    "placement": {
        "value": "placement_s3"
    },
    "production_type": {
        "value": "external"
    },
    "s3_bucket": {
        "value": "patrick-tfe-manual"
    },
    "s3_endpoint": {},
    "s3_region": {
        "value": "eu-north-1"
    }
}
EOF


# replicated.conf file
cat > /etc/replicated.conf <<EOF
{
    "DaemonAuthenticationType":          "password",
    "DaemonAuthenticationPassword":      "Password#1",
    "TlsBootstrapType":                  "self-signed",
    "TlsBootstrapHostname":              "patrick-tfe.bg.hashicorp-success.com",
    "BypassPreflightChecks":             true,
    "ImportSettingsFrom":                "/tmp/tfe_settings.json",
    "LicenseFileLocation":               "/tmp/license.rli",
    "LicenseBootstrapAirgapPackagePath": "/tmp/610.airgap"
}
EOF

# Following manual:
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-data-retrieval.html
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
LOCAL_IP=`curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/local-ipv4`
echo ${LOCAL_IP}

sudo bash ./install.sh airgap private-address=${LOCAL_IP}

````
![](media/20220520132657.png)    
![](media/20220520132720.png)    
![](media/20220520132750.png)    
![](media/20220520132810.png)    
- The launch configuration should now be visible  
![](media/20220520132828.png)  


- loadbalancer create a target group which we at a later point connect to the Auto Scaling Group  
 ![](media/20220520133657.png)  
 ![](media/20220520133733.png)    
- Will have no targets yet  
![](media/20220520133755.png)    

- do the same for the tfe-app port 443

- loadbalancer create a appplication load balancer which will connect to the load balancer target    
![](media/20220520133950.png)    
- following configuration  
![](media/20220520134014.png)  
![](media/20220520134040.png)    
![](media/20220520134059.png)    
![](media/20220520134138.png)    
![](media/20220520134318.png)    
![](media/20220520134341.png)    


- Auto Scaling groups. Will configure the group and connect it to auto scaling launch and the created load balancer
Make sure you switch to launch configuration   
![](media/20220520134600.png)    
![](media/20220520134625.png)    
![](media/20220520134702.png)    
![](media/20220520134759.png)    
![](media/20220520134837.png)    
![](media/20220520134852.png)    
![](media/20220520134913.png)      

- You should now see an instance being started   
![](media/20220412113300.png)       


- Alter the DNS record in route53 to point to the loadbalancer dns name    
![](media/20220520134508.png)  
- You should now be able to connect to your website   


### Test the autoscaling

After everything is working you should see one web server running and one web server as a target in the load balancer target group

EC2   
![](media/20220412113820.png)    

Load balancer target  
![](media/20220412113839.png)    

**Change the Auto scaling group to have 2 servers**
- Edit your Auto scaling group  
- Change the desired capacity to 2  
![](media/20220412113904.png)    

- After that you should see 2 EC2 instances and load balancer target with 2 instances    
![](media/20220412114410.png)  























- Auto Scaling groups. Will configure the group and connect it to auto scaling launch and the created load balancer  


- loadbalancer generated a DNS name which you can use to connect to the application server  


### Test the autoscaling

After everything is working you should see one web server running and one web server as a target in the load balancer target group

EC2   

Load balancer target  

**Change the Auto scaling group to have 2 servers**
- Edit your Auto scaling group  

- Change the desired capacity to 2  

- After that you should see 2 EC2 instances and load balancer target with 2 instances  


