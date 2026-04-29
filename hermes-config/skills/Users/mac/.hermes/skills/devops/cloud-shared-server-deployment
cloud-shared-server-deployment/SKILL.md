---
name: cloud-shared-server-deployment
category: devops
description: Deploy new Docker projects on an existing shared cloud server without disturbing other services — port discovery, resource limits, and safe data sync.
---

# Cloud Shared Server Deployment

**Use Case:** Deploying a new Docker stack (e.g., MySQL + API + Web) on a cloud server (like 82.156.187.35) that already hosts other projects (CLM, etc.). The goal is zero interference.

---

## When to Use

- User asks to "deploy to the cloud server" or "start a docker on 82.156.187.35".
- The server is already running other containers/services.
- Data sync from TencentDB (read-only accounts) is required.

---

## Core Workflow

### 1. Port Discovery & Isolation

Before choosing ports, check what's already taken:
```bash
# SSH into server
sudo netstat -tulpn | grep -E ':(80|8080|8081|8082|3306|3307)'
```
**Rule:** Pick ports at least +5 away from existing ones (e.g., if 8081 is taken, use 8086).

### 2. Docker Compose Resource Limits

Always cap resources in `docker-compose.yml` to protect the host:
```yaml
services:
  mysql:
    deploy:
      resources:
        limits:
          cpus: '0.50'
          memory: 512M
  api:
    deploy:
      resources:
        limits:
          cpus: '0.50'
          memory: 256M
```

### 3. SSH/SCP Automation (No sshpass)

If `sshpass` is not installed on the local machine, use `expect` scripts:

**`/tmp/ssh_helper.sh`:**
```expect
#!/usr/bin/expect -f
set ip [lindex $argv 0]
set user [lindex $argv 1]
set pass [lindex $argv 2]
set cmd [lindex $argv 3]
set timeout 20
spawn ssh -o StrictHostKeyChecking=no $user@$ip $cmd
expect {
    "*yes/no*" { send "yes\r"; expect "*assword:*"; send "$pass\r" }
    "*assword:*" { send "$pass\r" }
}
expect eof
```

### 4. Data Sync from TencentDB (Read-Only Account)

**Critical:** When dumping from TencentDB using a read-only account (e.g., `btyc_hw_read`), `mysqldump` will fail or produce corrupt files unless you use these exact flags:

```bash
mysqldump -h REMOTE_HOST -P PORT -u USER -pPASS \
  --lock-tables=false \
  --no-tablespaces \
  --set-gtid-purged=OFF \
  database_name table1 table2 \
  2>/dev/null > dump.sql
```
- `--lock-tables=false`: Avoids `FLUSH TABLES` permission errors.
- `--no-tablespaces`: Avoids tablespace permission errors.
- `--set-gtid-purged=OFF`: Avoids GTID consistency warnings.
- `2>/dev/null`: Prevents warnings from being written into the SQL file, which would break the import.

### 5. Deployment Pattern

1.  **Package locally**: `tar czf deploy.tar.gz deploy/`
2.  **SCP to server**: `scp deploy.tar.gz user@ip:/opt/project-name/`
3.  **Extract & Run**:
    ```bash
    cd /opt/project-name
    tar xzf deploy.tar.gz --strip-components=1
    sudo docker compose down && sudo docker compose up -d --build
    ```

---

## Pitfalls

1.  **Port conflicts**: Always verify ports are free before setting up `docker-compose.yml`.
2.  **MySQL dump warnings**: Never ignore stderr during dump — redirect it! Otherwise `mysql < dump.sql` will fail with syntax errors at line 1.
3.  **Missing mysql client**: Cloud servers (Ubuntu minimal) often lack `mysql`/`mysqldump`. Install via `sudo apt-get install -y default-mysql-client`.
4.  **Over-provisioning**: Don't give containers too much RAM. Shared servers often have limited memory.
5.  **Docker Compose Version**: `version: '3.8'` is now obsolete in newer Docker Compose. It's fine to leave it, but be aware of the warning.
