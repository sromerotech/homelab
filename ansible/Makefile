help: 
	@ echo "Ansible v1.0.0 Makefile options:"
	@ $(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

setup:
	@ python -m venv .venv
	@ . .venv/bin/activate && pip install -r requirements.txt
