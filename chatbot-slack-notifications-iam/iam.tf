resource "random_id" "chatbot_id" {
  byte_length = 4
}

resource "aws_iam_role" "chatbot_role" {
  name = "ChatbotSlackRole-${random_id.chatbot_id.id}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "chatbot.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name      = "ChatbotSlackRole-${random_id.chatbot_id.id}"
    Owner     = "engineering-enablement"
    Terraform = "true"
  }
}
