# ArgoCD Home Cluster

This is the ArgoCD folder for my Homeland. 

## Setup

1. Create the repository credential secret. You can use the [template](https://github.com/sromerotech/boilerplates/blob/main/argocd/repository-credentials-ssh.yaml) in the [boilerplates](https://github.com/sromerotech/boilerplates) repo.
    ```bash
    $ kubectl \
      --kubeconfig /path/to/config.yaml \
      apply -f repository-credentials-<provider>-<account>.yaml
    ```

2. Create the respository manifest. You can use the [template](https://github.com/sromerotech/boilerplates/blob/main/argocd/repository.yaml) in the [boilerplates](https://github.com/sromerotech/boilerplates) repo. You can find an actual example [here](https://github.com/sromerotech/homelab/blob/main/argocd/respositories/github.com/repository-github-sromerotech-homelab.yaml).
    ```bash
    $ kubectl \
      --kubeconfig /path/to/config.yaml \
      apply -f repository-<provider>-<account>-homelab.yaml
    ```

3. Apply the `applicationSet.yaml` manifest by hand in order to tell ArgoCD
to monitor the `clusters/home` folder. Once applied, create a new folder with an `application.yaml` [manifest](https://github.com/sromerotech/homelab/tree/main/argocd/clusters/home/homepage) and commit it to autodeploy the new service.
    ```bash
    $ kubectl \
      --kubeconfig /path/to/config.yaml \
      apply -f clusters/home/applicationSet.yaml
    ```
