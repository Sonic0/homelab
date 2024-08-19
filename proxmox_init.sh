#!/usr/bin/env bash

# DESCRIPTION
#    This script perform the creation/update/delete of Wordpress infrastructure for Siti-Scuole Project in AWS Env.
#    Documentation at https://docs.google.com/document/.....
#    See usage() function for more information.
#================================================================
#  DEBUG OPTION
#    set -n  # Uncomment to check your syntax, without execution.
#    set -x  # Uncomment to debug this shell script
#    set -euo pipefail # Uncomment to "unofficial bash strict mode"
#================================================================

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
ANSIBLE_PLAYBOOKS_DIR="${SCRIPT_DIR}/proxmox_init"
ANSIBLE_INVENTORY_FILE="${ANSIBLE_PLAYBOOKS_DIR}/inventories/nmap.yml"


# It updates the value of a parameter in an .env file.
# If the parameter does not exist in the file, it will be added to the end of the file. \
# inputs: ${1} the name of the parameter
#         ${2} the new value for the parameter
#         ${3} the path to the .env file
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

modify_ansible_nmap_inventory "address" "192.168.1.0\/24" "${ANSIBLE_INVENTORY_FILE}"

ansible-playbook "./${ANSIBLE_PLAYBOOKS_DIR}/init.yml" -i "${ANSIBLE_INVENTORY_FILE}" -t "${TAGS:-all}" \
    -e "inventory_nmap_address=${ANSIBLE_INVENTORY_NMAP_ADDRESS},proxmox_init_user=${PROXMOX_INIT_USER},proxmox_init_user_pwd=${PROXMOX_INIT_USER_PWD}"