# ArgoCD Home Cluster

This is the ArgoCD folder for my Homeland. 

## Requirements

Wait for the K3s cluster to has installed [servers/k3s/manifests/argocd.HelmChart.yaml](../servers/k3s/manifests/argocd.HelmChart.yaml). 


## Setup

1. Create the repository credential secret. You can use the [template](https://github.com/sromerotech/boilerplates/blob/main/argocd/example-ssh.repository-credentials.yaml) in the [boilerplates](https://github.com/sromerotech/boilerplates) repo.
    ```bash
    $ kubectl \
      --kubeconfig /path/to/config.yaml \
      apply -f <provider>-<account>.repository-credentials.yaml
    ```

2. Create the respository manifest. You can use the [template](https://github.com/sromerotech/boilerplates/blob/main/argocd/example.repository.yaml) in the [boilerplates](https://github.com/sromerotech/boilerplates) repo. You can find an actual example [here](https://github.com/sromerotech/homelab/blob/main/argocd/selfconfig/repositories/github-sromerotech-homelab.repository.yaml).
    ```bash
    $ kubectl \
      --kubeconfig /path/to/config.yaml \
      apply -f <provider>-<account>.repository.yaml
    ```

3. Apply the root `applicationSet.yaml` manifest by hand in order to tell ArgoCD
to monitor itself: 
    ```bash
    $ kubectl \
      --kubeconfig /path/to/config.yaml \
      apply -f argocd/applicationSet.yaml
    ```


## Usage

Create a new folder in `argocd/apps` with an `application.yaml` [manifest](https://github.com/sromerotech/homelab/tree/main/argocd/apps/home-assistant/application.yaml) and commit it to autodeploy the new service.
