# K3s Infrastructure Overview

Tài liệu mô tả kiến trúc hạ tầng K3s trên AWS:
- **Compute**: EC2 t3.small chạy K3s single-node
- **Network**: WireGuard VPN để truy cập SSH/K8s API, HTTP/HTTPS public qua NGINX Ingress
- **Ingress**: NGINX Ingress Controller (thay thế Traefik)
- **Monitoring**: Prometheus + Grafana + node_exporter (kube-prometheus-stack)
- **Storage**: AWS EFS cho persistent volumes
- **Database**: AWS RDS PostgreSQL managed
- **DNS**: Cloudflare DNS + Proxy

## Sơ đồ tổng quan

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                      INTERNET                                           │
└─────────────────────────────────────────┬───────────────────────────────────────────────┘
                                          │
                    ┌─────────────────────┴─────────────────────┐
                    │            Elastic IP (Public)            │
                    └─────────────────────┬─────────────────────┘
                                          │
        ┌─────────────────────────────────┼─────────────────────────────────┐
        │                                 │                                 │
        ▼                                 ▼                                 ▼
   ┌─────────┐                      ┌──────────┐                      ┌──────────┐
   │UDP:51820│                      │ TCP:80   │                      │ TCP:443  │
   │WireGuard│                      │  HTTP    │                      │  HTTPS   │
   │ (VPN)   │                      │ (public) │                      │ (public) │
   └────┬────┘                      └────┬─────┘                      └────┬─────┘
        │                                │                                 │
┌───────┴────────────────────────────────┴─────────────────────────────────┴───────────────┐
│                              AWS VPC (10.0.0.0/16)                                       │
│                              Region: ap-southeast-1                                      │
│                                                                                          │
│  ┌────────────────────────────────────────────────────────────────────────────────────┐  │
│  │                         Public Subnet (10.0.1.0/24) - AZ: a                        │  │
│  │  ┌──────────────────────────────────────────────────────────────────────────────┐  │  │
│  │  │                      EC2 Instance (t3.small)                                 │  │  │
│  │  │                      Name: blog-k3s-server                                   │  │  │
│  │  │                      OS: Ubuntu 22.04 LTS | Storage: 30GB gp3                │  │  │
│  │  │  ┌────────────────────────────────────────────────────────────────────────┐  │  │  │
│  │  │  │                    WireGuard VPN (wg0: 10.10.0.1/24)                   │  │  │  │
│  │  │  │  Peers: user1 (10.10.0.2) | user2 (10.10.0.3) | user3 (10.10.0.4)      │  │  │  │
│  │  │  └────────────────────────────────────────────────────────────────────────┘  │  │  │
│  │  │  ┌────────────────────────────────────────────────────────────────────────┐  │  │  │
│  │  │  │                         K3s Server (Single Node)                       │  │  │  │
│  │  │  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐       │  │  │  │
│  │  │  │  │ API Server  │ │ Controller  │ │  Scheduler  │ │etcd(SQLite) │       │  │  │  │
│  │  │  │  │   :6443     │ │   Manager   │ │             │ │             │       │  │  │  │
│  │  │  │  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘       │  │  │  │
│  │  │  │  ┌─────────────┐ ┌─────────────┐ ┌──────────────────────────────┐      │  │  │  │
│  │  │  │  │NGINX Ingress│ │   CoreDNS   │ │  Your Workloads              │      │  │  │  │
│  │  │  │  │  :80/:443   │ │             │ │  blog-api | blog-ui | ...    │      │  │  │  │
│  │  │  │  └─────────────┘ └─────────────┘ └──────────┬───────────────────┘      │  │  │  │
│  │  │  │  ┌───────────────────────────────────────────────────────────────┐     │  │  │  │
│  │  │  │  │              Monitoring Stack (kube-prometheus-stack)         │     │  │  │  │
│  │  │  │  │  ┌───────────┐  ┌───────────┐  ┌─────────────┐                │     │  │  │  │
│  │  │  │  │  │Prometheus │  │  Grafana  │  │node_exporter│                │     │  │  │  │
│  │  │  │  │  │   :9090   │  │   :3000   │  │   :9100     │                │     │  │  │  │
│  │  │  │  │  │  10Gi PV  │  │           │  │ (DaemonSet) │                │     │  │  │  │
│  │  │  │  │  └───────────┘  └───────────┘  └─────────────┘                │     │  │  │  │
│  │  │  │  └───────────────────────────────────────────────────────────────┘     │  │  │  │
│  │  │  └─────────────────────────────────────────────┼──────────────────────────┘  │  │  │
│  │  │                                                │                             │  │  │
│  │  │  ┌─────────────────────────┐                   │                             │  │  │
│  │  │  │    EFS Mount Target     │◄──────────────────┤ NFS :2049                   │  │  │
│  │  │  │    (Persistent Storage) │                   │                             │  │  │
│  │  │  └────────────┬────────────┘                   │                             │  │  │
│  │  └───────────────┼────────────────────────────────┼─────────────────────────────┘  │  │
│  └──────────────────┼────────────────────────────────┼────────────────────────────────┘  │
│                     │                                │                                   │
│  ┌──────────────────▼─────────────────┐   ┌─────────▼─────────────────────────────────┐  │
│  │           AWS EFS                  │   │     DB Subnets (10.0.100-101.0/24)        │  │
│  │  ┌──────────────────────────────┐  │   │  ┌─────────────────────────────────────┐  │  │
│  │  │  blog-efs                    │  │   │  │       AWS RDS PostgreSQL            │  │  │
│  │  │  fs-xxx.efs.aws.com          │  │   │  │  ┌───────────────────────────────┐  │  │  │
│  │  │                              │  │   │  │  │  blog-db (db.t3.micro)        │  │  │  │
│  │  │  • Encrypted at rest         │  │   │  │  │  PostgreSQL 15 | 20GB gp3     │  │  │  │
│  │  │  • Auto-scaling              │  │   │  │  │  Backup: 7 days retention     │  │  │  │
│  │  │  • ~$0.30/GB/month           │  │   │  │  │  Encrypted | ~$15-25/month    │  │  │  │
│  │  └──────────────────────────────┘  │   │  │  └───────────────────────────────┘  │  │  │
│  └────────────────────────────────────┘   │  └─────────────────────────────────────┘  │  │
│                                           └───────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────────────────────────────────────────┐  │
│  │                              Internet Gateway                                      │  │
│  └────────────────────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────────────────────┘
                                          │
