
terraform {
  required_version = ">= 1.0"

  required_providers {
    podman = {
      source  = "blechschmidt/podman"
      version = "~> 0.5.3"
    }
  }
}

variable "runtime_dir" {
  description = "Value of XDG_RUNTIME_DIR for the current Ubuntu user"
  type        = string
}

provider "podman" {
  host = "unix://${var.runtime_dir}/podman/podman.sock"
}

# 1. Build the custom Linux SSH image.
resource "podman_image" "linux_server" {
  name = "localhost/linux-ssh-server:1.0"

  build {
    context    = path.module
    dockerfile = "Containerfile"
  }

  triggers = {
    containerfile_hash = filesha256("${path.module}/Containerfile")
    ssh_key_hash       = filesha256("${path.module}/authorized_keys")
  }
}

# 2. Create a shared bridge network.
resource "podman_network" "server_net" {
  name   = "server-net"
  driver = "bridge"
}

# 3. Create Linux server 1.
resource "podman_container" "server1" {
  name  = "server1"
  image = podman_image.linux_server.image_id

  hostname = "server1"
  restart  = "unless-stopped"

  networks_advanced {
    name    = podman_network.server_net.name
    aliases = ["server1"]
  }

  ports {
    internal = 22
    external = 2221
    ip       = "127.0.0.1"
  }
}

# 4. Create Linux server 2.
resource "podman_container" "server2" {
  name  = "server2"
  image = podman_image.linux_server.image_id

  hostname = "server2"
  restart  = "unless-stopped"

  networks_advanced {
    name    = podman_network.server_net.name
    aliases = ["server2"]
  }

  ports {
    internal = 22
    external = 2222
    ip       = "127.0.0.1"
  }
}

# 5. Output the information required to connect.
output "container_ids" {
  description = "IDs of the two Linux containers"
  value = {
    server1 = podman_container.server1.id
    server2 = podman_container.server2.id
  }
}

output "ssh_commands" {
  description = "Commands to connect to each server from this Ubuntu VM"
  value = {
    server1 = "ssh -i ~/.ssh/podman_task_key -p 2221 serveradmin@127.0.0.1"
    server2 = "ssh -i ~/.ssh/podman_task_key -p 2222 serveradmin@127.0.0.1"
  }
}

output "network_name" {
  description = "Shared Podman network"
  value       = podman_network.server_net.name
}

output "ssh_ports" {
  description = "Host ports forwarded to container port 22"
  value = {
    server1 = 2221
    server2 = 2222
  }
}
