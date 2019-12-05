provider "google" {
  credentials = "${file("cred.json")}"
  project = "${var.gcpProject}"
  region = "${var.region}"
}



# resource "google_project_service" "project" {
#   project = "${var.gcpProject}"
#   service = "iam.googleapis.com"

#   disable_dependent_services = true
# }
# resource "google_project_iam_binding" "project" {
#   project = "${var.gcpProject}"
#   role    = "roles/editor"

#   members = [
#      "serviceAccount:harshitha@reference-point-260720.iam.gserviceaccount.com",
#   ]
# }

# resource "google_project_iam_binding" "project1" {
#   project = "${var.gcpProject}"
#   role    = "roles/storage.objectViewer"
 
#   members = [
#       "serviceAccount:harshitha@reference-point-260720.iam.gserviceaccount.com",
#   ]
# }

# resource "google_project_iam_binding" "project3" {
#   project = "${var.gcpProject}"
#   role    = "roles/compute.instanceAdmin"
 
#   members = [
#      "serviceAccount:harshitha@reference-point-260720.iam.gserviceaccount.com",
#   ]
# }
resource "google_project_service" "projectservice" {
  project = "${var.gcpProject}"
  service = "bigtableadmin.googleapis.com"

  disable_dependent_services = true
}

resource "google_bigtable_instance" "production-instance" {
  name = "tf-instance"

  cluster {
    cluster_id   = "tf-instance-cluster"
    zone         = "us-central1-b"
    num_nodes    = 3
    storage_type = "HDD"
  }
   depends_on = ["google_project_service.projectservice"]
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

resource "google_project_service" "project_sql" {
 project = "${var.gcpProject}"
  service = "sqladmin.googleapis.com"

  disable_dependent_services = true
}


resource "google_pubsub_subscription" "gcp_sub" {
  name  = "gcp-subscription"
  project = "${var.gcpProject}"
  topic = "${google_pubsub_topic.topic.name}"

  labels = {
    foo = "bar"
  }

  # 20 minutes
  message_retention_duration = "1200s"
  retain_acked_messages      = true

  ack_deadline_seconds = 20

  expiration_policy {
    ttl = "300000.5s"
  }
}

resource "google_pubsub_topic" "topic" {
  name       = "gcp-topic"
  project    = "${var.gcpProject}"

}


resource "google_cloudfunctions_function" "function" {
  name                  = "gcp_cloud_function"
  project               = "${var.gcpProject}"
  runtime               = "python37"
  available_memory_mb   = 128
  source_archive_bucket = "${google_storage_bucket.bucket-gcp-fall2019.name}"
  source_archive_object = "${google_storage_bucket_object.archive.name}"
  timeout               = 61
  entry_point           = "foos"
  event_trigger {
    event_type = "google.pubsub.topic.publish"
  //  event_type = "providers/cloud.storage/eventTypes/object.change"
    resource   = "${google_storage_bucket.bucket-gcp-fall2019.name}"
    failure_policy {
      retry = true
    }
  }
}

resource "google_storage_bucket" "bucket-gcp-fall2019" {
  project        = "${var.gcpProject}"
  name = "cloudfunction-storage-bucket-gcp"
}

resource "google_storage_bucket_object" "archive" {
  name   = "index.zip"
  bucket = "${google_storage_bucket.bucket-gcp-fall2019.name}"
  source = "try.zip"
}

# IAM entry for a single user to invoke the function
resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = "${var.gcpProject}"
  region         = "${google_cloudfunctions_function.function.region}"
  cloud_function = "${google_cloudfunctions_function.function.name}"

  role   = "roles/cloudfunctions.invoker"
  member = "serviceAccount:harshitha@reference-point-260720.iam.gserviceaccount.com"
}



# Random identifier for Database name
resource "random_pet" "database_name" {
  prefix = "csye6225-cloud-sql-instnace"
  separator = "-"
}

resource "google_sql_database_instance" "cloudsql-mysql-master" {
  project        = "${var.gcpProject}"
  name = "${random_pet.database_name.id}"
   database_version = "MYSQL_5_6"
  region = "us-central1"
  
 

  settings {
    # Second-generation instance tiers are based on the machine
    # type. See argument reference below.
    tier = "db-f1-micro"
  disk_type              = "PD_SSD"
  disk_size              = "10"
    ip_configuration {
            ipv4_enabled = true
            require_ssl = false
           
        }
   }
    depends_on = [google_project_service.project_sql]
}

resource "google_sql_user" "users" {
  name     = "root"
  instance = "${google_sql_database_instance.cloudsql-mysql-master.name}"
  password = "denim123"
}

resource "google_sql_database" "default" {
  name       = "csye6225_db"
  project    = "${var.gcpProject}"
  instance   = "${google_sql_database_instance.cloudsql-mysql-master.name}"
  charset    = "utf8"
  collation  = "utf8_general_ci"
  depends_on = [google_sql_database_instance.cloudsql-mysql-master]
}

# CREATE THE LOAD BALANCER


module "lb" {
  source                = "./http-load-balancer" 
  gcpProject            = var.gcpProject
  url_map               = google_compute_url_map.urlmap.self_link 
  enable_http           = var.enable_http
  
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

resource "google_compute_firewall" "firewall" {
  project = "${var.gcpProject}"
  name    = "lb-fw"
  network = "default"


  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]

  target_tags = ["private-app"]
  source_tags = ["private-app"]

  allow {
    protocol = "tcp"
    ports    = ["5000"]
  }
}


