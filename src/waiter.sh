spin()
{
    spinner="/|\\-/|\\-"
    while :
    do
        for i in `seq 0 7`
        do
            echo -e "\r[${spinner:$i:1}] Waiting for deployment to finish..."
            echo -en "\033[1A"
            sleep 1
        done
    done
}

# This should not used for tests where there are more complex deployments
# and we need to wait for a ready state 1/1.
wait_for_deployment() {
    selector=$1
    spin &
    SPIN_PID=$!
    trap "ps a | awk '{print $1}' | grep -q "${SPIN_PID}" && kill -9 $SPIN_PID || exit 0" `seq 0 15`
    while :
    do
        output=$(kubectl get pods --field-selector=status.phase=Running --selector=${selector} -o jsonpath='{.items[*].status.phase}' | tr ' ' '\n' | uniq)
        if [ "${output}" == "Running" ]; then
            echo -e "\ncluster finished deployment"
            kill -9 $SPIN_PID
            break
        fi
        sleep 0.5
    done
}

wait_for_deployment_ready_state() {
    selector=$1
    # TODO: Implement complex search for cluster deployment ready state.
    JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'
    kubectl get pods --selector=${selector} -o jsonpath="$JSONPATH" | grep "Ready=True"
    if [[  $? -eq 0 ]]; then
        echo "All pods are in Ready 1/1 state."
    fi
}