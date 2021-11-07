.PHONY: clean install_known_hosts

IP_ADDR ?= 192.168.64.254
PUB_KEY ?= $(HOME)/.ssh/id_ed25519.pub
SIZE ?= 128G

arch.img: arch.img.lz4
	lz4 -d < "$<" > "$@"
	truncate -s "$(SIZE)" "$@"
	$$(brew --prefix e2fsprogs)/sbin/resize2fs "$@"

arch.img.lz4: build.sh bootstrap.sh pkg.lst ssh_host_ed25519_key
	docker run \
		--rm \
		--privileged \
		$(foreach file,$^,-v "$$PWD/$(file)":"/$(file)") \
		-e SIZE="$(SIZE)" \
		-e IP_ADDR="$(IP_ADDR)" \
		-e PUB_KEY="$(shell cat $(PUB_KEY))" \
		alpine "/$<" > "$@"

ssh_host_ed25519_key:
	ssh-keygen -t ed25519 -C "" -N "" -f "$@"

install_known_hosts: ssh_host_ed25519_key
	gsed -i '/^$(IP_ADDR).*$$/d' ~/.ssh/known_hosts
	echo "$(IP_ADDR) $$(ssh-keygen -y -f "$<")" >> ~/.ssh/known_hosts

clean:
	rm -f arch.img arch.img.lz4 ssh_host_ed25519_key ssh_host_ed25519_key.pub
