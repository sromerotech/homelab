help: 
	@ echo "OpenTofu v1.0.0 Makefile options:"
	@ $(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

init:
	@ docker run --rm \
    --workdir=/srv/workspace \
    --mount type=bind,source=.,target=/srv/workspace \
    ghcr.io/opentofu/opentofu:latest \
    init

zip:
	@ rm lambda_function.zip
	@ cd lambda && zip -r ../lambda_function.zip function.py

plan: zip
	@ docker run --rm \
		--env-file .env \
    --workdir=/srv/workspace \
    --mount type=bind,source=.,target=/srv/workspace \
    -it \
    ghcr.io/opentofu/opentofu:latest \
    plan -out=main.plan

show:
	@ docker run --rm \
		--env-file .env \
    --workdir=/srv/workspace \
    --mount type=bind,source=.,target=/srv/workspace \
    -it \
    ghcr.io/opentofu/opentofu:latest \
    show

apply: plan
	@ docker run --rm \
		--env-file .env \
    --workdir=/srv/workspace \
    --mount type=bind,source=.,target=/srv/workspace \
    -it \
    ghcr.io/opentofu/opentofu:latest \
    apply "/srv/workspace/main.plan"
