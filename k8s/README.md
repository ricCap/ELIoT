# Deploy ELIoT on K8s

## Prerequisites

We are currently using Helm to deploy the node exporter, so you will need to have it configured.

## Develop locally using KIND

[KIND](https://kind.sigs.k8s.io/), alias Kubernetes IN Docker, allows to deploy k8s clusters locally (in Docker). As an advantage to Minikube, it can handle multinode configuration on the same machine (e.g. 1 master node and 2 worker nodes),which allows us to simulate a huge amount of IoT devices.

By running `./setup.sh --kind` you can leave the script do the magic for you. Other options are documented in `setup.sh -h`

```
Services are automatically deployed when creating a cluster

-k|--kind                    Create a kind cluster
-a|--admin                   Deploy a k8s cluster using kubeadm
-s|--services A || "A B C"   Deploy a single service A or a list of services "A B C"
-d|--default-services        Deploy default services
--show-default-services      Show services that are deployed by default
--scale TARGET REPLICAS      Scale the target device to number of replicas; target "all" is allowed
--no-services                Do not deploy default services
```

Be sure to check that everything is deployed correctly `watch kubectl get po -A`.

## Default configuration

The default max number of pods per node is 110\. Adding worker nodes to the kind configuration file increases the number of deployable pods by the default 110 per node.

```
- role: worker
  extraMounts:
  - hostPath: /tmp/eliot
    containerPath: /tmp/eliot
```

Note that the various services (e.g. grafana) might be deployed on other nodes, meaning that you would need to port-forward them directly if you want to get access.

`kubectl port-forward POD -n NAMESPACE HOST_PORT:POD_PORT`

or

`docker port-forward NODE HOST_PORT:NODE_PORT`

# Deploy over multiple servers

Be sure to have the correct configuration ready on the server where you want K8s to run the control-plane ([docs](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)). Then run `./setup.sh --admin` and subsequently run the join command on the worker nodes. For more information check [k8s docs](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/).

# Resource limits

To set specific resource limits before scaling ELIoT is advised; this allows you to set an upper bound for resource usage for the eliot namespace. Please run the following command in the `eliot` folder. For more information please refer to the [documentation](https://kubernetes.io/docs/concepts/policy/resource-quotas/). `MEMORY="1Gi" CPU="1" envsubst < resource-quota.yml | kubectl apply -f -`

Check that everything works `kubectl describe quota -A`