┌─────────────────────────────────────────┴───────────────────────────────────────────────┐
│                                   VPN CLIENTS                                           │
│  ┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐          │
│  │       user1         │    │       user2         │    │       user3         │          │
│  │   IP: 10.10.0.2     │    │   IP: 10.10.0.3     │    │   IP: 10.10.0.4     │          │
│  └─────────────────────┘    └─────────────────────┘    └─────────────────────┘          │
│  Access: ssh ubuntu@10.10.0.1 | kubectl --server=https://10.10.0.1:6443                 │
│          psql -h blog-db.xxx.rds.amazonaws.com -U blog_admin -d blog                    │
└─────────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  PUBLIC: Browser → Cloudflare (DNS+Proxy) → Elastic IP → NGINX Ingress → Your Apps      │
│          grafana.domain.com → Grafana | api.domain.com → blog-api | blog.domain.com →   │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

## Ports & Security Groups

| Port / Service | Protocol | Source | Mục đích |
|----------------|----------|--------|----------|
| 22 (SSH) | TCP | VPN only (10.10.0.0/24) | SSH vào EC2 |
| 6443 (K8s API) | TCP | VPN only (10.10.0.0/24) | kubectl tới cluster |
| 80 / 443 | TCP | Public (0.0.0.0/0) | Traefik Ingress |
| 51820 (WireGuard) | UDP | Public (0.0.0.0/0) | VPN connection |
| 2049 (NFS) | TCP | K3s SG | EFS mount |
| 5432 (PostgreSQL) | TCP | K3s SG + VPN subnet | RDS access |

## Thành phần

### Compute (EC2)
- **Instance**: t3.small (2 vCPU, 2GB RAM)
- **OS**: Ubuntu 22.04 LTS
- **Storage**: 30GB gp3
- **WireGuard**: VPN server 10.10.0.1/24, 3 user slots
- **K3s**: Single-node cluster với NGINX Ingress, CoreDNS, Local Path Provisioner

### Ingress (NGINX)
- **Type**: NGINX Ingress Controller (Helm)
- **Mode**: hostPort (bind trực tiếp :80/:443)
- **Metrics**: Enabled, scraped by Prometheus
- **Routes**: grafana.domain, api.domain, blog.domain

