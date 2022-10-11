variable "REGION" {
  description = "Your AWS Region"
  type        = string
  default     = "us-east-1"
}


variable "S3_SOURCE_BUCKET" {
  description = "The name of the aws s3 bucket you want to use"
  type        = string
  default = "source-bucket"
}

variable "S3_TF_STATE_BUCKET" {
    description = "The name of the aws s3 bucket you want to use to store Terraform state"
    type = string
    default = "tf-state-bucket"
}

variable "S3_TF_STATE_BUCKET_KEY" {
    description = "The name of the aws s3 bucket you want to use to store Terraform state"
    type = string
    default = "<tf-state-parent-folder>/<bucket-name>"
}

variable "AWS_ACCESS_KEY" {
  description = "Your aws access key which is also mapped to TF_VAR_AWS_ACCESS_KEY Env Var"
  type        = string
  sensitive = true
}

variable "AWS_SECRET_ACCESS_KEY" {
  description = "Your aws secret access key which is also mapped to TF_VAR_SECRET_AWS_ACCESS_KEY Env Var"
  type        = string
  sensitive = true
}