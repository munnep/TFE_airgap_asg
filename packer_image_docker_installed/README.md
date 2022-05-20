# AMI image used for the TFE installation

We don't want to download and install software with the airgap installation instance from the internet. For this we create an image that has docker and the AWS cli software pre-installed. We build this image using packer. 

- go to directory packer_image_docker_installed
```
cd packer_image_docker_installed
```
- Alter the variable `region` in the file `ubuntudocker.pkr.hcl` to the region where you intend to place your TFE instance
```
variable "region" {
  type    = string
  default = "eu-north-1"
}
```
- initialize packer
```
packer init .
```
- build the image
```
packer build .
```
- Check in AWS console you have the image
![](media/20220510091219.png)  