#!/bin/bash

set -x

REPO_DIR="$(cd "$(dirname "$0")"/.. && pwd)"
HOSTS_CMD="cd "${REPO_DIR}" && ANSIBLE_LOAD_CALLBACK_PLUGINS=1 ANSIBLE_STDOUT_CALLBACK=json ansible -m debug -a 'var=groups.all' localhost | jq -r '.plays[0].tasks[0].hosts.localhost.\"groups.all\" | .[]'"
RESOLVER_IP="10.11.12.1"
RESOLVER_PREFIX="10.11.12"

usage() {
  echo "Usage: $0 [-q] [-s HOST] [-f]" 1>&2
}

active_hosts() {
  for host in $(eval ${HOSTS_CMD}); do
    if ssh ${host} "ip a | grep -q 'inet ${RESOLVER_IP}\/24'" 2>/dev/null; then
      echo "${host} "
    fi
  done
}

do_query() {
  hosts=($(active_hosts))
  if [[ ${#hosts[@]} -gt 1 ]]; then
    echo "Warning: multiple hosts found listening on ${RESOLVER_IP}!"
  elif [[ ${#hosts[@]} -eq 0 ]]; then
    echo "Warning: no host is listening on ${RESOLVER_IP}!"
  fi
  for h in ${hosts[@]}; do
    echo "${h} is listening on ${RESOLVER_IP}"
  done
}

do_set() {
  if [[ "${FORCE}" == "" ]]; then
    for old in $(active_hosts); do
      old_if="$(ssh "${old}" "ip a | grep ${RESOLVER_PREFIX} | head -1 | awk -F' ' '{print \$NF}'" 2>/dev/null)"
      ssh "${old}" "ip addr del \"${RESOLVER_IP}/24\" dev \"${old_if}\"" 2>/dev/null
    done
  fi

  new="${1}"
  new_if="$(ssh "${new}" "ip a | grep ${RESOLVER_PREFIX} | head -1 | awk -F' ' '{print \$NF}'" 2>/dev/null)"
  ssh "${new}" "ip addr add \"${RESOLVER_IP}/24\" dev \"${new_if}\"" 2>/dev/null
}

while getopts ":qfs:" opt; do
  case "${opt}" in
    q)
      QUERY=1
      ;;
    s)
      SET=1
      HOST="${OPTARG}"
      ;;
    f)
      FORCE=1
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

if [[ "${QUERY}" == "1" ]]; then
  do_query
elif [[ "${SET}" == "1" ]]; then
  do_set "${HOST}"
else
  usage
  exit 1
fi

