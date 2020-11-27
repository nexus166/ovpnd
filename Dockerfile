FROM	alpine:edge

ARG	USR="vpnd"
RUN	apk add --update --upgrade --no-cache \
		ca-certificates bash iproute2 iptables ip6tables openvpn socat sudo; \
	addgroup -S "${USR}"; \
	adduser -H -D -S -s /sbin/nologin -g "${USR}" "${USR}"; \
	printf '%s ALL=(ALL) NOPASSWD: ALL\n' "${USR}" | tee -a /etc/sudoers

SHELL   ["/bin/bash", "-evxo", "pipefail", "-c"]

ARG     VAULT_VERSION=1.6.0
RUN	case "$(apk --print-arch)" in \
		arm*) ARCH='arm' ;; \
                aarch64) ARCH='arm64' ;; \
                x86_64) ARCH='amd64' ;; \
                x86) ARCH='386' ;; \
                *) echo >&2 "error: unsupported architecture"; exit 1 ;; \
        esac; \
	cd /tmp; \
	wget -qO vault.zip "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_${ARCH}.zip"; \
	unzip vault.zip; \
	install -v -m 0755 vault /usr/local/bin/vault; \
	vault version; \
	rm -fr vault.zip

#ADD	https://raw.githubusercontent.com/nexus166/ovpnd/master/ovpnd /usr/local/bin/ovpnd
COPY	ovpnd	/usr/local/bin/ovpnd
#RUN	chmod -v a+rx /usr/local/bin/ovpnd

USER	"${USR}"

ENTRYPOINT ["/usr/local/bin/ovpnd"]
