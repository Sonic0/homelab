resource "proxmox_vm_qemu" "k8s_worker" {
  for_each = local.k8s_worker

  name        = each.key
  target_node = each.value.target_node
  desc        = "Kubernetes worker"
  clone       = local.k8s_common.clone_base
  vmid        = each.value.vmid

  os_type = "cloud-init"
  qemu_os = "l26"
  agent   = 1
  scsihw  = "virtio-scsi-pci"
  onboot  = true

  ssh_forward_ip = each.value.ip
  ipconfig0      = "ip=${each.value.ip}/24,gw=${local.k8s_common.gw}"
  # ipconfig1      = "ip=${each.value.ip_data}/24"
  skip_ipv6 = true
  sshkeys   = var.ssh_pub_keys

  memory = each.value.memory

  cpu {
    cores   = each.value.cores
    sockets = 1
    type    = "host"
  }

  ciupgrade = true
  ci_wait   = 180

  tags = "k8s,worker,k3s,${local.vm_user},${local.cluster_name}"

  disks {
    ide {
      ide2 {
        cloudinit {
          storage = "local-zfs"
        }
      }
    }
    scsi {
      scsi0 {
        disk {
          storage    = each.value.storage
          size       = each.value.disk
          discard    = true
          emulatessd = true
          replicate  = true
        }
      }
    }
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
    tag    = 20
  }

  network {
    id     = 1
    model  = "virtio"
    bridge = "vmbr0"
    tag    = 50
  }


  vga {
    memory = 0
    type   = "serial0"
  }

  serial {
    id   = 0
    type = "socket"
  }

  lifecycle {
    ignore_changes = [
      clone,
      pool,
      ciuser,
      disks[0].scsi[0].scsi0[0].disk[0].storage,
    ]
  }

}
