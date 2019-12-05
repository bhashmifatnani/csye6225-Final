

variable "url_map" {
  description = "A reference (self_link) to the url_map resource to use."
  type        = string
}




variable "enable_http" {
  description = "Set to true to enable plain http. Note that disabling http does not force SSL and/or redirect HTTP traffic. See https://issuetracker.google.com/issues/35904733"
  type        = bool
  default     = true
}


variable "gcpProject"{
  type=string
  description="Project id"
}