PrimaryDatabaseName = "primary"
SecondaryDatabaseName = "secoundry"
CronSchedule = "0 0 * * *"
VpcNetwork = "primary-standby-vpc"
VpcFirwall = "primary-standby-vpc-firewall"
CloudStorageBucket = "backup-bucket-2633"
RetentionPeriod = 15
MachineType = "n1-standard-1"
CPUUsageThreshold = 90
DiskUsageThreshold = 85
Zone = "us-central1-a"
MachinImage = "debian-cloud/debian-11"
Location="US-CENTRAL1"

PrimaryDatabaseName rename to PrimaryComputeEngine
SecondaryDatabaseName rename to SecondaryComputeEngine

in main.tf give primary db name as primary_db
for replication db name as standby_db

-- Test Primarydb pgbench replication to standby_db (add a simple table in prmarydb and see it in standbydb)
-- cron schedule, change to 1 min, it should add to cloud storage