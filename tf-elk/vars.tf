variable "eks_cluster_name" {
  type    = string
  default = "elk"
}

variable "component_name" {
  type        = string
  description = "Component name"
  default     = "elk"
}

variable "region" {
  type    = string
  default = "ap-southeast-2"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "es_metrics_endpoint" {
  type    = string
  default = "https://kibana.crms.myzeller.dev/es/test_metrics/_doc"
}

variable "alb_endpoint" {
  type    = string
  default = "https://kibana.crms.myzeller.dev"
}
