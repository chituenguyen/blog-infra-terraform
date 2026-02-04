output "records" {
  description = "Created DNS records"
  value = {
    for name, record in cloudflare_record.this : name => {
      id       = record.id
      hostname = record.hostname
      type     = record.type
      content  = record.content
      proxied  = record.proxied
    }
  }
}
