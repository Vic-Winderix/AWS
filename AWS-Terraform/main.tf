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

# Maak de S3 bucket
resource "aws_s3_bucket" "uploads" {
  bucket = "terraform-vicwin-uploads" # Naam van de bucket
  acl    = "private" # Bucket zal private zijn
}

# Maak de lambda S3 role aan
resource "aws_iam_role" "lambda_S3_role" { 
  name = "lambda_s3_role" # Naam van de rol
  assume_role_policy = jsonencode({ # Gebruik json code 
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole" # Geef toestemming om de role te mogen gebruiken
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com" # Alleen lambda van AWS kan deze role aannemen
      }
    }]
  })
}

# Koppel IAM policy aan de rol
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_S3_role.name # Naam moet dezelfde zijn als hierboven vernoemd
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" # Geef deze policy om logging mogelijk te maken
}

# S3 upload detectie
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.uploads.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.process_upload.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

# Geef toestemming aan S3 om lambda functie op te roepen
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_upload.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.uploads.arn
}