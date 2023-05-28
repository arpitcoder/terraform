# Configure the provider
provider "aws" {
  region = "us-west-2"
}

# Create the RDS instance
resource "aws_db_instance" "mysql" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "admin"
  password             = "password"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

# Create the MySQL user
resource "aws_db_instance_user" "rotate_user" {
  username = "rotate_user"
  password = "rotator"
  db_instance_identifier = aws_db_instance.mysql.id
}

# Grant access to the MySQL user
resource "aws_db_instance_grant" "rotate_user_grant" {
  username = aws_db_instance_user.rotate_user.username
  db_name  = "*.*"
  privileges = [
    "SELECT",
    "INSERT",
    "UPDATE",
    "DELETE",
    "CREATE",
    "DROP",
    "RELOAD",
    "PROCESS",
    "REFERENCES",
    "INDEX",
    "ALTER",
    "SHOW DATABASES",
    "CREATE TEMPORARY TABLES",
    "LOCK TABLES",
    "EXECUTE",
    "REPLICATION SLAVE",
    "REPLICATION CLIENT",
    "CREATE VIEW",
    "SHOW VIEW",
    "CREATE ROUTINE",
    "ALTER ROUTINE",
    "CREATE USER",
    "EVENT",
    "TRIGGER"
  ]
  db_instance_identifier = aws_db_instance.mysql.id
}

# Create the rotate-user secret
resource "aws_secretsmanager_secret" "rotate_user_secret" {
  name = "rotate-user"
}

# Add the rotate-user secret to the rotation policy
resource "aws_secretsmanager_secret_rotation" "rotate_user_rotation" {
  secret_id = aws_secretsmanager_secret.rotate_user_secret.id
  rotation_lambda_arn = "arn:aws:lambda:us-west-2:123456789012:function:rotate-user-secret"
  rotation_rules = jsonencode([
    {
      "automatically_after_days": 30,
      "set_attributes": {
        "username": "rotate_user",
        "password": "${aws_db_instance_user.rotate_user.password}"
      }
    }
  ])
}

# Create the primary-mysql-rotation secret
resource "aws_secretsmanager_secret" "primary_mysql_rotation" {
  name = "primary-mysql-rotation"
}

# Add the primary-mysql-rotation secret to the rotation policy
resource "aws_secretsmanager_secret_rotation" "primary_mysql_rotation_rotation" {
  secret_id = aws_secretsmanager_secret.primary_mysql_rotation.id
  rotation_lambda_arn = "arn:aws:lambda:us-west-2:123456789012:function:primary-mysql-rotation-secret"
  rotation_rules = jsonencode([
    {
      "automatically_after_days": 30,
      "set_attributes": {
        "username": "admin",
        "password": "password"
      }
    },
    {
      "automatically_after_days": 30,
      "use_existing_secret": true,
      "previous_secrets": [
        {
          "arn": aws_secretsmanager_secret.rotate_user_secret.arn,
          "version_stage": "AWSCURRENT"
        }
      ]
    }
  ])
}
