FROM	alpine

SHELL	["/bin/ash", "-euvxo", "pipefail", "-c"]

RUN	apk add --update --upgrade --no-cache \
		ca-certificates bash iproute2 iptables ip6tables openvpn sudo

ARG     USR="vpnd"
RUN	addgroup -S "${USR}"; \
	adduser -H -D -S -s /sbin/nologin -g "${USR}" "${USR}"; \
	printf '%s ALL=(ALL) NOPASSWD: ALL\n' "${USR}" | tee -a /etc/sudoers

SHELL   ["/bin/bash", "-evxo", "pipefail", "-c"]

ARG     VAULT_VERSION=none
ARG     GO_VERSION=1.12.6
RUN	if [[ "${VAULT_VERSION}" != "none" ]]; then \
		mkdir -vp /lib64; \
		ln -vs "/lib/libc.musl-$(uname -m).so.1" "/lib64/ld-linux-$(uname -m | tr '_' '-').so.2"; \
		ln -vs "/lib/libc.musl-$(uname -m).so.1" "/lib/ld64.so.1"; \
	else \
		exit 0; \
	fi; \
	case "$(apk --print-arch)" in \
		arm*) ARCH='arm' ;; \
                aarch64) ARCH='arm64' ;; \
                x86_64) ARCH='amd64' ;; \
                x86) ARCH='386' ;; \
                *) echo >&2 "error: unsupported architecture"; exit 1 ;; \
        esac; \
	if [[ -z "$VAULT_VERSION" ]] || [[ "${VAULT_VERSION}" == "latest" ]]; then \
		apk add --update --upgrade --no-cache --virtual .deps \
			binutils git; \
		export GOPATH="$(mktemp -d)"; \
                case "${ARCH}" in \
                        arm*) ARCH=armv6l;; \
                esac; \
		wget -qO- "https://dl.google.com/go/go${GO_VERSION}.$(uname -s | tr '[[:upper:]]' '[[:lower:]]')-${ARCH}.tar.gz" | tar zxf - -C /usr/local; \
		/usr/local/go/bin/go get -v github.com/hashicorp/vault; \
		mv -v "${GOPATH}/bin/vault" /usr/local/bin/vault; \
		strip /usr/local/bin/vault; \
		vault version; \
		rm -fr "${GOPATH}" /usr/local/go /root/.cache; \
		apk del .deps; \
	else \
		cd /tmp; \
		wget -qO vault.zip "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_${ARCH}.zip"; \
		unzip vault.zip; \
		mv -v vault /usr/local/bin/vault; \
		vault version; \
		rm -fr vault.zip; \
	fi

ADD	https://raw.githubusercontent.com/nexus166/ovpnd/master/ovpnd /usr/local/bin/ovpnd
RUN	chmod -v a+rx /usr/local/bin/ovpnd
#COPY	ovpnd	/usr/local/bin/ovpnd

USER	"${USR}"

ENTRYPOINT ["/usr/local/bin/ovpnd"]
