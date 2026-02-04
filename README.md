# Blog Infrastructure (Terraform)

Terraform repo quản lý hạ tầng cho blog: GitHub repos, Cloudflare (R2, DNS), AWS (K3s cluster).

## Quản lý gì

| Provider   | Resources |
|-----------|-----------|
| GitHub    | Repos (blog-service-api, blog-service-ui, …), branch protection, collaborators |
| Cloudflare| R2 buckets (blog-media), DNS records (trỏ tới K3s) |
| AWS       | VPC, security group, EC2 + K3s (cloud-init), WireGuard VPN |

## Yêu cầu

- Terraform ≥ 1.x
- Credentials: GitHub token, Cloudflare API token + account/zone ID, AWS keys

## Cấu hình

1. Copy/sửa `terraform.tfvars` (ví dụ `github_owner`, `cloudflare_account_id`, `cloudflare_zone_id`).
2. Cung cấp biến nhạy cảm (không commit):
   - `TF_VAR_github_token`
   - `TF_VAR_cloudflare_api_token`
   - `TF_VAR_aws_access_key` / `TF_VAR_aws_secret_key`
   - `TF_VAR_ssh_public_key` (nội dung public key cho EC2/K3s)

   Có thể dùng `.envrc` + [direnv](https://direnv.net/) để load env khi vào thư mục.

## Chạy

```bash
make init    # lần đầu hoặc sau khi đổi provider/module
make plan    # xem thay đổi
make apply   # áp dụng
make destroy # hủy toàn bộ (cẩn thận)
```

Format & validate:

```bash
make fmt
make validate
```

## Cấu trúc

```
modules/
  github-repo/   # GitHub repositories + protection + collaborators
  cloudflare/
    r2/          # R2 buckets
    dns/         # DNS records (A, CNAME, …)
  aws/
    vpc/         # VPC + subnet
    security-group/
    k3s/         # EC2 + cloud-init (K3s, WireGuard)
```

Outputs: `terraform output` in ra thông tin K3s (IP, SSH, kubeconfig, VPN) và DNS records.
