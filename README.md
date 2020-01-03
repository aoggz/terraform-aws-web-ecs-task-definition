# terraform-aws-web-fargate-task-definition

Terraform module for a ECR repository and ECS task definition using the Fargate launch type.

It will create the following:

- ECR Repository
- ECS Task Definition
  - `web` container using the definition you specify
  - [`nginx_reverse_proxy`](https://github.com/aoggz/nginx-reverse-proxy) container listening at port 443
    - Forwards request to port 127.0.0.1:80
  - [`xray`](https://hub.docker.com/r/amazon/aws-xray-daemon) container listening at port 2000
- IAM roles & policies
- Security groups
- CloudWatch log group

## Usage

```hcl
module "cool-module-name-here" {
  source  = "aoggz/web-fargate-task/aws"
  version = "2.0.0"

  resource_prefix                        = local.resource_prefix
  log_retention_in_days                  = 30
  app_domain                             = var.app_domain              # must be a subdomain of the acm_certificate_domain
  reverse_proxy_cpu                      = var.reverse_proxy_cpu       # Number of CPU Units for reverse_proxy container
  reverse_proxy_memory                   = var.reverse_proxy_memory    # MB of RAM for reverse_proxy container
  reverse_proxy_version                  = "1.0.0"                     # Docker image tag of nginx_reverse_proxy container
  reverse_proxy_cert_state               = "PA"
  reverse_proxy_cert_locality            = "Pittsburgh"
  reverse_proxy_cert_organization        = "Awesome"
  reverse_proxy_cert_organizational_unit = "Sauce"
  reverse_proxy_cert_email_address       = "awesome@sau.ce"
  xray_cpu                               = var.xray_cpu                # Number of CPU Units for xray container
  xray_memory                            = var.xray_memory             # MB of RAM for xray container
  web_cpu                                = var.web_cpu                 # Number of CPU Units for web container
  web_memory                             = var.web_memory              # MB of RAM for web container
  web_image                              = var.web_image               # Name of Docker image to use for web container
  web_version                            = var.web_version             # Version of Docker image to use for web container
  web_environment_variables = [
    {
      name  = "ASPNETCORE_ENVIRONMENT",
      value = var.aspnetcore_environment,
    },
  ]
}
```

https://www.terraform.io/docs/modules/sources.html
