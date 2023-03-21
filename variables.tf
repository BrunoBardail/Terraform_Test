# Déclaration des variables

variable "region" {
  description = "AWS region"
  default     = "ca-central-1"
}

variable "instance_type" {
  description = "Type of EC2 instance to provision"
  default     = "t2.micro"
}

variable "instance_name" {
  description = "EC2 instance name"
  default     = "Provisioned by Terraform"
}

variable "region_a" {
  description = "Région A"
  default ="ca-central-1"
}

variable "region_b" {
  description = "Région B"
  default ="eu-west-1"
}

variable "db_name" {
  description = "Nom de la base de données"
  default ="mytestdb"
}

variable "snapshot_id" {
  description = "ID du snapshot à restaurer"
  default =""
}

variable "iam_role_name" {
  description = "Nom du rôle IAM"
  default ="S3DynamoDBFullAccessRole"
}
