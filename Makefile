.PHONY: run_light
run_light:
	$(shell nix-build images.nix --no-out-link -A light)

.PHONY: run_standalone
run_standalone:
	$(shell nix-build images.nix --no-out-link -A standalone)

.PHONY: run_docker
run_docker:
	$(shell nix-build images.nix --no-out-link -A docker)

.PHONY: build_light
build_light:
	nix-build images.nix --no-out-link -A light.eval

.PHONY: build_standalone
build_standalone:
	nix-build images.nix --no-out-link -A standalone.eval

.PHONY: build_docker
build_docker:
	nix-build images.nix --no-out-link -A docker.eval
