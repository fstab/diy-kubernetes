# ====================================================================
# Variables
# ====================================================================

variable "hcloud_token" {
  description = "Hetzner cloud API token"
}

variable "ssh_key_name" {
  description = "Name of the SSH key uploaded to Hetzner"
}

variable "node_count" {
  description = "Number of nodes"
  default = "2"
}

# ====================================================================
# Provider
# ====================================================================

provider "hcloud" {
  token = "${var.hcloud_token}"
}

# ====================================================================
# Infrastructure resources
# ====================================================================

resource "hcloud_server" "master" {
  name        = "kube-master"
  image       = "ubuntu-18.04"
  server_type = "cx21"
  datacenter  = "nbg1-dc3"
  ssh_keys    = ["${var.ssh_key_name}"]
  provisioner "remote-exec" {
    script = "install-python.sh"
  }
}

resource "hcloud_server" "node" {
  count       = "${var.node_count}"
  name        = "kube-node-${count.index + 1}"
  image       = "ubuntu-18.04"
  server_type = "cx21"
  datacenter  = "nbg1-dc3"
  ssh_keys    = ["${var.ssh_key_name}"]
  provisioner "remote-exec" {
    script = "install-python.sh"
  }
}

resource "hcloud_server" "loadbalancer" {
  name        = "load-balancer"
  image       = "ubuntu-18.04"
  server_type = "cx11"
  datacenter  = "nbg1-dc3"
  ssh_keys    = ["${var.ssh_key_name}"]
  provisioner "remote-exec" {
    script = "install-python.sh"
  }
}

# ====================================================================
# Ansible inventory
# ====================================================================

# Example inventory file:
#
# -------------------------------------------------------------------
# [kube-masters]
# kube-master vpn_ip=172.16.0.100 ansible_host=195.201.25.34 ansible_user=root
#
# [kube-nodes]
# kube-node-1 vpn_ip=172.16.0.1 ansible_host=195.201.25.33 ansible_user=root
# kube-node-2 vpn_ip=172.16.0.2 ansible_host=78.46.158.93 ansible_user=root
# 
# [kube-cluster:children]
# kube-masters
# kube-nodes
# -------------------------------------------------------------------

resource "null_resource" "ansible-provision" {
  depends_on = ["hcloud_server.master", "hcloud_server.node", "hcloud_server.loadbalancer"]

  triggers = {
    kube_master_id = "${hcloud_server.master.id}"
    kube_node_ids = "${join(", ", hcloud_server.node.*.id)}"
    load_balancer_id = "${hcloud_server.loadbalancer.id}"
  }

  provisioner "local-exec" {
    command = ": > inventory"
  }

  provisioner "local-exec" {
    command = "echo \"[kube-masters]\" >> inventory"
  }

  provisioner "local-exec" {
    command = "echo \"${format("%s vpn_ip=172.16.0.100 ansible_host=%s ansible_user=root", hcloud_server.master.name, hcloud_server.master.ipv4_address)}\" >> inventory"
  }

  provisioner "local-exec" {
    command = "echo \"\n[kube-nodes]\" >> inventory"
  }

  provisioner "local-exec" {
    command = "echo \"${replace(join("\n",formatlist("%s vpn_ip=%s ansible_host=%s ansible_user=root", hcloud_server.node.*.name, hcloud_server.node.*.name, hcloud_server.node.*.ipv4_address)), "vpn_ip=kube-node-", "vpn_ip=172.16.0.")}\" >> inventory"
  }

  provisioner "local-exec" {
    command = "echo \"\n[kube-cluster:children]\nkube-masters\nkube-nodes\" >> inventory"
  }

  provisioner "local-exec" {
    command = "echo \"\n[load-balancers]\" >> inventory"
  }

  provisioner "local-exec" {
    command = "echo \"${format("%s vpn_ip=172.16.0.101 ansible_host=%s ansible_user=root", hcloud_server.loadbalancer.name, hcloud_server.loadbalancer.ipv4_address)}\" >> inventory"
  }
}
