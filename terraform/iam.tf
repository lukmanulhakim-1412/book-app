# IAM Role for EC2 to allow Systems Manager (SSM) access
resource "aws_iam_role" "ssm_role" {
  name = "book-app-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the AWS managed SSM policy to the role
resource "aws_iam_role_policy_attachment" "ssm_policy_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile to attach the role to the EC2 instance
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "book-app-ssm-profile"
  role = aws_iam_role.ssm_role.name
}
