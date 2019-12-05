resource "google_compute_global_address" "default" {
  project      = "${var.gcpProject}"
  name         = "public-address"
  ip_version   = "IPV4"
  address_type = "EXTERNAL"
}


resource "google_compute_target_http_proxy" "http" {
  count   = var.enable_http ? 1 : 0
  project    = "${var.gcpProject}"
  name    = "fwd-http-proxy"
  url_map = var.url_map
}

resource "google_compute_global_forwarding_rule" "http" {
  
  count      = var.enable_http ? 1 : 0
  project    = "${var.gcpProject}"
  name       = "ssl-http-rule"
  target     = google_compute_target_http_proxy.http[0].self_link
  ip_address = google_compute_global_address.default.address
  port_range = "80"

  depends_on = [google_compute_global_address.default]

  
}


