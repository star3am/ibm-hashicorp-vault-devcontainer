# shellcheck shell=bash
# Shared Vault environment for every terminal in the DevContainer.
#
# The token lives in ~/.vault-token (Vault's own token helper), so `vault login`
# in any terminal applies to all terminals immediately.
#
# Variables set with `vexport` are stored in ~/.vault.env and picked up by every
# terminal, including ones that are already open, on their next prompt.
#
#   vexport VAULT_NAMESPACE=admin   # set in all terminals
#   vunset VAULT_NAMESPACE          # unset in all terminals

VAULT_ENV_FILE="${HOME}/.vault.env"

__vault_env_write() {
  touch "${VAULT_ENV_FILE}"
  sed -i -e "/^export $1=/d" -e "/^unset $1\$/d" "${VAULT_ENV_FILE}"
  echo "$2" >> "${VAULT_ENV_FILE}"
}

vexport() {
  local pair
  for pair in "$@"; do
    __vault_env_write "${pair%%=*}" "$(printf 'export %s=%q' "${pair%%=*}" "${pair#*=}")"
  done
  __vault_env_sum=""
  __vault_env_sync
}

vunset() {
  local name
  for name in "$@"; do
    __vault_env_write "${name}" "unset ${name}"
  done
  __vault_env_sum=""
  __vault_env_sync
}

# Re-source ~/.vault.env whenever any terminal changed it
__vault_env_sync() {
  [ -f "${VAULT_ENV_FILE}" ] || return 0
  local sum
  sum=$(cksum < "${VAULT_ENV_FILE}")
  if [ "${sum}" != "${__vault_env_sum}" ]; then
    # shellcheck source=/dev/null
    . "${VAULT_ENV_FILE}"
    __vault_env_sum="${sum}"
  fi
}

__vault_env_sync

case ";${PROMPT_COMMAND};" in
  *";__vault_env_sync;"*) ;;
  *) PROMPT_COMMAND="__vault_env_sync${PROMPT_COMMAND:+;${PROMPT_COMMAND}}" ;;
esac
