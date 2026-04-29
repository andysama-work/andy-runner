#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -gt 0 ]]; then
  exec "$@"
fi

if [[ ! -d /data ]]; then
  mkdir -p /data
fi

cd /data

RUNNER_STATE_FILE=${RUNNER_STATE_FILE:-.runner}
GITEA_MAX_REG_ATTEMPTS=${GITEA_MAX_REG_ATTEMPTS:-10}

CONFIG_ARGS=()
if [[ -n "${CONFIG_FILE:-}" ]]; then
  CONFIG_ARGS=(--config "${CONFIG_FILE}")
fi

REGISTER_ARGS=()
if [[ -n "${GITEA_RUNNER_LABELS:-}" ]]; then
  REGISTER_ARGS+=(--labels "${GITEA_RUNNER_LABELS}")
fi
if [[ -n "${GITEA_RUNNER_EPHEMERAL:-}" ]]; then
  REGISTER_ARGS+=(--ephemeral)
fi

RUN_ARGS=()
if [[ -n "${GITEA_RUNNER_ONCE:-}" ]]; then
  RUN_ARGS+=(--once)
fi

if [[ -z "${GITEA_RUNNER_REGISTRATION_TOKEN:-}" && -n "${GITEA_RUNNER_REGISTRATION_TOKEN_FILE:-}" && -f "${GITEA_RUNNER_REGISTRATION_TOKEN_FILE}" ]]; then
  GITEA_RUNNER_REGISTRATION_TOKEN=$(cat "${GITEA_RUNNER_REGISTRATION_TOKEN_FILE}")
fi

if [[ ! -s "${RUNNER_STATE_FILE}" ]]; then
  if [[ -z "${GITEA_INSTANCE_URL:-}" ]]; then
    echo "ERROR: GITEA_INSTANCE_URL is required when ${RUNNER_STATE_FILE} is missing." >&2
    exit 1
  fi

  if [[ -z "${GITEA_RUNNER_REGISTRATION_TOKEN:-}" ]]; then
    echo "ERROR: GITEA_RUNNER_REGISTRATION_TOKEN or GITEA_RUNNER_REGISTRATION_TOKEN_FILE is required when ${RUNNER_STATE_FILE} is missing." >&2
    exit 1
  fi

  attempt=1
  success=0
  while [[ "${success}" -eq 0 && "${attempt}" -le "${GITEA_MAX_REG_ATTEMPTS}" ]]; do
    echo "Registering Gitea runner, attempt ${attempt}/${GITEA_MAX_REG_ATTEMPTS} ..."
    if act_runner register \
      --instance "${GITEA_INSTANCE_URL}" \
      --token "${GITEA_RUNNER_REGISTRATION_TOKEN}" \
      --name "${GITEA_RUNNER_NAME:-$(hostname)}" \
      "${CONFIG_ARGS[@]}" "${REGISTER_ARGS[@]}" --no-interactive 2>&1 | tee /tmp/act-runner-register.log; then
      if grep -q 'Runner registered successfully' /tmp/act-runner-register.log || [[ -s "${RUNNER_STATE_FILE}" ]]; then
        echo "Runner registered successfully."
        success=1
        break
      fi
    fi

    attempt=$((attempt + 1))
    if [[ "${attempt}" -le "${GITEA_MAX_REG_ATTEMPTS}" ]]; then
      echo "Registration failed, waiting to retry ..."
      sleep 5
    fi
  done

  if [[ "${success}" -ne 1 ]]; then
    echo "ERROR: Runner registration failed after ${GITEA_MAX_REG_ATTEMPTS} attempts." >&2
    exit 1
  fi
fi

unset GITEA_RUNNER_REGISTRATION_TOKEN
unset GITEA_RUNNER_REGISTRATION_TOKEN_FILE

exec act_runner daemon "${CONFIG_ARGS[@]}" "${RUN_ARGS[@]}"
