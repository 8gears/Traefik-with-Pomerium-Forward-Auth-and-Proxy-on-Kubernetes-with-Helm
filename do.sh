#!/usr/bin/env sh
# Do - The Simplest Build Tool on Earth.
# Documentation and examples see https://github.com/8gears/do

set -e -u # -e "Automatic exit from bash shell script on error"  -u "Treat unset variables and parameters as errors"

_checkCommands() {
    command -v k3d >/dev/null 2>&1 || {
        echo >&2 "k3d is required. but it's not installed."
        exit 1
    }
}

test() {
    _checkCommands
    k3d ct
    k3d create --name "doo-test" --wait 100 --server-arg "--no-deploy=traefik" --publish 8090:80 --publish 8443:443 -i "docker.io/rancher/k3s:latest"
    export KUBECONFIG="$(k3d get-kubeconfig --name='doo-test')"
    helmfile sync
    clean
    echo "Test Successful!"
}

clean() {
    k3d del --name "doo-test"
}

testCerManagerCRDExists() {
    _testCRDExists "issuers.cert-manager.io"
}
testTraefikCRDExists() {
    _testCRDExists "ingressroutes.traefik.containo.us"
}
_testCRDExists() {
    set +e
    kubectl get crd "$1" >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo "true"
        exit 0
    else
        echo "false"
        exit 0
    fi
}

"$@" # <- execute the task

[ "$#" -gt 0 ] || printf "Usage:\n\t./do.sh %s\n" "($(compgen -A function | grep '^[^_]' | paste -sd '|' -))"
