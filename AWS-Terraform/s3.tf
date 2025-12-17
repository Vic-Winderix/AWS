/*
===========================================================
Aanmaken S3 bucket & database
===========================================================
- Maak een S3 bucket aan met een unieke naam
- 
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
resource "aws_dynamodb_table" "file_table" {
  name           = "file_table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "filename"
  attribute {
    name = "filename"
    type = "S"
  }
}

/*
===========================================================
Lambda configuratie
===========================================================
- Maak lambda IAM role
- Maak de policy voor S3 en DynamoDB
- Maak de lambda functie
*/

# Maak de lambda IAM role aan
resource "aws_iam_role" "lambda_iam_role" {
  name = "lambda_iam_role"           # Naam van de rol
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

# IAM Policy voor S3 en DynamoDB
resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_policy"
  role = aws_iam_role.lambda_iam_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.file_bucket.arn}",
          "${aws_s3_bucket.file_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DescribeTable"
        ]
        Resource = aws_dynamodb_table.file_table.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Maak de lambda functie
resource "aws_lambda_function" "upload_lambda" {
  function_name = "upload_file_lambda"
  runtime       = "python3.11"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"

  filename         = "lambda.zip"  # Zip bestand met lambda_function.py
  source_code_hash = filebase64sha256("lambda.zip")

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.file_bucket.bucket
      TABLE_NAME  = aws_dynamodb_table.file_table.name
    }
  }
}

/*
===========================================================
API Gateway
===========================================================
- Maak lambda IAM role
- Maak de policy voor S3 en DynamoDB
- Maak de lambda functie
*/

# Maak een gateway voor het uploaden van files
resource "aws_api_gateway_rest_api" "upload_api" {
  name        = "upload-api"
  description = "API voor uploaden bestanden naar Lambda"
}


resource "aws_api_gateway_resource" "upload_resource" {
  rest_api_id = aws_api_gateway_rest_api.upload_api.id
  parent_id   = aws_api_gateway_rest_api.upload_api.root_resource_id
  path_part   = "upload"
}

resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.upload_api.id
  resource_id   = aws_api_gateway_resource.upload_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.upload_api.id
  resource_id = aws_api_gateway_resource.upload_resource.id
  http_method = aws_api_gateway_method.post_method.http_method
  integration_http_method = "POST"
  type                     = "AWS_PROXY"
  uri                      = aws_lambda_function.upload_lambda.invoke_arn
}

# Toestemming voor API Gateway om Lambda te triggeren
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.upload_api.execution_arn}/*/*"
}
