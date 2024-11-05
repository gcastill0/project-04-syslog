/**** **** **** **** **** **** **** **** **** **** **** ****
Prefix is here to emulate a required naming convention.
**** **** **** **** **** **** **** **** **** **** **** ****/
variable "prefix" {
  default = "syslog-ng"
}

/**** **** **** **** **** **** **** **** **** **** **** ****
Request the SDL API Token for the ingest configuration.
**** **** **** **** **** **** **** **** **** **** **** ****/
variable "SDL_TOKEN" {
  description = "The SDL API Token for the ingest configuration."
}

/**** **** **** **** **** **** **** **** **** **** **** ****
Default tags used to determine the identity and meta-data 
for the deployment. 
**** **** **** **** **** **** **** **** **** **** **** ****/

variable "tags" {
  type = map(any)

  default = {
    Organization = "Data"
    Keep         = "True"
    Owner        = "Gilberto"
    Region       = "US-EAST-1"
    Purpose      = "Syslog Testing"
    Environment  = "dev"
  }
}