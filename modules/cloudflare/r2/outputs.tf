output "buckets" {
  description = "Created R2 buckets"
  value = {
    for name, bucket in cloudflare_r2_bucket.this : name => {
      name     = bucket.name
      location = bucket.location
      url      = "https://${var.account_id}.r2.cloudflarestorage.com/${bucket.name}"
    }
  }
}
