# Emulated IoT (ELIOT) Platform

The Emulated IoT (ELIOT) platform enables emulating simple IoT devices on top of Docker. It is based on libraries, [coap-node](https://github.com/PeterEB/coap-node) and [Leshan](https://github.com/eclipse/leshan), which implement device management over CoAP and LWM2M. Devices consisting of simple sensors and actuators can be built using IPSO objects. The current implementation provides ready-to-use devices, such as weather observer, presence detector, light controller and radiator.

More detailed information about ELIOT can be found in the [wiki](https://github.com/Alliasd/ELIOT/wiki).

**This module implements the following LWM2M interfaces & operations:**

Bootstrap | Register   | Device Management & Service Enablement | Information Reporting
--------- | ---------- | -------------------------------------- | -----------------------
Bootstrap | Register   | Read (Text/JSON/TLV)                   | Observe (Text/JSON/TLV)
          | Update     | Write (Text/JSON/TLV)                  | Notify (Text/JSON/TLV)
          | Deregister | Create (JSON/TLV)                      | Cancel
          |            | Execute                                |
          |            | Delete                                 |
          |            | Write attributes

## Usage with Docker

![alt text](https://github.com/ricCap/ELIoT/blob/master/docs/eliot.gif)

1. Run the LWM2M Server:

  `docker run --rm -ti --name ms corfr/leshan`

2. Run the LWM2M Bootstrap Server:

  `docker run --rm -ti --name bss --link ms corfr/leshan bootstrap`

3. Run the devices (PresenceDetector | WeatherObserver | LightController | Radiator):

  **Without Bootstrap Server**

  `docker run -it --link ms riccap/eliot <jsfile_name> ms [OPTIONS]`

  **With Bootstrap Server**

  `docker run -it --link bss --link ms riccap/eliot <jsfile_name> bss [OPTIONS]`

  ```
  JS-files:
  * presence.js
  * weather.js
  * light_control.js
  * radiator.js

  Options:
  -b          Bootstrap mode
  -t          Real Weather data (only WeatherObserver)
  ```

  **Note**: instead of using the name ms/bss you can use the IP address without the --link flags.

4. Run multiple clients with docker-compose. The basic configuration docker-compose spins-up the LWM2Mbootstrap server and the LWM2M server plus the IoT devices. The default configuration includes also monitoring capabilities: cadvisor for containers monitoring, node exporter for machine monitoring, prometheus to collect the various metrics, and Grafana to show them.

Note the -d flag to run docker-compose in detached mode.

`docker-compose up -d`

`docker-compose scale weather=X presence=X radiator=X light=X`

If you do not want to include the monitoring services just run

`docker-compose -f docker-compose.yml up -d`

or simply rename the docker-compose.override.yml file (e.g. to docker-compose.monitoring.yml), and then use it later through

`docker-compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d`

## Monitoring

An extension of the project allows you to monitor resources used by the system through various components such as [Prometheus](https://prometheus.io/), [Grafana](https://grafana.com/), [cadvisor](https://github.com/google/cadvisor) and [node exporter](https://github.com/prometheus/node_exporter). A Grafana dashboard has been implemented to give a general overview of resource utilisation for ELIOT; the dashboard works only with the K8s deployment (not with docker-compose). A snapshot of the dashboard can be downloaded from Grafana website using the dashboard id _12627_.

### Monitoring ELIOT in docker-compose

The default deployment of Prometheus and Grafana stores data and configurations in docker volumes. To check where the data is stored:

```
docker volume ls
docker volume inspect NAME_OF_THE_VOLUME | jq -r '.[0].Mountpoint'
```

You can store the data on a directory of your local host by commenting out the docker volume and using the absolute path in `docker-compose.override.yml` as shown below.

With docker volumes:

```yaml
#- /tmp/eliot/grafana-storage:/var/lib/grafana # shared with K8s
- grafana-storage:/var/lib/grafana # only docker-compose
- grafana-config:/etc/grafana
```

With absolute path:

```yaml
- /tmp/eliot/grafana-storage:/var/lib/grafana # shared with K8s
# - grafana-storage:/var/lib/grafana # only docker-compose
# - grafana-config:/etc/grafana
```

### Monitoring ELIOT in k8s

Please refer to the [README](https://github.com/ricCap/ELIoT/tree/master/k8s) of the K8s folder.
