terraform {
  # Include required module for deployment
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  # Storing State in S3 Bucket !!DO NOT ALTER!!
  backend "s3" {
    bucket = var.S3_TF_STATE_BUCKET
    key = var.S3_TF_STATE_BUCKET_KEY
    region = var.REGION
  }
}



# Configure the module to work in a specific region
provider "aws" {
  region = var.REGION
}

# Create an empty cluster
resource "aws_ecs_cluster" "primary_cluster" {
  name = "s3-proxy-${var.S3_BUCKET_NAME}" # Cluster Name
}

# Create the task definition (container definition)
resource "aws_ecs_task_definition" "primary_task" {
  family = "s3-proxy-${var.S3_BUCKET_NAME}"
  # Define the container and point to the image (docker repos work - ECR Containers need a repo stanza)
  container_definitions = <<DEFINITION
  [
    {
      "name": "<Container Name>",
      "image": "<Docker Image>",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000
        }
      ],
      "memory": 512,
      "cpu": 256,
      "environment": [
        {"name": "S3_BUCKET_NAME", "value": "${var.s3-bucket-name}"},
        {"name": "S3_ACCESS_KEY_ID", "value": "${var.AWS_ACCESS_KEY}"},
        {"name": "S3_SECRET_KEY", "value": "${var.AWS_SECRET_ACCESS_KEY}"},
        {"name": "S3_SERVER", "value": "s3.${var.region}.amazonaws.com"},
        {"name": "S3_SERVER_PORT", "value": "80"},
        {"name": "S3_SERVER_PROTO", "value": "http"},
        {"name": "S3_REGION", "value": "${var.region}"},
        {"name": "S3_STYLE", "value": "virtual"},
        {"name": "S3_DEBUG", "value": "false"},
        {"name": "AWS_SIGS_VERSION", "value": "4"},
        {"name": "ALLOW_DIRECTORY_LIST", "value": "true"}
      ]
    }
  ]
  DEFINITION

  # Mandatory task configurations
  requires_compatibilities = ["FARGATE"] # Stating that we are using ECS Fargate
  network_mode             = "awsvpc"    # Using awsvpc as our network mode as this is required for Fargate
  memory                   = 512         # Specifying the memory our container requires
  cpu                      = 256         # Specifying the CPU our container requires
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
}

# The security role that will deploy the container
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name_prefix               = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

# The policy that the security role will assume
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Attaching the security policy to the role
resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name_prefix
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# The service definition
resource "aws_ecs_service" "primary_service" {
  name            = "name"                 # Naming our first service
  cluster         = aws_ecs_cluster.primary_cluster.id       # Referencing our created Cluster
  task_definition = aws_ecs_task_definition.primary_task.arn # Referencing the task our service will spin up
  launch_type     = "FARGATE"                                # Deployment Type Fargate is preferred
  desired_count   = 1                                        # Setting the number of containers we want deployed

# Mandatory network configurations
network_configuration {
    subnets          = [aws_default_subnet.default_subnet_a.id, aws_default_subnet.default_subnet_b.id, aws_default_subnet.default_subnet_c.id]
    security_groups  = [aws_security_group.name.id]
    assign_public_ip = true # Providing our containers with public IPs
  }
}

# Mount to the existing default VPC (i.e do not create a VPC)
resource "aws_default_vpc" "default_vpc" {
  enable_dns_hostnames = true
  enable_dns_support = true
}

# Providing a reference to our default subnets
resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = format("%s%s",var.region,"a")
}

resource "aws_default_subnet" "default_subnet_b" {
  availability_zone = format("%s%s",var.region,"b")
}

resource "aws_default_subnet" "default_subnet_c" {
  availability_zone = format("%s%s",var.region,"c")
}

# Create a ingress/egress security group that is implicitly bound the internet gateway
resource "aws_security_group" "name" {
  name = "security_group_example_app"
  description = "Allow TLS inbound traffic on port 80 (http)"
  vpc_id = aws_default_vpc.default_vpc.id

  # Map port 3000 on the container to port 80 HTTP Traffic
  ingress {
    from_port = 80
    to_port = 3000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}