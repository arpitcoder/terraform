This is a IaC project to create a terraform configuration file to rotate the RDS MySQL instance keys.

This uses alternate user strategy which will use a primary user and a rotate_user to alternate when there is a
process undergoing for rotating the primary secret.
