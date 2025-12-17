/*
===========================================================
Aanmaken webserver instance
===========================================================
- Maak een nieuwe security group aan die SSH en HTTP enabled
- Genereer een SSH key-pair met terraform
- Maak een AWS key-pair met de terraform keys
- Maak een EC2 instance aan met volgende parameters
  * Security group
  * SSH keys
*/

# Maak een security group aan
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
    description = "Python webserver"
    from_port   = 8000
    to_port     = 8000
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

# Maak de python webserver instance aan met AWS key-pair
resource "aws_instance" "web" {
  ami           = "ami-0d940f23d527c3ab1" # Amazon Linux 2
  instance_type = "t2.micro"
  key_name      = aws_key_pair.generated.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]
}
