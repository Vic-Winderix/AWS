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