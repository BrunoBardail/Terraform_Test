# Déclaration des variables
variable "region_a" {
  description = "Région A"
}

variable "region_b" {
  description = "Région B"
}

variable "db_name" {
  description = "Nom de la base de données"
}

variable "snapshot_id" {
  description = "ID du snapshot à restaurer"
}

variable "iam_role_name" {
  description = "Nom du rôle IAM"
}
