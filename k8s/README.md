# Deploy ELIoT on K8s

[KIND](https://kind.sigs.k8s.io/), alias Kubernetes IN Docker, allows to deploy k8s clusters locally (in Docker). As an advantage to Minikube, it can handle multinode configuration on the same machine (e.g. 1 master node and 2 worker nodes).

By running `./setup.sh` you can leave the script do the magic for you. If you prefer to use some other tool rather than KIND (e.g. Minikube), simply follow the instructions below.

1. At first the kind cluter is created and some ports are exposed to the host machine (i.e. your laptop). The ports are localhost:30000 for Prometheus and localhost:30001 for Grafana. If you don't use kind you might need to configure your own port forwarding.

2. Deploy prometheus by running `cd prometheus; ./setup.sh`. This does the following:

  - create a namespace for our monitoring containers (called **"monitoring"**)
  - create a clusterRole to access k8s API
  - create a configMap in order to be able to modify Prometheus configurations easily
  - create a deployment
  - create a service and expose a port to the host machine

3. Check that everything is ok `kubectl get po -n monitoring`

4. Deploy kube-state-metrics to have better insight into k8s state. Prometheus configuration already includes the right entry.

  `cd kube-state-metrics; ./setup.sh`

5. Check that everything works `kubectl get deployments kube-state-metrics -n kube-system`

6. Deploy Grafana `cd grafana; ./setup.sh`

7. Check that Grafana is working `kubectl get po -n monitoring`

8. Deploy node-exporter using Helm

  `helm install stable/prometheus-node-exporter --version 1.9.1 --generate-name --set prometheus.monitor.namespace=monitoring --set namespaceOverride="monitoring"`

9. Check that everything works `kubectl get po -A`

10. Scale the number of devices

  ```
  kubectl scale deployment.v1.apps/eliot-presence -n eliot --replicas=2

  kubectl scale deployment.v1.apps/eliot-radiator -n eliot --replicas=2

  kubectl scale deployment.v1.apps/eliot-weather -n eliot --replicas=2

  kubectl scale deployment.v1.apps/eliot-light -n eliot --replicas=2
  ```

11. Once you are done with using the application simply run `kind delete cluster`
