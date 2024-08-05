help: 
	@ echo "Ansible v1.0.0 Makefile options:"
	@ $(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

activate:
	@ . ../../.venv/bin/activate

run: activate
	@ ansible-playbook -i ../../inventories/home.yaml main.yaml
