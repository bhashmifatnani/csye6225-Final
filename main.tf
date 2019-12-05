provider "google" {
  credentials = "${file("cred.json")}"
  project = "${var.gcpProject}"
  region = "${var.region}"
}






resource "google_compute_network" "VPC_GCP" {
    name = "${var.vpcname}-network-vpc"
    auto_create_subnetworks=false
    
  
}

resource "google_compute_subnetwork" "gcp-subnet11" {
    name = "gcp-subnet11"
    ip_cidr_range="${var.subnet_cidr1}"
    network="${var.vpcname}-vpc"
    depends_on = ["google_compute_network.VPC_GCP"]
    
    
  
}
resource "google_compute_subnetwork" "gcp-subnet12" {
    name = "gcp-subnet12"
    ip_cidr_range="${var.subnet_cidr2}"
    network="${var.vpcname}-vpc"
    depends_on = ["google_compute_network.VPC_GCP"]
   
    
  
}
resource "google_compute_subnetwork" "gcp-subnet13" {
    name = "gcp-subnet13"
    ip_cidr_range="${var.subnet_cidr3}"
    network="${var.vpcname}-vpc"
    depends_on = ["google_compute_network.VPC_GCP"]
   
     
}




resource "google_compute_route" "route-table" {
  name        = "route-table"
  dest_range  = "0.0.0.0/0"
  network     = google_compute_network.VPC_GCP.name
  next_hop_gateway = "default-internet-gateway"
  
}


#URL maps to map paths to backend

resource "google_compute_url_map" "urlmap" {
  project = "${var.gcpProject}"

  name        = "gcp-lb-url-map"
  description = "URL map for gcp-lb-url-map"

  default_service = google_compute_backend_service.api.self_link

}

#Backend service cofiguration for instance group

resource "google_compute_backend_service" "api" {
  project = "${var.gcpProject}"

  name        = "backend-servicess"
  health_checks = [google_compute_health_check.my-healthcheck.self_link]

  depends_on = [google_compute_instance_group_manager.my-instance-manager]
}

#Health check for backend configured

resource "google_compute_health_check" "my-healthcheck" {
  project = "${var.gcpProject}"
  name    = "my-compute-healthcheck"
  healthy_threshold   = 2
  unhealthy_threshold = 10 
  check_interval_sec = 5
  timeout_sec        = 5
  tcp_health_check {
    port = "80"
  }
}

#Create an instance template which will be launched 

resource "google_compute_instance_template" "my-template" {
  project      = "${var.gcpProject}"
  name         = "my-instance-template"
  instance_description = "description assigned to instances"
  machine_type         = "n1-standard-1"
  can_ip_forward       = false
  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  // Create a new boot disk from an image
  disk {
    source_image = "debian-cloud/debian-9"
    auto_delete  = true
    boot         = true
  }
  # We're tagging the instance with the tag specified in the firewall rule
  tags = ["private-app"]
  # Launch the instance in the subnetwork
  network_interface {
    subnetwork = google_compute_subnetwork.gcp-subnet11.name

    # This gives the instance a public IP address for internet connectivity. 
    access_config {
    }
  }
}



# Autoscalar resource
resource "google_compute_autoscaler" "scaling" {
  name   = "my-autoscaler"
  zone   = "us-central1-f"
  target = "${google_compute_instance_group_manager.my-instance-manager.name}"

  
  autoscaling_policy {
    max_replicas    = 2
    min_replicas    = 1
    cooldown_period = 60
    cpu_utilization {
      target = 0.6
   }
  }
}

#target pool
resource "google_compute_target_pool" "my-target-pool" {
  name = "my-target-pools"
}

#instance group manager to manage instances which is managed by google cloud
resource "google_compute_instance_group_manager" "my-instance-manager" {
  name = "my-instance-manager"

  base_instance_name = "base-instance"
  
  version {
    instance_template  = "${google_compute_instance_template.my-template.self_link}"
  }
  zone = "us-central1-f"

  target_pools = ["${google_compute_target_pool.my-target-pool.self_link}"]
  target_size  = 1
  named_port {
    name = "customhttp"
    port = 80
  }
  }


