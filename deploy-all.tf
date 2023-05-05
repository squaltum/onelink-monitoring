provider "aws" {
  region = "ap-southeast-1"
}

# Create a security group for Thanos instances
resource "aws_security_group" "thanos_sg" {
  name_prefix = "thanos_sg"

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "thanos-sg"
    Platform = "Monitoring"
  }
}

# Create an S3 bucket
resource "aws_s3_bucket" "thanos_bucket" {
  bucket = "central-thanos-data"
  acl    = "private"

  tags = {
    Name = "Thanos Bucket"
    Platform = "Monitoring"
  }
}

# Output the name of the S3 bucket
output "s3_bucket_name" {
  value = aws_s3_bucket.thanos_bucket.id
}

# Create an EC2 instance for the exporter
resource "aws_instance" "exporter" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI
  instance_type = "t3.medium"
  key_name      = "my-key-pair"

  associate_public_ip_address = true

  tags = {
    Name = "exporter"
    Software = "Exporter"
    Platform = "Monitoring"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo amazon-linux-extras install -y epel
              sudo yum install -y docker
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo docker run -d \
                --name exporter \
                -p 9100:9100 \
                prom/node-exporter

              EOF

  # Attach the security group to the instance
  vpc_security_group_ids = [aws_security_group.thanos_sg.id]
}

# Create an EC2 instance for the Thanos sidecar
resource "aws_instance" "thanos_sidecar" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI
  instance_type = "t3.medium"
  key_name      = "my-key-pair"

  associate_public_ip_address = true

  tags = {
    Name = "thanos-sidecar"
    Software = "Thanos"
    Component = "Sidecar"
    Platform = "Monitoring"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo amazon-linux-extras install -y epel
              sudo yum install -y docker
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo docker run -d \
                --name prometheus \
                -p 9090:9090 \
                prom/prometheus
              sudo docker run -d \
                --name thanos-sidecar \
                -p 10902:10902 \
                quay.io/thanos/thanos:v0.23.0 \
                --objstore.config-file=/etc/thanos/bucket.yml \
                --objstore.s3.endpoint=<YOUR_S3_ENDPOINT> \
                --objstore.s3.bucket=<YOUR_S3_BUCKET_NAME> \
                --objstore.s3.access-key=<YOUR_S3_ACCESS_KEY> \
                --objstore.s3.secret-key=<YOUR_S3_SECRET_KEY> \
                --query.replica-label=replica \
                --tsdb.path=/prometheus \
                --prometheus.url=http://localhost:9090 \
                --log.level=debug \
                --sidecar.listen-address=:10901
              EOF

  # Attach the security group to the instance
  vpc_security_group_ids = [aws_security_group.thanos_sg.id]
}

# Create an EC2 instance for the Thanos store gateway
resource "aws_instance" "thanos_store_gateway" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI
  instance_type = "a1.xlarge"
  key_name      = "my-key-pair"

  tags = {
    Name = "thanos-store-gateway"
    Software = "Thanos"
    Component = "Store"
    Platform = "Monitoring"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo amazon-linux-extras install -y epel
              sudo yum install -y docker
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo docker run -d \
                --name thanos-store-gateway \
                -p 10901:10901 \
                quay.io/thanos/thanos:v0.23.0 \
                store \
                --objstore.config-file=/etc/thanos/bucket.yml \
                --objstore.s3.endpoint=<YOUR_S3_ENDPOINT> \
                --objstore.s3.bucket=<YOUR_S3_BUCKET_NAME> \
                --objstore.s3.access-key=<YOUR_S3_ACCESS_KEY> \
                --objstore.s3.secret-key=<YOUR_S3_SECRET_KEY> \
                --grpc-address=:10901 \
                --http-address=:10902 \
                --log.level=debug
              EOF

  # Attach the security group to the instance
  vpc_security_group_ids = [aws_security_group.thanos_sg.id]
}

