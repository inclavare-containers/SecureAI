#!/bin/bash

set -euo pipefail
set -o noglob

usage() {
  echo "This script is used to download encrypted mode from Aliyun OSS and decrypt it." 1>&2

  exit 1
}

# Parse cmd
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

# download encrypted model
OSSUTIL_CONFIG="[default]\naccessKeyId=${ACCESS_KEY}\naccessKeySecret=${ACCESS_SECRET}\nregion=cn-beijing"
echo -e "${OSSUTIL_CONFIG}" > /root/.ossutilconfig
ossutil cp -r oss://${BUCKET_NAME}/${MODEL_TYPE}/ /tmp/encrypted-model/

# decrypt encrypted model
PASSWORD_FILE=/tmp/gocryptfs-decryptionkey/key
TIME_LIMIT=60
SECONDS_PASSED=0
FILE_EXISTS=false
while [ ${SECONDS_PASSED} -lt ${TIME_LIMIT} ]; do
  if [ -f "${PASSWORD_FILE}" ]; then
      FILE_EXISTS=true
      break
  else
      echo "wait for gocryptfs encryption key..."
      sleep 1
      ((${SECONDS_PASSED}++))
  fi
done

if [ "${FILE_EXISTS}" = false ]; then
    echo "password ${PASSWORD_FILE} not detect in ${TIME_LIMIT} seconds, exiting..."
    exit 1
fi

cat ${PASSWORD_FILE} | gocryptfs /tmp/encrypted-model /tmp/plaintext-model

echo "model decrypted to '/tmp/plaintext-model'"