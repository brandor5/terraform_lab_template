terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

provider "libvirt" {
  uri = "qemu+ssh://user@hypervisor.example.com/system"
}

data "template_file" "user_data" {
  template = file("${path.module}/cloud_init.cfg")
}

data "template_file" "network_config" {
  template = file("${path.module}/network_config.cfg")
}

resource "libvirt_cloudinit_disk" "test-commoninit" {
  name           = "test-commoninit.iso"
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
}

resource "libvirt_volume" "test_disk" {
  name             = "test_disk.qcow2"
  base_volume_name = "rhel-baseos-9.1-x86_64-kvm.qcow2"
  pool             = "default"
  size             = "21474836480"
}

resource "libvirt_domain" "test" {
  name   = "test"
  vcpu   = 2
  memory = "12288"

  cloudinit = libvirt_cloudinit_disk.test-commoninit.id

  autostart = true

  network_interface {
    bridge = "lab"
  }

  disk {
    volume_id = libvirt_volume.test_disk.id
  }

  cpu {
    mode = "host-passthrough"
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type = "vnc"
  }
}
