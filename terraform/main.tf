# ------------------------------------------------------------
# DEFAULT VPC
# Find the default VPC that already exists in the AWS account
# ------------------------------------------------------------

data "aws_vpc" "default" {
  default = true
}


# ------------------------------------------------------------
# UBUNTU 24.04 AMI
# Get the current Ubuntu 24.04 LTS image from Canonical
# ------------------------------------------------------------

data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/noble/stable/current/amd64/hvm/ebs-gp3/ami-id"
}


# ------------------------------------------------------------
# SUBNET
# Create a subnet inside the default VPC for the EC2 instance
# ------------------------------------------------------------

resource "aws_subnet" "web_subnet" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = cidrsubnet(data.aws_vpc.default.cidr_block, 8, 1)
  map_public_ip_on_launch = true

  tags = {
    Name    = "tech-challenge-3-subnet"
    Project = "Tech Challenge 3"
  }
}


# ------------------------------------------------------------
# SSH KEY PAIR
# Upload the public SSH key to AWS
# ------------------------------------------------------------

resource "aws_key_pair" "tech_challenge_key" {
  key_name   = "tech-challenge-3-key"
  public_key = file(pathexpand(var.public_key_path))

  tags = {
    Name    = "tech-challenge-3-key"
    Project = "Tech Challenge 3"
  }
}


# ------------------------------------------------------------
# SECURITY GROUP
# Create the firewall for the EC2 web server
# ------------------------------------------------------------

resource "aws_security_group" "web_sg" {
  name        = "tech-challenge-3-web-sg"
  description = "Security group for Tech Challenge 3 web server"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name    = "tech-challenge-3-web-sg"
    Project = "Tech Challenge 3"
  }
}


# Allow SSH only from my public IP address
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.web_sg.id

  cidr_ipv4   = var.allowed_ssh_cidr
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"

  description = "Allow SSH from administrator IP"
}


# Allow HTTP access from the internet
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.web_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"

  description = "Allow HTTP from the internet"
}


# Allow the EC2 instance to make outbound connections
resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.web_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  description = "Allow all outbound traffic"
}


# ------------------------------------------------------------
# S3 BUCKET
# Create the S3 bucket required by the challenge
# ------------------------------------------------------------

resource "aws_s3_bucket" "tech_challenge_bucket" {
  bucket_prefix = "tech-challenge-3-"

  tags = {
    Name    = "tech-challenge-3-bucket"
    Project = "Tech Challenge 3"
  }
}


# Prevent public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "tech_challenge_bucket" {
  bucket = aws_s3_bucket.tech_challenge_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# ------------------------------------------------------------
# IAM TRUST POLICY
# Allow EC2 to use the IAM role
# ------------------------------------------------------------

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}


# ------------------------------------------------------------
# IAM ROLE
# Create an IAM role for the EC2 instance
# ------------------------------------------------------------

resource "aws_iam_role" "ec2_role" {
  name               = "tech-challenge-3-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name    = "tech-challenge-3-ec2-role"
    Project = "Tech Challenge 3"
  }
}


# ------------------------------------------------------------
# S3 LEAST-PRIVILEGE POLICY
# Allow the EC2 instance to read only this S3 bucket
# ------------------------------------------------------------

data "aws_iam_policy_document" "s3_access" {

  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.tech_challenge_bucket.arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.tech_challenge_bucket.arn}/*"
    ]
  }
}


# Create the IAM policy
resource "aws_iam_policy" "s3_read_policy" {
  name        = "tech-challenge-3-s3-read-policy"
  description = "Allows Tech Challenge 3 EC2 instance to read its S3 bucket"
  policy      = data.aws_iam_policy_document.s3_access.json
}


# Attach the S3 policy to the EC2 IAM role
resource "aws_iam_role_policy_attachment" "s3_read_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_read_policy.arn
}


# ------------------------------------------------------------
# IAM INSTANCE PROFILE
# Connect the IAM role to the EC2 instance
# ------------------------------------------------------------

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "tech-challenge-3-ec2-profile"
  role = aws_iam_role.ec2_role.name
}


# ------------------------------------------------------------
# EC2 INSTANCE
# Create the Ubuntu web server
# ------------------------------------------------------------

resource "aws_instance" "web_server" {
  ami           = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type = var.instance_type

  # Place the EC2 instance inside the subnet created above
  subnet_id = aws_subnet.web_subnet.id

  # SSH key and firewall
  key_name               = aws_key_pair.tech_challenge_key.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # Attach IAM permissions
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  # Give the EC2 instance a public IP address
  associate_public_ip_address = true

  # Encrypt the EC2 disk
  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 8
  }

  # Require IMDSv2 for better security
  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name    = "tech-challenge-3-web-server"
    Project = "Tech Challenge 3"
  }
}
