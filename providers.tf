provider "aws" {
  region = "ap-northeast-2"

  default_tags {
    tags = {
      Project     = "app"
      ManagedBy   = "terraform"
      Environment = "dev"
    }
  }
}
