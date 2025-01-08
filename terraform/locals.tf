locals {
  cluster_name          = "k3s"
  vm_super_user         = "root"
  vm_user               = "ubuntu"
  ansible_config        = "../ansible/ansible.cfg"
  ansible_playbook      = "../ansible/k8s_cluster_init.yml"
  ansible_inventory     = "../ansible/inventories/k8s_${local.cluster_name}"
  ansible_k3s_inventory = "../ansible/inventories/${local.cluster_name}_hosts"

  k8s_common = {
    gw         = "192.168.1.1"
    ci_disk    = "ide2"
    boot_disk  = "scsi0"
    storage    = "local-zfs"
    clone_k8s  = "${var.template_name}-k8s"
    clone_base = "${var.template_name}"
    # clone_base      = "${var.template_name}-base"
  }

  k8s_controlplane = {
    k8s-controlplane-01 = {
      target_node = "vmm01"
      storage     = "local-zfs"
      vmid        = 8001
      ip          = "192.168.1.201"
      cores       = 1
      memory      = 2048
      disk        = "20G"
    }
  }

  k8s_worker = {
    k8s-worker-01 = {
      target_node = "vmm01"
      storage     = "local-zfs"
      vmid        = 8011
      ip          = "192.168.1.211"
      ip_data     = "10.10.20.211"
      cores       = 2
      memory      = 12288
      disk        = "80G"
    },
    k8s-worker-02 = {
      target_node = "vmm01"
      storage     = "local-zfs"
      vmid        = 8012
      ip          = "192.168.1.212"
      ip_data     = "10.10.20.212"
      cores       = 2
      memory      = 12288
      disk        = "80G"
    }
  }

  ct_common = {
    gw        = "192.168.1.1"
    boot_disk = "scsi0"
    storage   = "local-zfs"
    templates = {
      ubuntu = "ubuntu-24.04-standard_24.04-1_amd64.tar.gz"
    }
  }
}
