resource "aws_cognito_user_pool" "main" {
  name                     = "main"
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = false
    require_symbols   = false
    require_uppercase = false
  }
}

resource "aws_cognito_user_pool_client" "main" {
  name = "main"

  user_pool_id = aws_cognito_user_pool.main.id
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "server-less-random"
  user_pool_id = aws_cognito_user_pool.main.id
}