# Create two EC2 instances for the Thanos query
resource "aws_instance" "thanos_query" {
  count = 2

  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI
  instance_type = "t3.medium"
  key_name      = "my-key-pair"

  tags = {
    Name = "thanos-query-${count.index}"
    Software = "Thanos"
    Component = "Query"
    Platform = "Monitoring"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo amazon-linux-extras install -y epel
              sudo yum install -y docker
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo docker run -d \
                --name thanos-query \
                -p 10903:10903 \
                quay.io/thanos/thanos:v0.23.0 \
                query \
                --objstore.config-file=/etc/thanos/bucket.yml \
                --objstore.s3.endpoint=<YOUR_S3_ENDPOINT> \
                --objstore.s3.bucket=<YOUR_S3_BUCKET_NAME> \
                --objstore.s3.access-key=<YOUR_S3_ACCESS_KEY> \
                --objstore.s3.secret-key=<YOUR_S3_SECRET_KEY> \
                --grpc-address=:10903 \
                --http-address=:10904 \
                --query.replica-label
              EOF

  # Attach the security group to the instance
  vpc_security_group_ids = [aws_security_group.thanos_sg.id]
}

# Create an EC2 instance for Thanos Compact
resource "aws_instance" "thanos_compact" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI
  instance_type = "t3.medium"
  key_name      = "my-key-pair"

  tags = {
    Name = "thanos-compact"
    Software = "Thanos"
    Component = "Query"
    Platform = "Monitoring"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo amazon-linux-extras install -y epel
              sudo rpm --import https://raw.githubusercontent.com/thanos-io/thanos/main/KEYS
              sudo tee /etc/yum.repos.d/thanos.repo <<EOF
              [thanos]
              name=thanos
              baseurl=https://thanos-io.github.io/thanos-rpm/rpm
              repo_gpgcheck=1
              gpgcheck=1
              enabled=1
              gpgkey=https://raw.githubusercontent.com/thanos-io/thanos/main/KEYS
              EOF
              sudo yum install -y thanos-0.23.0-1.x86_64.rpm
              sudo mkdir /etc/thanos
              sudo touch /etc/thanos/compact.yaml
              sudo tee /etc/thanos/compact.yaml <<EOF
              objstore:
                type: s3
                config:
                  bucket: <YOUR_S3_BUCKET_NAME>
                  endpoint: <YOUR_S3_ENDPOINT>
                  access_key: <YOUR_S3_ACCESS_KEY>
                  secret_key: <YOUR_S3_SECRET_KEY>
                  insecure: true

              http:
                addr: "0.0.0.0:10902"

              EOF
              sudo systemctl enable thanos-compact
              sudo systemctl start thanos-compact
              EOF

  # Attach the security group to the instance
  vpc_security_group_ids = [aws_security_group.thanos_sg.id]
}

# Create an EC2 instance for the Grafana server
resource "aws_instance" "grafana" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI
  instance_type = "t3.medium"
  key_name      = "my-key-pair"

  associate_public_ip_address = true

  tags = {
    Name = "grafana"
    Software = "Grafana"
    Platform = "Monitoring"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo amazon-linux-extras install -y epel
              sudo rpm --import https://packages.grafana.com/gpg.key
              sudo tee /etc/yum.repos.d/grafana.repo <<EOF
              [grafana]
              name=grafana
              baseurl=https://packages.grafana.com/oss/rpm
              repo_gpgcheck=1
              enabled=1
              gpgcheck=1
              gpgkey=https://packages.grafana.com/gpg.key
              sslverify=1
              sslcacert=/etc/pki/tls/certs/ca-bundle.crt

              EOF
              sudo yum install -y grafana-9.0.3-1.x86_64.rpm

              EOF

  # Attach the security group to the instance
  vpc_security_group_ids = [aws_security_group.thanos_sg.id]
}

# Output the public IP address of the Grafana instance
output "grafana_public_ip" {
  value = aws_instance.grafana.public_ip
}

# Output the public IP address of the Prometheus instance
output "thanos_sidecar_public_ip" {
  value = aws_instance.thanos_sidecar.public_ip
}

# Create an EC2 instance for Rundeck Automation Platform
resource "aws_instance" "rundeck" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI
  instance_type = "t3.medium"
  key_name      = "my-key-pair"

  associate_public_ip_address = true

  tags = {
    Name = "Rundeck"
    Software = "Rundeck"
    Platform = "Automation"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo amazon-linux-extras install -y epel
              sudo yum install -y docker
              sudo systemctl start docker
              sudo systemctl enable docker

              EOF

  # Attach the security group to the instance
  vpc_security_group_ids = [aws_security_group.thanos_sg.id]
}

# Output the public IP address of the Rundeck instance
output "rundeck_public_ip" {
  value = aws_instance.rundeck.public_ip
}

