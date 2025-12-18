/*
===========================================================
Instellen AWS
===========================================================
- Definieer de provider (AWS)
- Stel region in  
*/

# Definieer de provider (AWS)
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.5.0"
    }
  }
}

# Stel de region in 
provider "aws" {
  region = "eu-west-1"
}

/*
===========================================================
Security group & SSH
===========================================================
- Maak een nieuwe SSH key
- Maak een security group 
*/

# Genereer een Terraform key-pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Maak een AWS key-pair aan met de Terraform keys
resource "aws_key_pair" "generated" {
  key_name   = "terraform-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Save de private key
resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "terraform-key.pem"
  file_permission = "0400"
}

# Maak een security group aan voor de webserver
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow SSH and HTTP"

  # Allow SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP
  ingress {
    description = "PHP webserver"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Maak de security group aan voor de database
resource "aws_security_group" "db" {
  name = "db-sg"

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }
}

/*
===========================================================
S3 bucket & database
===========================================================
- Maak een S3 bucket aan
- Maak een Database aan
*/

# Maak de S3 bucket
resource "aws_s3_bucket" "uploads" {
  bucket = "terraform-vicwin-uploads" # Naam van de bucket
  acl    = "private"                  # Bucket zal private zijn
  versioning {
    enabled = true
  }
}
# Maak de database aan
resource "aws_db_instance" "mysql" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  name                   = "files"
  username               = "admin"
  password               = "r0998157!"
  skip_final_snapshot    = true
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.db.id]
}


/*
===========================================================
Roles en permissie
===========================================================
- Maak een nieuwe role aan voor de API en de APP
*/

resource "aws_iam_role" "api_role" {
  name = "api-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "api_s3_policy" {
  role = aws_iam_role.api_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:GetObject"
      ]
      Resource = "${aws_s3_bucket.uploads.arn}/*"
    }]
  })
}

resource "aws_iam_instance_profile" "api_profile" {
  name = "api-instance-profile"
  role = aws_iam_role.api_role.name
}


/*
===========================================================
EC2 instance API & APP
===========================================================
- Maak de instance voor de API aan
- Maak de instance voor de APP aan
- Geef de juiste security group
- Geef user data voor het opzetten van PHP webserver
*/

# Maak insrance voor API aan
resource "aws_instance" "api" {
  ami                  = "ami-0905a3c97561e0b69" # Ubuntu Linux
  instance_type        = "t3.micro"
  key_name             = aws_key_pair.generated.key_name
  iam_instance_profile = aws_iam_instance_profile.api_profile.name

  security_groups = [aws_security_group.web_sg.name]
  provisioner "remote-exec" {
    inline = [
      "apt remove needrestart -y", # Zal popup over restart services disabelen
      "apt update -y",
      "apt upgrade -y",
      "apt install -y apache2",
      "systemctl status apache2.service"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu" # Ubuntu AMI
      private_key = tls_private_key.ssh_key.private_key_pem
      host        = self.public_ip
    }
  }
}

resource "aws_instance" "app" {
  ami           = "ami-0905a3c97561e0b69" # Ubuntu Linux 
  instance_type = "t3.micro"
  key_name      = aws_key_pair.generated.key_name # Script om php te installeren

  security_groups = [aws_security_group.web_sg.name] # Security group die je hebt aangemaakt

  user_data = file("${path.module}/userdata.sh")
}




