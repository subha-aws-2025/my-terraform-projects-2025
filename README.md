# Terraform Project: Highly Available Web Server with S3 Access on AWS

This Terraform project provisions a highly available web server setup on AWS. It includes a custom VPC, public subnets, an Application Load Balancer (ALB), and EC2 instances running a web server that displays metadata. Additionally, it creates an S3 bucket and an IAM role with an instance profile, allowing EC2 instances to interact with the S3 bucket.

---

## 🚀 Features

- **Custom VPC** with CIDR block
- **Two Public Subnets** in different Availability Zones
- **Internet Gateway (IGW)** for internet access
- **Route Table** with routes to the IGW
- **Security Groups** allowing:
  - SSH (port 22)
  - HTTP (port 80)
- **Application Load Balancer (ALB)** with:
  - Listener on port 80
  - Target group with registered EC2 instances
- **Two EC2 Instances**:
  - Run a simple web server serving EC2 metadata
  - Use a **user data** script on boot
  - Have access to an S3 bucket
- **S3 Bucket**:
  - Created via Terraform
  - Used to demonstrate instance profile access
- **IAM Role and Instance Profile**:
  - Role with policy to allow S3 access
  - Attached to EC2 instances
- **Outputs**:
  - DNS name of the Application Load Balancer
  - using the DNS , you can access the webservers balanced by the Application Load Balancer

---

## 📁 Project Structure

```bash
.
├── main.tf           # Main infrastructure configuration
├── variables.tf      # Input variables
├── outputs.tf        # Output variables
├── userdata.sh       # Script run on EC2 instances to serve metadata
├── terraform.tfvars  # Optional variable values file (not committed)
└── README.md         # Project documentation
