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

variable "es_endpoint" {
  type    = string
  default = "https://k8s-sidecar-7a158acff4-940632450.ap-southeast-2.elb.amazonaws.com/es/test_metrics"
}
