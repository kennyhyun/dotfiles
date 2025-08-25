#!/bin/sh

# install terraform
# ubuntu/debian
# x64/arm64

# terraform

if [ -z "$(terraform --version)" ]; then
  echo Installing terraform

  #wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg -f --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  #echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

  curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
  sudo apt update && sudo apt install terraform
fi

# ansible

if [ -z "$(ansible --version)" ]; then
  # ansible
  echo Installing ansible
  pipx install --include-deps ansible
fi
