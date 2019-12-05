variable "region" {
type=string
description="The Region in which VPC will be created"

}
variable "gcpProject" {
type=string
description="The Region in which VPC will be created"
}



variable "vpcname" {
type=string
description="Your VPC name"  
}

variable "subnet_cidr1" {
type=string
description="Subent CIDR value 1"
}

variable "subnet_cidr2" {
type=string
description="Subent CIDR value 2"
}

variable "subnet_cidr3" {
type=string
description="Subent CIDR value 3"
}

variable "enable_ssl" {
  description = "Set to true to enable ssl. If set to 'true', you will also have to provide 'var.custom_domain_name'."
  type        = bool
  default     = false
}

variable "enable_http" {
  description = "Set to true to enable plain http. Note that disabling http does not force SSL and/or redirect HTTP traffic. See https://issuetracker.google.com/issues/35904733"
  type        = bool
  default     = true
}





