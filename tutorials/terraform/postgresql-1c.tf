# Infrastructure for Yandex Cloud Managed Service for PostgreSQL 1C cluster
#
# RU: https://cloud.yandex.ru/docs/managed-postgresql/tutorials/1c-postgresql
# EN: https://cloud.yandex.com/en-ru/docs/managed-postgresql/tutorials/1c-postgresql
#
# Set the user password for Managed Service for PostgreSQL 1C cluster


# Network
resource "yandex_vpc_network" "postgresql-1c-network" {
  name        = "postgresql-1c-network"
  description = "Network for Managed Service for PostgreSQL 1C cluster."
}

# Subnet in ru-central1-a availability zone
resource "yandex_vpc_subnet" "subnet-a" {
  name           = "postgresql-subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.postgresql-1c-network.id
  v4_cidr_blocks = ["10.1.0.0/16"]
}

# Security group for Managed Service for PostgreSQL 1C cluster
resource "yandex_vpc_default_security_group" "postgresql-security-group" {
  network_id = yandex_vpc_network.postgresql-1c-network.id

  # Allow connections to cluster from Internet
  ingress {
    protocol       = "TCP"
    description    = "Allow incoming SSL-connections with postgresql-client from Internet"
    port           = 6432
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow connections from cluster to Yandex Object Storage
  egress {
    protocol       = "ANY"
    description    = "Allow outgoing connections to any required resource"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Managed Service for PostgreSQL 1C cluster
resource "yandex_mdb_postgresql_cluster" "postgresql-1c" {
  name               = "postgresql-1c"
  environment        = "PRODUCTION"
  network_id         = yandex_vpc_network.postgresql-1c-network.id
  security_group_ids = [yandex_vpc_default_security_group.postgresql-security-group.id]

  config {
    version = "12-1c"
    resources {
      resource_preset_id = "s2.small"
      disk_type_id       = "network-ssd"
      disk_size          = "10" # GB
    }
  }

  database {
    name  = "postgresql-1c"
    owner = "user-1c" # Base owner name
  }

  user {
    name     = "user-1c" # Username
    password = ""        # Set user password
    permission {
      database_name = "postgresql-1c"
    }
  }

  host {
    zone             = "ru-central1-a"
    subnet_id        = yandex_vpc_subnet.subnet-a.id
    assign_public_ip = true # Required for connection from Internet
  }
}
