# https://github.com/btkrausen/vault-codespaces/blob/main/.devcontainer/Dockerfile
# https://github.com/star3am/k3s-devcontainer/blob/main/.devcontainer/Dockerfile

ARG VAULT_VERSION=latest
FROM hashicorp/vault:${VAULT_VERSION}

ARG VAULT_MCP_SERVER_VERSION=0.2.0

USER root

# Install base packages (hashicorp/vault is Alpine based)
RUN apk add --no-cache \
        bash \
        bash-completion \
        curl \
        figlet \
        git \
        github-cli \
        gnupg \
        jq \
        less \
        logrotate \
        openssh-client \
        openssl \
        pre-commit \
        shellcheck \
        sudo \
        unzip \
        vim

# Give the vault user a login shell and passwordless sudo
RUN sed -i 's|^\(vault:.*\):/sbin/nologin$|\1:/bin/bash|' /etc/passwd && \
    mkdir -p /etc/sudoers.d /home/vault && \
    echo 'vault ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/vault && \
    chmod 440 /etc/sudoers.d/vault

# Install latest Terraform, HCP CLI, gitleaks and the Vault MCP server for the container's architecture
RUN case "$(uname -m)" in \
        x86_64) ARCH=amd64 ;; \
        aarch64|arm64) ARCH=arm64 ;; \
        *) ARCH=arm ;; \
    esac && \
    cd /tmp && \
    TERRAFORM_VERSION=$(curl -fsSL https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r .current_version) && \
    curl -fsSLo terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip && \
    unzip -o terraform.zip terraform -d /usr/local/bin && \
    HCP_VERSION=$(curl -fsSL https://checkpoint-api.hashicorp.com/v1/check/hcp | jq -r .current_version) && \
    curl -fsSLo hcp.zip https://releases.hashicorp.com/hcp/${HCP_VERSION}/hcp_${HCP_VERSION}_linux_${ARCH}.zip && \
    unzip -o hcp.zip hcp -d /usr/local/bin && \
    GITLEAKS_ARCH=$(case "${ARCH}" in amd64) echo x64 ;; arm64) echo arm64 ;; *) echo armv7 ;; esac) && \
    GITLEAKS_VERSION=$(curl -fsSLI -o /dev/null -w "%{url_effective}" https://github.com/gitleaks/gitleaks/releases/latest | sed "s|.*/v||") && \
    curl -fsSL https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_${GITLEAKS_ARCH}.tar.gz | tar -xz -C /usr/local/bin gitleaks && \
    curl -fsSLo vault-mcp-server.zip https://releases.hashicorp.com/vault-mcp-server/${VAULT_MCP_SERVER_VERSION}/vault-mcp-server_${VAULT_MCP_SERVER_VERSION}_linux_${ARCH}.zip && \
    unzip -o vault-mcp-server.zip vault-mcp-server -d /usr/local/bin && \
    chmod +x /usr/local/bin/terraform /usr/local/bin/hcp /usr/local/bin/gitleaks /usr/local/bin/vault-mcp-server && \
    rm -f /tmp/*.zip

# Set message of the day MOTD file and shared Vault environment for every interactive shell
COPY ./etc/update-motd.d/00-header /etc/update-motd.d/
COPY ./etc/profile.d/vault-env.sh /etc/profile.d/
RUN chmod +x /etc/update-motd.d/00-header && \
    echo '. /etc/profile.d/vault-env.sh' >> /home/vault/.bashrc && \
    echo 'bash /etc/update-motd.d/00-header' >> /home/vault/.bashrc && \
    echo 'root' > /home/vault/.vault-token && \
    chmod 600 /home/vault/.vault-token && \
    echo '[ -f ~/.bashrc ] && . ~/.bashrc' >> /home/vault/.bash_profile && \
    chown -R vault:vault /home/vault

# VAULT_TOKEN is deliberately not set: the CLI reads ~/.vault-token instead,
# so `vault login` in one terminal applies to all terminals
ENV VAULT_ADDR=http://127.0.0.1:8200 \
    VAULT_DEV_ROOT_TOKEN_ID=root \
    VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200

EXPOSE 8200

# docker-compose.yml starts the Vault dev server in the background with the image's own
# docker-entrypoint.sh, logging to /tmp/vault.log, so the container stays up if Vault fails.
