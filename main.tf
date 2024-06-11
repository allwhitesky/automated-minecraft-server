# Define the provider
provider "aws" {
  region                    = "us-west-2"  # Change to your preferred region
  shared_credentials_files  = ["~/Desktop/automated-minecraft-server/credentials"]
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
  ami           = "ami-02e8e2a390064c712"  # Amazon Linux 2 AMI (HVM), SSD Volume Type
  instance_type = "t2.medium"  # Change to your preferred instance type

  key_name = aws_key_pair.pre_existing_key.key_name

  security_groups = [aws_security_group.minecraft_sg.name]

  tags = {
    Name = "MinecraftServer"
  }

  # Provisioner to install Docker and prepare instance for Minecraft server
  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y amazon-linux-extras",
      "sudo amazon-linux-extras enable docker",
      "sudo yum install -y docker",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "sudo usermod -aG docker ec2-user",
      "sudo docker pull itzg/minecraft-server",
      "sudo docker run -d --name minecraft_server -p 25565:25565 -e EULA=TRUE --restart always itzg/minecraft-server"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("${path.module}/minecraft")
      host        = self.public_ip
    }
  }
}

# Output the instance's public IP
output "instance_ip" {
  value = aws_instance.minecraft_server.public_ip
}
