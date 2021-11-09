terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 1.0.10"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}


locals {
  common_prefix = "demo"
  elk_domain = "${local.common_prefix}-elk-domain"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_security_group" "es" {
  name = "${local.common_prefix}-es-sg"
  description = "Allow inbound traffic to ElasticSearch from VPC CIDR"
  vpc_id = aws_vpc.demo.id

  ingress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = [
          aws_vpc.demo.cidr_block
      ]
  }
}

resource "aws_instance" "app_server" {
  ami           = "ami-01cc34ab2709337aa"
  instance_type = "t2.micro"

  tags = {
    Name = "ExampleAppServerInstance"
  }
}

resource "aws_elasticsearch_domain" "example" {
  domain_name           = "example"
  elasticsearch_version = "7.10"

  cluster_config {
    instance_count = 3
    instance_type = "t2.small.elasticsearch"
    zone_awareness_enabled = true

      zone_awareness_config {
        availability_zone_count = 3
      }
  }

  vpc_options {
      subnet_ids = [
        aws_subnet.nated_1.id,
        aws_subnet.nated_2.id
      ]

      security_group_ids = [
          aws_security_group.es.id
      ]
  }

  ebs_options {
      ebs_enabled = true
      volume_size = 10
  }

  tags = {
    Domain = "TestDomain"
  }
}


