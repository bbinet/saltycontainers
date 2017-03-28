THIN_MD5="02cc2091da7b05d67ea5e1f72aa0bea7"
THIN_RM := $(shell echo "${THIN_MD5}  .tmp/thin.tgz" | md5sum --check --status || echo thin_rm)
SALT=python2.7 .tmp/thin/salt-call -c ${CURDIR}
SALT_APPLY=${SALT} --state-output=changes state.apply

help:
	@echo "Available targets: deps thin thin_rm grains pillar salt apply apply_formula apply_build all"

deps:
	apt-get install -y git wget python2.7 python-apt jq

.tmp/thin.tgz: ${THIN_RM}
	mkdir -p .tmp/
	wget -O .tmp/thin.tgz https://github.com/bbinet/salt/releases/download/develop_thin_tgz/thin.tgz
	rm -fr .tmp/thin && mkdir -p .tmp/thin && tar zxvf .tmp/thin.tgz -C .tmp/thin/
thin: .tmp/thin.tgz
thin_rm:
	rm -f .tmp/thin.tgz

grains: thin
	${SALT} grains.items
pillar: thin
	${SALT} pillar.items
salt: thin
	@arg="$(arg)"; \
	if [ -z "$$arg" ]; then \
		echo -n "Enter salt arguments below:\n${SALT} "; \
		read -r arg; \
	fi; \
	${SALT} $$arg
apply: thin
	@arg="$(arg)"; \
	if [ -z "$$arg" ]; then \
		echo -n "Enter state to apply:\n${SALT_APPLY} "; \
		read -r arg; \
	fi; \
	${SALT_APPLY} $$arg
apply_formula: thin
	# this state should be run twice because jinja is not evaluated at runtime:
	# https://github.com/saltstack/salt/issues/38072
	${SALT_APPLY} salty.formula
	${SALT_APPLY} salty.formula
apply_build: thin
	${SALT_APPLY} salty.build

all: deps apply_formula apply_build

.PHONY: deps thin thin_rm grains pillar salt apply apply_formula apply_build all
