#!/bin/sh
set -eu

REPO_NAME="${REPO_NAME:-$(basename "$(git remote get-url origin | rev | cut -d '/' -f 1 | rev)" .git)}"
IMAGE="${IMAGE:-$REPO_NAME-ansible-runner}"

if [ "$#" -eq 0 ]; then
    set -- ansible-playbook site.yml
fi

trap "rm -rf context/" EXIT
docker run \
    --rm \
    -u "$(id -u):$(id -g)" \
    -v "$PWD:$PWD" \
    -w "$PWD" \
    quay.io/ansible/ansible-builder \
    ansible-builder create

export DOCKER_BUILDKIT=1
docker build --pull -t "$IMAGE" context
[ "$#" -eq 1 ] && [ "$1" = "--build" ] && exit

docker run \
    --network host \
    --rm \
    -e ANSIBLE_FORCE_COLOR=True \
    -e ANSIBLE_HOST_KEY_CHECKING=False \
    -e ANSIBLE_VAULT_PASSWORD_FILE \
    -e SSH_AUTH_SOCK \
    -v "$ANSIBLE_VAULT_PASSWORD_FILE:$ANSIBLE_VAULT_PASSWORD_FILE:ro" \
    -v "$SSH_AUTH_SOCK:$SSH_AUTH_SOCK:ro" \
    -v "$PWD:$PWD:ro" \
    -w "$PWD" \
    "$IMAGE" \
    "$@"
