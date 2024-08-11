# Homelab - Installation

1. Download the [Raspberry Pi Imager](https://www.raspberrypi.com/software/).
2. Configure the installer to burn `Ubuntu Server`. Use the OS customization to set:
    - `Hostname`: An identificable name for your server.
    - `Locale`: Your language settings preference.
    - `Enable SSH` > `Allow public-key authentication only`: The public-key part of an SSH key configured in your current host.
3. Once the installer is finished, put the SD card back to the Raspberry Pi, turn it on,
  and wait for the boot up. It should take a couple of minutes.
4. Go to your router's homepage (`192.168.1.1` or similar) and asign a fixed IP to the
  Raspberry Pi. You should see a device named as the `Hostname` field you set before.
5. `cd` into `ansible/` folder and execute `make setup` to prepare Ansible dependencies.
6. Check that `ansible_host` in `ansible/inventories/home.yaml` match your Raspberry Pi IP.
7. `cd` into `ansible/playbooks/home-node` and execute `make run`. This will update and prepare your
  Raspberry Pi with the minimun software required and configuration. This will take some time to complete, specially the `COMMON:Update my hosts` task.
8. Now, you should have a `ansible/playbooks/home-node/output/kubeconfig-<host>.yaml` file with the kubeconfig of your K8S node. Load it into your desired **context**, [management application](https://k8slens.dev/) or use it as a paramater of the `kubectl` command.

    > Update the server ip (127.0.0.1) with your Raspberry Pi IP.
    >
    > You may want to change `default` by a meaningful name, like the hostname of the node.

    Check the cluster by running a simple kubectl command:

    ```bash
    $ kubectl get node \
      --kubeconfig ansible/playbooks/home-node/output/kubeconfig-<host>.yaml
    ```
9. Now, your Raspberry Pi is setup and ready to work. Go to the [Homelab ArgoCD documentation](../argocd/README.md) to install the remaining software.
