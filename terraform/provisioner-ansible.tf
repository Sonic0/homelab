resource "local_file" "ansible_inventory_file" {
  depends_on = [
    proxmox_vm_qemu.k8s_controlplane,
    proxmox_vm_qemu.k8s_worker
  ]

  content = templatefile("templates/ansible-inventory.tftpl", {
    k8s_controlplane = zipmap(
      values(proxmox_vm_qemu.k8s_controlplane)[*].name,
      values(proxmox_vm_qemu.k8s_controlplane)[*].ssh_forward_ip
    )
    k8s_workers = zipmap(
      values(proxmox_vm_qemu.k8s_worker)[*].name,
      values(proxmox_vm_qemu.k8s_worker)[*].ssh_forward_ip
    )
    cluster_name = local.cluster_name
    ansible_user = local.vm_super_user
  })
  filename = local.ansible_inventory
}

resource "local_file" "ansible_inventory_file_k3s_install" {
  depends_on = [
    proxmox_vm_qemu.k8s_controlplane,
    proxmox_vm_qemu.k8s_worker
  ]

  content = templatefile("templates/ansible-inventory-k3s-install.tftpl", {
    k8s_controlplane = zipmap(
      values(proxmox_vm_qemu.k8s_controlplane)[*].name,
      values(proxmox_vm_qemu.k8s_controlplane)[*].ssh_forward_ip
    )
    k8s_workers = zipmap(
      values(proxmox_vm_qemu.k8s_worker)[*].name,
      values(proxmox_vm_qemu.k8s_worker)[*].ssh_forward_ip
    )
    cluster_name = local.cluster_name
    ansible_user = local.vm_user
  })
  filename = local.ansible_k3s_inventory
}

resource "terraform_data" "ansible" {
  depends_on = [
    local_file.ansible_inventory_file
  ]

  triggers_replace = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command     = "ansible-playbook ${local.ansible_playbook} --tags 'init' --extra-vars \"k8s_cluster_name=${local.cluster_name} k3s_token=${var.k3s_token}\""
    working_dir = "../ansible"
    environment = {
      ANSIBLE_INVENTORY        = local.ansible_k3s_inventory
      ANSIBLE_CONFIG           = local.ansible_config
      ANSIBLE_PRIVATE_KEY_FILE = var.ssh_pub_keys
    }
  }

  provisioner "local-exec" {
    command     = "ansible-playbook k3s.orchestration.site --extra-vars @group_vars/k3s_${local.cluster_name}.yml"
    working_dir = "../ansible"
    environment = {
      ANSIBLE_INVENTORY        = local.ansible_k3s_inventory
      ANSIBLE_CONFIG           = local.ansible_config
      ANSIBLE_PRIVATE_KEY_FILE = var.ssh_pub_keys
    }
  }

  provisioner "local-exec" {
    # TODO remove token
    command     = "ansible-playbook ${local.ansible_playbook} --tags 'apps' --extra-vars @group_vars/k3s_${local.cluster_name}.yml --extra-vars \"vault_token=ftFMWQPJcudX0ieFHza3cbh7HNISN70BJQPB2v1x4g\""
    working_dir = "../ansible"
    environment = {
      ANSIBLE_INVENTORY        = local.ansible_k3s_inventory
      ANSIBLE_CONFIG           = local.ansible_config
      ANSIBLE_PRIVATE_KEY_FILE = var.ssh_pub_keys
    }
  }
}
