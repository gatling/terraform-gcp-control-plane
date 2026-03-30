locals {
  conf_file_name = "control-plane.conf"
  host_path      = "/etc/control-plane"
  mount_path     = "/app/conf"
  volume         = "-v ${local.host_path}/${local.conf_file_name}:${local.mount_path}/${local.conf_file_name}"
  git = {
    creds_enabled = length(var.git.credentials.token-secret-name) > 0
    ssh_enabled   = length(var.git.ssh.secret-name) > 0
  }
  ssh_host_path      = "/etc/control-plane/ssh"
  ssh_container_path = "/app/.ssh"
  ssh_volume         = local.git.ssh_enabled ? "-v ${local.ssh_host_path}:${local.ssh_container_path}" : ""
  cache_volumes      = join(" ", [for path in var.git.cache.paths : "-v ${path}:${path}"])
  environment_list = concat(
    ["-e CONTROL_PLANE_TOKEN=$CONTROL_PLANE_TOKEN"],
    local.git.creds_enabled ? ["-e GIT_TOKEN=$GIT_TOKEN"] : [],
    [for env in lookup(var.container, "environment", []) : "-e ${env}"]
  )
  environment    = join(" ", local.environment_list)
  port           = "-p ${var.server.port}:${var.server.port}"
  command        = join(" ", var.container.command)
  config_content = <<-EOF
    control-plane {
      token = $${?CONTROL_PLANE_TOKEN}
      description = "${var.description}"
      enterprise-cloud = ${jsonencode(var.enterprise-cloud)}
      locations = [%{for location in local.locations} ${jsonencode(location)}, %{endfor}]
      server = ${jsonencode(var.server)}
      %{if local.private-package != null}repository = ${jsonencode(local.private-package)}%{endif}
      %{if local.git.ssh_enabled || local.git.creds_enabled}
      builder {
        %{if local.git.ssh_enabled}
        git.global.credentials.ssh {
          key-file = "${local.ssh_container_path}/${var.git.ssh.file-name}"
        }
        %{endif}
        %{if local.git.creds_enabled}
        git.global.credentials.https {
          %{if length(var.git.credentials.username) > 0}username = "${var.git.credentials.username}"%{endif}
          password = $${?GIT_TOKEN}
        }
        %{endif}
      }
      %{endif}
      %{for key, value in var.extra-content}${key} = "${value}"%{endfor}
    }
  EOF
}

resource "google_compute_instance" "control_plane" {
  name             = var.name
  zone             = var.network.zone
  machine_type     = var.compute.machine-type
  min_cpu_platform = var.compute.min-cpu-platform

  boot_disk {
    initialize_params {
      image = var.compute.boot-disk-image
    }
  }

  network_interface {
    network    = var.network.network
    subnetwork = var.network.subnetwork
    dynamic "access_config" {
      for_each = var.network.enable-external-ip ? [1] : []
      content {}
    }
  }

  service_account {
    email  = google_service_account.service_account.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata_startup_script = <<-EOF
    #! /bin/bash

    set -e

    toolbox gcloud version
    CONTROL_PLANE_TOKEN=$(toolbox gcloud secrets versions access latest --secret=${var.token-secret-name} || echo "SECRET_FETCH_FAILED")
    %{if local.git.creds_enabled}
    GIT_TOKEN=$(toolbox gcloud secrets versions access latest --secret=${var.git.credentials.token-secret-name} || echo "GIT_TOKEN_FETCH_FAILED")
    %{endif}
    %{if local.git.ssh_enabled}
    mkdir -p ${local.ssh_host_path}
    toolbox gcloud secrets versions access latest --secret=${var.git.ssh.secret-name} > ${local.ssh_host_path}/${var.git.ssh.file-name}
    chmod 400 ${local.ssh_host_path}/${var.git.ssh.file-name}
    %{endif}
    %{for path in var.git.cache.paths}
    mkdir -p ${path}
    %{endfor}

    mkdir -p ${local.host_path}
    echo '${local.config_content}' | sudo tee ${local.host_path}/${local.conf_file_name}

    sudo docker run -d --name ${var.name} ${local.environment} ${local.volume} ${local.ssh_volume} ${local.cache_volumes} ${local.port} ${var.container.image} ${local.command}
  EOF

  shielded_instance_config {
    enable_secure_boot          = var.compute.shielded.enable-secure-boot
    enable_vtpm                 = var.compute.shielded.enable-vtpm
    enable_integrity_monitoring = var.compute.shielded.enable-integrity-monitoring
  }

  confidential_instance_config {
    enable_confidential_compute = var.compute.confidential.enable
    confidential_instance_type  = var.compute.confidential.instance-type
  }
}
