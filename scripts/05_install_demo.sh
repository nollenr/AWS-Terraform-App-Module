ADMIN_HOME="/home/${admin_user}"

# Define the demo install function
cat >> "$ADMIN_HOME/.bashrc" <<'BASHRC'
export CRDB_CERT_URL="${database_connection_string}"
export DATABASE_REGIONS="${database_regions}"
%{ if app_private_ip_list != "" ~}
export APP_PRIVATE_IP_LIST="${app_private_ip_list}"
export APP_PUBLIC_IP_LIST="${app_public_ip_list}"
%{ endif ~}

MULTIREGION_IAM_DEMO() {

  sudo yum install -y gcc gcc-c++ libpq-devel
  sudo yum install -y python3.11 python3.11-devel python3.11-pip.noarch || true
  sudo yum install -y git
  sudo yum install -y docker
  sudo systemctl start docker
  sudo systemctl enable docker
  sudo usermod -a -G docker ec2-user

  # Get the demo
  if [ ! -d "$HOME/crdb-multi-region-demo" ]; then
    git clone https://github.com/nollenr/multi-region-iam-resiliency-demo.git "$HOME/crdb-multi-region-iam-demo"
  fi

  pip3.11 install -r crdb-multi-region-iam-demo/requirements.txt

  # Install Docker Compose
  sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  chmod +x crdb-multi-region-iam-demo/demo.py
  chmod +x crdb-multi-region-iam-demo/setup-demo.sh

}
BASHRC

# Optionally kick off the demo install automatically (matches your original logic)
if [[ "${include_demo}" == "yes" ]]; then
  echo "Installing Demo shortly..."
  sleep 60
  su ${admin_user} -lc 'MULTIREGION_IAM_DEMO'
fi

chown ${admin_user}:${admin_user} "$ADMIN_HOME/.bashrc"
