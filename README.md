# Homelab

Almost everything needed to set up my personal servers. Inspired by [ChristianLempa](https://github.com/ChristianLempa)'s wonderful repository.

<p align="center">
    <a alt="Raspberry Pi">
      <img src="https://img.shields.io/badge/Raspberry_Pi-a22846?style=flat&logo=raspberry-pi&logoColor=white">
    </a>
    <a alt="Ansible">
      <img src="https://img.shields.io/badge/Ansible-000000?style=flat&logo=ansible&logoColor=white" />
    </a>
    <a alt="Kubernetes">
      <img src="https://img.shields.io/badge/Kubernetes-326ce5?style=flat&logo=kubernetes&logoColor=white" />
    </a>
    <a alt="K3s">
      <img src="https://img.shields.io/badge/K3s-ffe600?style=flat&logo=k3s&logoColor=black" />
    </a>
    <a alt="ArgoCD">
      <img src="https://img.shields.io/badge/ArgoCD-007acc?style=flat&logo=argo&logoColor=white" />
    </a>
    <a alt="GitHub">
      <img src="https://img.shields.io/badge/GitHub-181717?style=flat&logo=github&logoColor=white" />
    </a>
</p>

<p align="center">
  <img src="docs/homelab.png" alt="diagram-general"/>
</p>

## Current Issues

- DNS `Bind9 -> Pihole` chain makes **Pihole** to register all queries as the same client (`10-42-0-79.bind-service.dns.svc.cluster.local`).
- **Pihole** seems not to be blocking **custom domains**.
- `LoadBalancer` services in **K3S** exposes ports on the raspberry despite **UFW** not defining it.
