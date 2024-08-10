# Pihole

Before deploying this application, create a secret in the target namespace with the env configuration used by pihole.

```bash
$ kubectl create secret generic pihole-envars \
  --from-literal=TZ=UTC \
  --from-literal=WEB_PORT=80 \
  --from-literal=VIRTUAL_HOST=pihole.home \
  --from-literal=DNS1=8.8.8.8 \
  --from-literal=DNS2=8.8.4.4 \
  --from-literal=ServerIP=192.168.1.39 \
  --from-literal=WEBPASSWORD=123456 \
  --kubeconfig /path/to/config.yaml \
  --namespace dns
```
