
variable "PrimaryDatabaseName" {
  type = string
}

variable "SecondaryDatabaseName" {
  type = string

}

variable "CronSchedule" {
  type = string
}

variable "VpcNetwork" {
  type = string
}

variable "VpcFirwall" {
  type = string
}

variable "CloudStorageBucket" {
  type = string
}

variable "RetentionPeriod" {
  type = number
}

variable "MachineType" {
  type = string
}

variable "CPUUsageThreshold" {
  type = number
}


variable "DiskUsageThreshold" {
  type = number
}


variable "Zone" {
  type = string
}


variable "MachinImage" {
  type = string
}

variable "Location" {
  type = string
}