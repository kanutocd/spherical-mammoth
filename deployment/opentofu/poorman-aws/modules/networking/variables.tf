variable "name" { type = string }
variable "availability_zone" { type = string }
variable "vpc_cidr" { type = string }
variable "private_subnet_cidr" { type = string }
variable "instance_ingress_ports" {
  description = "TCP ports reachable only through EICE."
  type        = set(number)
  default     = [22]
}
variable "tags" {
  type    = map(string)
  default = {}
}
