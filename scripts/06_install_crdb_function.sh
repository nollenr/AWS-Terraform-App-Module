ADMIN_HOME="/home/${admin_user}"

# Define the CRDB function
cat >> "$ADMIN_HOME/.bashrc" <<'BASHRC'

CRDB() {
    cockroach sql --url $CRDB_URI --set prompt1='CRDB%/ > '
}

BASHRC

chown ${admin_user}:${admin_user} "$ADMIN_HOME/.bashrc"
