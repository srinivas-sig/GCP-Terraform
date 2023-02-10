// create vpc network
resource "google_compute_network" "vpc_network" {
  name                    = var.VpcNetwork
  auto_create_subnetworks = true
}


resource "google_compute_firewall" "vpc_firwall" {
  name    = var.VpcFirwall
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "all"
  }
  source_ranges = ["0.0.0.0/0"]
}



resource "google_storage_bucket" "cloudstorage" {
  name = var.CloudStorageBucket
  location      = var.Location

  
  lifecycle_rule {
    condition {
      age = var.RetentionPeriod
    }
    action {
      type = "Delete"
    }
  }
}
resource "google_compute_instance" "primary_db" {
  name         = var.PrimaryDatabaseName
  machine_type = var.MachineType
  zone         = var.Zone
  boot_disk {
    initialize_params {
      image = var.MachinImage
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
      // Include a public IP for the primary database instance
    }
  }

  metadata = {
    startup-script = <<EOF
      # install PostgreSQL

       # Install pgbench
      sudo apt update

      sudo apt -y install vim bash-completion wget

      wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

      echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" |sudo tee  /etc/apt/sources.list.d/pgdg.list

      sudo apt update

      sudo apt -y install postgresql-12 postgresql-client-12

      # initialize pgbench schema

      sudo su - postgres -c "createdb c"

      sudo su - postgres -c "pgbench -i -s 75 primary_db"
    EOF
  }
}

resource "google_compute_instance" "standby_db" {
  name         = var.SecondaryDatabaseName
  machine_type = var.MachineType
  zone         = var.Zone
  boot_disk {
    initialize_params {
      image = var.MachinImage
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
      // Include a public IP for the primary database instance
    }
  }

  metadata = {
    startup-script = <<EOF
       # Install pgbench
      sudo apt update

      sudo apt -y install vim bash-completion wget

      wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

      echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" |sudo tee  /etc/apt/sources.list.d/pgdg.list

      sudo apt update

      sudo apt -y install postgresql-12 postgresql-client-12

      # configure replication
      # (assuming primary_db is already set up and running)
      sudo su - postgres -c "createdb standby_db"
      sudo su - postgres -c "psql standby_db -c 'CREATE USER replication REPLICATION LOGIN CONNECTION LIMIT 10 ENCRYPTED PASSWORD ''password'';'"
      sudo su - postgres -c "pg_basebackup -h ${google_compute_instance.primary_db.network_interface.0.access_config.0.nat_ip} -D /var/lib/postgresql/data --format=tar --username=replication"
      sudo su - postgres -c "echo 'host replication replication 0.0.0.0/0 md5' >> /var/lib/postgresql/data/pg_hba.conf"
      sudo su - postgres -c "echo 'primary_conninfo = ''host=${google_compute_instance.primary_db.network_interface.0.access_config.0.nat_ip} port=5432 user=replication password=password sslmode=disable''' >> /var/lib/postgresql/data/recovery.conf"
      sudo systemctl restart postgresql

      # schedule daily backup
      echo "${var.CronSchedule} sudo su - postgres -c \"pg_dumpall -f /tmp/backup.sql\" && gsutil cp /tmp/backup.sql gs://${google_storage_bucket.cloudstorage.name}/$(date +\%F).sql" | crontab -
    EOF
  }
}

resource "google_monitoring_alert_policy" "cpu_usage_alert" {
  display_name = "High CPU Usage Alert"
  combiner     = "OR"
  conditions {
    display_name = "High CPU Usage Alert"
    condition_threshold {
      filter     = "resource.type = \"gce_instance\" AND metric.type = \"compute.googleapis.com/instance/cpu/usage_time\" AND metric.labels.instance_name = \"${var.PrimaryDatabaseName}\""
      duration   = "60s"
      comparison = "COMPARISON_GT"
      threshold_value = var.CPUUsageThreshold
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

}

resource "google_monitoring_alert_policy" "disk_usage_alert" {
  display_name = "High Disk Usage Alert"
  combiner     = "OR"
  conditions {
    display_name = "VM Instance - Disk usage"
    condition_threshold {
      filter     = "resource.type = \"gce_instance\" AND metric.type = \"compute.googleapis.com/guest/disk/bytes_used\" AND metric.labels.instance_name = \"${var.PrimaryDatabaseName}\""
      duration   = "60s"
      comparison = "COMPARISON_GT"
      threshold_value = var.DiskUsageThreshold
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

}