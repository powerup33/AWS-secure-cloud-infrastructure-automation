# ---------------------------------------------------------------------------
# VPC + EC2 with Systems Manager Session Manager access (no SSH, no key pair,
# no inbound ports). Built to stay cheap: no NAT gateway, no VPC endpoints.
#
# Design note: the instance sits in a public subnet with a public IP so it can
# reach the SSM service, but its security group allows NO inbound traffic.
# In production you'd put it in the private subnet and reach SSM through
# VPC interface endpoints (or a NAT gateway), which cost ~$7-30+/month each.
# ---------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Latest Amazon Linux 2023 AMI (SSM Agent is preinstalled)
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# --- Network ----------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "secure-cloud-vpc" }
}

# Lock down the VPC's default security group so nothing can accidentally use it
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id
  # No ingress or egress blocks = all rules removed
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "secure-cloud-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 1) # 10.0.1.0/24
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false # public IPs are assigned per instance, on purpose

  tags = { Name = "secure-cloud-public-a" }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 11) # 10.0.11.0/24
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = { Name = "secure-cloud-private-a" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "secure-cloud-public-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Private subnet: local routes only, no path to the internet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "secure-cloud-private-rt" }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# --- Security group: no inbound, HTTPS out only -----------------------------

resource "aws_security_group" "ssm_instance" {
  name        = "ssm-instance-sg"
  description = "No inbound access; HTTPS outbound for SSM and updates"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "HTTPS to AWS APIs (SSM) and package repos"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ssm-instance-sg" }
}

# --- IAM role so the instance can talk to Systems Manager -------------------

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ssm_instance" {
  name               = "ssm-instance-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm_instance.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_instance" {
  name = "ssm-instance-profile"
  role = aws_iam_role.ssm_instance.name
}

# --- EC2 instance -----------------------------------------------------------

resource "aws_instance" "ssm_managed" {
  ami                         = data.aws_ssm_parameter.al2023_ami.value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ssm_instance.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm_instance.name
  associate_public_ip_address = true  # needed to reach SSM without NAT or endpoints
  monitoring                  = false # detailed monitoring costs extra

  # No key_name: there is no SSH key, and port 22 is closed

  metadata_options {
    http_tokens   = "required" # enforce IMDSv2
    http_endpoint = "enabled"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  tags = { Name = "ssm-managed-instance" }
}

# --- Outputs ----------------------------------------------------------------

output "vpc_id" {
  value = aws_vpc.main.id
}

output "instance_id" {
  value = aws_instance.ssm_managed.id
}

output "ssm_connect_command" {
  value = "aws ssm start-session --target ${aws_instance.ssm_managed.id}"
}
