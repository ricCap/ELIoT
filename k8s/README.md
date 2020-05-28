# Deploy ELIoT on K8s

## Using KIND

[KIND](https://kind.sigs.k8s.io/), alias Kubernetes IN Docker, allows to deploy k8s clusters locally (in Docker). As an advantage to Minikube, it can handle multinode configuration on the same machine (e.g. 1 master node and 2 worker nodes).

1. Run setup.sh in order to create the cluster. This command exposes some ports from the kind cluster to the host machine (i.e. your laptop).

2. Deploy prometheus by running /prometheus/setup.sh. This command:

  - creates a namespace for our monitoring containers (called **"monitoring"**)
  - create a clusterRole to access k8s API
  - create a configMap in order to be able to modify prometheus configurations easily
  - create a deployment
  - create a service and expose a port to the host machine

3. Check that everything is ok `kubectl get po -n monitoring`

4. Deploy kube-state-metrics to have better insight into k8s state. Prometheus configuration already includes the right entry.

  `cd kube-state-metrics ./setup.sh`

5. Check that everything works `kubectl get deployments kube-state-metrics -n kube-system`

helm install stable/prometheus-node-exporter --version 1.9.1 --generate-name --set prometheus.monitor.namespace=monitoring --set namespaceOverride="monitoring"
