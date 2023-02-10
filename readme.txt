
This code is written in the Terraform language and creates infrastructure as code (IaC) resources in Google Cloud Platform (GCP). It creates a Virtual Private Cloud (VPC) network, a firewall to allow incoming traffic, a cloud storage bucket to store backups, and two compute instances (primary and standby databases).

The google_compute_network resource creates a VPC network with the name specified by the var.VpcNetwork variable, and sets the auto_create_subnetworks property to true.

The google_compute_firewall resource creates a firewall with the name specified by the var.VpcFirewall variable, associated with the VPC network created earlier, and allows all protocols with source ranges set to 0.0.0.0/0 (public IP addresses).

The google_storage_bucket resource creates a cloud storage bucket with the name specified by the var.CloudStorageBucket variable and the location specified by the var.Location variable. It sets a lifecycle rule to delete objects after a specified number of days, which is specified by the var.RetentionPeriod variable.

The google_compute_instance resources create two compute instances for primary and standby databases. The instances have the names specified by the var.PrimaryDatabaseName and var.SecondaryDatabaseName variables, respectively. The machine type, zone, and machine image are specified by the var.MachineType, var.Zone, and var.MachineImage variables, respectively. The instances are attached to the VPC network created earlier.

The instances have metadata specified in the startup-script field that installs and configures PostgreSQL and pgbench. The secondary database instance is also configured for replication with the primary database. Additionally, a daily backup is scheduled using cron with the cron schedule specified by the var.CronSchedule variable.

This code can be used to create an environment for running a highly available PostgreSQL database setup on GCP.

terraform.tfvars 