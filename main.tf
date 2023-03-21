provider "aws" {
  region = var.region
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "ubuntu" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  tags = {
    Name = var.instance_name
  }
}

# Création de la base de données Postgres dans la région A
resource "aws_db_instance" "postgres" {
  identifier_prefix = "postgres"
  engine = "postgres"
  instance_class = "db.t2.medium"
  name = var.db_name
  allocated_storage = 10
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.postgres.id]
  availability_zone = "${var.region_a}"
}

# Création de la fonction Lambda pour restaurer la base de données
resource "aws_lambda_function" "restore_postgres_db" {
  filename = "lambda_function_payload.zip"
  function_name = "restore_postgres_db"
  role = aws_iam_role.lambda_role.arn
  handler = "lambda_function.lambda_handler"
  runtime = "python3.8"
}

# Création du rôle IAM pour la fonction Lambda
resource "aws_iam_role" "lambda_role" {
  name = var.iam_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Autorisations pour le rôle IAM
# resource "aws_iam_policy_attachment" "lambda_policy_attachment" {
#  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
#  roles = [aws_iam_role.lambda_role.arn] 
# }

# Association du rôle IAM et de la politique
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

# Déclenchement de la fonction Lambda par une alerte CloudWatch
resource "aws_cloudwatch_event_rule" "trigger_restore_postgres_db" {
  name = "trigger_restore_postgres_db"
  description = "Déclenche la fonction Lambda pour restaurer la base de données Postgres"
  event_pattern = jsonencode({
    source = ["aws.rds"]
    detail_type = ["RDS DB Instance Event"]
    detail = {
      EventCategories = ["backup"]
      SourceType = ["snapshot"]
      SourceARN = ["arn:aws:rds:${var.region_a}::snapshot:${var.snapshot_id}"]
    }
  })
}

resource "aws_cloudwatch_event_target" "restore_postgres_db_target" {
  target_id = "restore_postgres_db_target"
  rule = aws_cloudwatch_event_rule.trigger_restore_postgres_db.name
  arn = aws_lambda_function.restore_postgres_db.arn
}

# Déclaration du groupe de sécurité pour la base de données Postgres
resource "aws_security_group" "postgres" {
  name = "postgres"
  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
