resource "aws_security_group" "db_sg" {
  name        = "${var.db_name}-sg"
  description = "Allow EKS traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [var.eks_node_sg_id] # Security: Only Pods can talk to DB
  }
}

resource "aws_db_instance" "this" {
  identifier           = replace(lower(var.db_name), "_", "-")
#  identifier           = var.db_name
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  db_name              = var.db_name
  username             = var.username
  password             = var.password
  db_subnet_group_name = var.db_subnet_group
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  multi_az             = true # Production High Availability
  skip_final_snapshot  = true
}