### Monitoring (kube-prometheus-stack)
- **Prometheus**: TSDB với 10Gi storage, 7 ngày retention
- **Grafana**: Dashboard UI, truy cập qua Ingress (grafana.domain.com)
- **node_exporter**: DaemonSet thu thập metrics CPU/Memory/Disk/Network
- **kube-state-metrics**: Metrics về K8s objects (pods, deployments, etc.)
- **AlertManager**: Alert routing (2Gi storage)

### Storage (EFS)
- **Type**: General Purpose, Bursting throughput
- **Encryption**: At rest enabled
- **Mount**: NFS v4.1 từ K3s pods
- **Cost**: ~$0.30/GB/month

### Database (RDS)
- **Engine**: PostgreSQL 15
- **Instance**: db.t3.micro
- **Storage**: 20GB gp3, encrypted
- **Backup**: 7 days retention
- **Access**: K3s pods + VPN admins
- **Cost**: ~$15-25/month

### DNS (Cloudflare)
- **Records**: A records trỏ tới Elastic IP
- **Proxy**: Enabled (DDoS, CDN, SSL)
- **Subdomains**: @, blog, api, grafana

## Chi phí ước tính

| Resource | Monthly Cost |
|----------|-------------|
| EC2 t3.small | ~$17 |
| EFS (10GB) | ~$3 |
| RDS db.t3.micro | ~$15-25 |
| Elastic IP | Free (attached) |
| VPC/Subnets | Free |
| **Total** | **~$35-45** |

## Truy cập sau khi apply

### 1. Lấy VPN config
```bash
# SSH lần đầu qua public IP
ssh -i ~/.ssh/your-key ubuntu@<ELASTIC_IP>

# Lấy config cho user
cat /home/ubuntu/vpn-clients/user1.conf
```

### 2. Kết nối VPN (macOS/Linux)
```bash
# Lưu config
sudo mkdir -p /etc/wireguard
sudo nano /etc/wireguard/wg0.conf  # paste config

# Connect
sudo wg-quick up wg0
```

### 3. Truy cập cluster (qua VPN)
```bash
# SSH
ssh ubuntu@10.10.0.1

# Kubectl
scp ubuntu@10.10.0.1:/home/ubuntu/.kube/config ~/.kube/k3s-config
KUBECONFIG=~/.kube/k3s-config kubectl get nodes
```

### 4. Kết nối database (qua VPN)
```bash
psql -h blog-db.xxx.rds.amazonaws.com -U blog_admin -d blog
# Password: TF_VAR_db_password
```

### 5. Truy cập Grafana
```bash
# Public access (qua Cloudflare)
https://grafana.your-domain.com
# Login: admin / <grafana_admin_password từ tfvars>
```

### 6. Truy cập Prometheus (qua VPN + port-forward)
```bash
# Kết nối VPN trước, sau đó:
kubectl port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090 -n monitoring

# Mở browser: http://localhost:9090
```

### 7. Check monitoring pods
```bash
# NGINX Ingress
kubectl get pods -n ingress-nginx

# Monitoring stack
kubectl get pods -n monitoring
```

### 8. Mount EFS (trong K3s pod)
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: blog-efs
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteMany
  nfs:
    server: fs-xxx.efs.ap-southeast-1.amazonaws.com
    path: /
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: blog-efs-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
  volumeName: blog-efs
```

## Terraform Outputs

```bash
terraform output k3s_clusters    # Connection details, VPN info
terraform output efs             # EFS DNS name, mount command
terraform output rds             # Database endpoint, credentials
terraform output dns_records     # Cloudflare DNS records
```

## Files quan trọng

| File | Mô tả |
|------|-------|
| `main.tf` | Module calls, locals (k3s_clusters, dns_records) |
| `variables.tf` | Input variables (credentials, ssh_key, db_password, grafana_admin_password, domain) |
| `modules/aws/k3s/` | K3s + VPC + WireGuard + NGINX Ingress + Monitoring |
| `modules/aws/k3s/cloud-init.yaml.tftpl` | Cloud-init script cài đặt K3s, Helm, NGINX, kube-prometheus-stack |
| `modules/aws/efs/` | EFS file system |
| `modules/aws/rds/` | RDS PostgreSQL |
| `modules/cloudflare/dns/` | DNS records |

## New Variables (terraform.tfvars)

```hcl
# Thêm vào terraform.tfvars
grafana_admin_password = "your-secure-password"
domain                 = "your-domain.com"
```
