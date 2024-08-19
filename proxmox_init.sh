#!/usr/bin/env bash

# DESCRIPTION
#    This script perform the setup of a Proxmox node.
#    ...
#================================================================
#  DEBUG OPTION
#    set -n  # Uncomment to check your syntax, without execution.
#    set -x  # Uncomment to debug this shell script
#    set -euo pipefail # Uncomment to "unofficial bash strict mode"
#================================================================

set -o nounset -o pipefail -o errexit

#== global variables ==#
# Shell Colors
RED='\e[1;31m'
GRE='\e[1;32m'
YEL='\e[1;33m'
NC='\e[0m'
# Constants
SCRIPT_NAME="$(basename "${0}")"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_FULLPATH="${SCRIPT_DIR}/${SCRIPT_NAME}"
DEFAULT_ENV_FILE_PATH="${SCRIPT_DIR}/.env.example"
ENV_FILE_PATH="${SCRIPT_DIR}/.env"
ANSIBLE_PLAYBOOKS_DIR="${SCRIPT_DIR}/ansible"
ANSIBLE_INVENTORY_FILE="${ANSIBLE_PLAYBOOKS_DIR}/inventories/nmap.yml"


modify_ansible_nmap_inventory() {
  local param_name=$1
  local new_value=$2
  local inventory_file=$3

  if grep -q "^${param_name}:" "${inventory_file}"; then
    sed -i "s/^${param_name}:.*/${param_name}: ${new_value}/" "${inventory_file}"
  else
    # If the parameter does not exist, add it to the file
    echo "${param_name}=${new_value}" >> "${inventory_file}"
  fi
}

spinner_loading() {
    echo -ne "\r"
    i=1
    sp="/ | \\ -"
    echo -n ' '
    while [ "$i" -le "$1" ]; do
        printf "\b${sp:i++%${#sp}:1}"
        sleep 1
    done
}

# Check if the command exists as some sort of executable.
command_exists() {
	type -t "$1" >/dev/null 2>&1
}

print_msg() {
  echo -e "${GRE}$1${NC}\n"
  return 0
}

print_warn() {
  echo -e "${YEL}$1${NC}\n"
  return 0
}

print_error() {
  echo -e "${RED}$1${NC}\n"
  return 0
}

########

if ! command_exists "nmap"; then
  print_error "Nmap doesn't seem to be installed. Please head on over to your OS package manager install it"
  exit 1
fi

if [ ! -f "${ENV_FILE_PATH}" ]; then
  cp "${DEFAULT_ENV_FILE_PATH}" "${ENV_FILE_PATH}"
  print_msg "ENV file created"
fi

# shellcheck source=./.env
set -o allexport
. "${ENV_FILE_PATH}"
set +o allexport

ANSIBLE_INVENTORY_VARS=$(ansible-inventory -i "${ANSIBLE_INVENTORY_FILE}" --list --export | jq '{all_vars: .all.vars, ungrouped_hosts: .ungrouped.hosts}')
HOSTNAME_PREFIX=$(jq -r '.all_vars.hostname_prefix' <<< "${ANSIBLE_INVENTORY_VARS}")
DOMAIN=$(jq -r '.all_vars.domain' <<< "${ANSIBLE_INVENTORY_VARS}")

SSH_KEY="${HOME}/.ssh/${HOSTNAME_PREFIX}.${DOMAIN}"  # Unique ssh key for every Proxmox node
if [ ! -f "${SSH_KEY}" ]; then
  print_warn "SSH key do not exist, creating..."
  ssh-keygen -t ecdsa -C "Proxmox server - ${HOSTNAME_PREFIX}XX.${DOMAIN}" -f "${SSH_KEY}"
  for host in $(echo "${ANSIBLE_INVENTORY_VARS}" | jq -r '.ungrouped_hosts[]'); do
    echo "${host}"
    ssh-copy-id -i "${SSH_KEY}" "${PROXMOX_INIT_USER}@${host}"
  done
fi

modify_ansible_nmap_inventory "address" "${ANSIBLE_INVENTORY_NMAP_ADDRESS}" "${ANSIBLE_INVENTORY_FILE}"

pushd "${ANSIBLE_PLAYBOOKS_DIR}" || { echo "Failed to change directory"; exit 1; }

# Step 1 - Init Proxmox
ansible-playbook "init.yml" -i "${ANSIBLE_INVENTORY_FILE}" -t "${TAGS:-all}" \
  --user "${PROXMOX_INIT_USER}" --private-key="${SSH_KEY}"

# Step 2 - User Token
ansible-playbook "pve_api_user.yml" -i "${ANSIBLE_INVENTORY_FILE}" \
  --user "${PROXMOX_INIT_USER}" --private-key="${SSH_KEY}" -e "terraform_user_password=${PROXMOX_TERRAFORM_USER_PASSWORD}"

# Step 3 - VM template
ansible-playbook "pve_template_build.yml" -i "${ANSIBLE_INVENTORY_FILE}" \
  --user "${PROXMOX_INIT_USER}" --private-key="${SSH_KEY}"

popd || { echo "Failed to return to the previous directory"; exit 1; }
