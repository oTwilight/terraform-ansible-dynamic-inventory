locals {
  instance_configs = {
    # "amazon_linux" = {
    #   ami           = data.aws_ami.amazon_linux.id
    #   instance_type = "t2.micro"
    #   count         = 1
    # }
    "ubuntu" = {
      ami           = data.aws_ami.ubuntu.id
      instance_type = "t2.micro"
      count         = 1
    }
  }
}