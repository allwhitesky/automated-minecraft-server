# Minecraft Server Installation Guide


## Step 1: Install AWS CLI and Terraform
1. Open a shell on your local machine
2. Enter the following commands:
    ```bash
    sudo apt update
    ```
3. Install unzip if not already installed:
    ```bash
    sudo apt install unzip -y
    ```
4. Download AWS CLI installer:
    ```bash
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    ```
    Refer to documentation here <https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html>
5. Unzip AWS CLI installer:
    ```bash
    unzip awscliv2.zip
    ```
6. Run the install script:
    ```bash
    sudo ./aws/install
    ```
7. Verify AWS CLI installation:
    ```bash
    aws --version
    ```
8. Download Terraform binary:
    ```bash
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add - sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    ```
    Refer to documentation here <https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli>
9. Install Terraform:
    ```bash
    sudo apt install terraform
    ```
10. Verify Terraform installation:
    ```bash
    terraform --version
    ```

## Step 2: Create Credentials File
1. In your project directory create a new file:
    ```bash
    touch credentials
    ```
2. Open the file in your editor and paste in the AWS credentials. They should look something like this:
    ```bash
    aws_access_key_id=SKDJGHJKLSFDSDF
    aws_secret_access_key=Bsdfkjh....
    aws_session_token=IFHKJAGSF////////FKDJBFKD.....

## Step 3: Create Terraform script
1. In your project directory, create a new file:
    ```bash
    touch main.tf
    ```
2. Open the file and make these changes:
    ```hcl
    # Define the provider
    provider "aws" {
    region                    = "us-west-2"
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
    instance_type = "t2.medium"

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
        "docker pull itzg/minecraft-server",
        "docker run -d --name minecraft_server -p 25565:25565 -e EULA=TRUE --restart always itzg/minecraft-server"
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
    ```
3. After creating the main.tf file, we also need to make the outputs file:
    ```bash
    touch outputs.tf
    ```
4. Open the outputs.tf in your editor and add in the following:
    ```hcl
    output "instance_id" {
    description = "ID of the EC2 instance"
    value       = aws_instance.minecraft_server.id
    }

    output "instance_public_ip" {
    description = "Public IP address of the EC2 instance"
    value       = aws_instance.minecraft_server.public_ip
    }
    ```

5. When you have created the outputs file, type the following command in the terminal where your terraform files live:
    ```bash
    terraform init
    ```
6. Apply the terraform script:
    ```bash
    terraform apply
    ```
7. Now we should see the public IP address of the EC2 instace after the terraform script finishes and we can connect to the server.


## Step 4: Access the Minecraft Server
1. Open Minecraft on your local machine.
2. Click on "Multiplayer" and then "Add Server".
3. Enter the public IP address of your EC2 instance and click "Done".
4. Double-click on the server entry to connect to the Minecraft server.



## Conclusion
We have successfully created an EC2 instance, set the necessary inbound security rules to allow access on the port used for minecraft (25565), configured the EC2 instance for docker, configured a docker image for a minecraft server and dispatched the container, making the server accessible for us to use.