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
