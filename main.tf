# Define the provider
provider "aws" {
  region = "us-west-2"  # Change to your preferred region
  shared_credentials_files = ["~/OneDrive/Desktop/School/CS312/minecraft/credentials"]
}

# Import the existing SSH key
resource "aws_key_pair" "pre_existing_key" {
  key_name   = "pre-existing-key"
  public_key = file("${path.module}/minecraft.pub")
}

# Define the security group allowing SSH and Minecraft traffic
resource "aws_security_group" "minecraft_sg" {
  name_prefix = "minecraft-sg-"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 25565
    to_port     = 25565
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

# Define the EC2 instance
resource "aws_instance" "minecraft_server" {
  ami           = "ami-0eb9d67c52f5c80e5"  # Amazon Linux 2 AMI (HVM), SSD Volume Type
  instance_type = "t2.medium"  # Change to your preferred instance type

  key_name = aws_key_pair.pre_existing_key.key_name

  security_groups = [aws_security_group.minecraft_sg.name]

  tags = {
    Name = "MinecraftServer"
  }
}

# Output the instance's public IP
output "instance_ip" {
  value = aws_instance.minecraft_server.public_ip
}
