packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}


locals {
  username          = vault("/seclab/data/seclab/", "seclab_user")
  password          = vault("/seclab/data/seclab/", "seclab_windows_password")
  proxmox_api_id    = vault("/seclab/data/seclab/", "proxmox_api_id")
  proxmox_api_token = vault("/seclab/data/seclab/", "proxmox_api_token")
}

variable "hostname" {
  type    = string
  default = "seclab-win-dc"
}

variable "proxmox_node" {
  type    = string
  default = "proxmox"
}

source "proxmox-iso" "seclab-win-dc" {
  proxmox_url  = "https://${var.proxmox_node}:8006/api2/json"
  node         = "${var.proxmox_node}"
  username     = "${local.proxmox_api_id}"
  token        = "${local.proxmox_api_token}"
  iso_file     = "local:iso/Win-Server-2019.iso"
  iso_checksum = "sha256:549bca46c055157291be6c22a3aaaed8330e78ef4382c99ee82c896426a1cee1"


  additional_iso_files {
    device       = "ide3"
    iso_file     = "local:iso/Autounattend-win-dc.iso"
    iso_checksum = "sha256:b63108f09f4338c02f17631006f89d2189970365bfec95a27ae1039c4ce7a1b4"
    unmount      = true
  }

  additional_iso_files {
    device       = "sata0"
    iso_file     = "local:iso/virtio-win-0.1.271.iso"
    iso_checksum = "sha256:bbe6166ad86a490caefad438fef8aa494926cb0a1b37fa1212925cfd81656429"
    unmount      = true
  }

  insecure_skip_tls_verify = true
  communicator             = "ssh"
  ssh_username             = "${local.username}"
  ssh_password             = "${local.password}"
  ssh_timeout              = "30m"
  qemu_agent               = true
  // winrm_use_ssl           = true
  // guest_os_type           = "Windows2019_64"
  cores                = 2
  memory               = 4096
  vm_name              = "seclab-win-dc"
  template_description = "Base Seclab Windows Domain Controller"

  network_adapters {
    bridge = "vmbr2"
  }

  disks {
    type         = "virtio"
    disk_size    = "50G"
    storage_pool = "local-lvm"
  }
  scsi_controller = "virtio-scsi-pci"
}


build {
  sources = ["sources.proxmox-iso.seclab-win-dc"]
  provisioner "windows-shell" {
    inline = [
      "ipconfig",
    ]
  }

}
