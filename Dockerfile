FROM debian
LABEL authors="prabhjotbawa"
RUN apt-get update && apt-get install -y curl gnupg software-properties-common
# Add hashicorp gpg key
RUN curl https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
# Check the key
RUN gpg --no-default-keyring \
--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
--fingerprint
# Add hashicorp repo to download terraform
RUN echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
tee /etc/apt/sources.list.d/hashicorp.list
# Download package information from hashicorp and install terraform
RUN apt update
RUN apt-get install terraform -y

# Add folders
WORKDIR $HOME/eks
ADD . $HOME/eks