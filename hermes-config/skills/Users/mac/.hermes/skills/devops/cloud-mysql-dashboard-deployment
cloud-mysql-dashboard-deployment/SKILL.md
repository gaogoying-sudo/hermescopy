---
name: cloud-mysql-dashboard-deployment
category: devops
description: Deploy a lightweight data dashboard with remote MySQL sync on a shared cloud server using Docker Compose. Covers resource isolation, mysqldump troubleshooting, and API schema verification.
---

# Cloud MySQL Dashboard Deployment

**Use Case:** When user wants to deploy a data lookup dashboard on a shared cloud server, sync data from a remote MySQL (e.g., Tencent CDB), and ensure strict resource isolation so it doesn't disturb other projects.

---

## Core Architecture

```
/opt/[project-name]/
├── docker-compose.yml   # MySQL + FastAPI Backend + Nginx Frontend
├── .env                 # DB passwords, tokens
├── backend/
│   ├── main.py          # FastAPI, dynamic schema checks
│   ├── Dockerfile       # Python slim, tsinghua pip mirror
│   └── requirements.txt
├── frontend/
│   ├── index.html       # Vue/Bootstrap CDN, API calls
│   └── nginx.conf       # Static + /api/ proxy_pass
└── scripts/
    └── sync_clean.py    # Shell-piped mysqldump sync script
```

---

## Step-by-Step Workflow

### 1. SSH & Environment Prep
- **No Key Auth**: If user provides password, use `expect` or `sshpass` scripts for non-interactive SSH/SCP.
- **Directory**: `sudo mkdir -p /opt/[project-name] && sudo chown ubuntu:ubuntu /opt/[project-name]`
- **Port Check**: ALWAYS run `sudo netstat -tulpn` to find free ports. Shared servers often use 8080, 8081, 3306, 3307. Pick unused ones (e.g., 8085, 8086, 3308).

### 2. Docker Compose (Resource Limits)
**CRITICAL**: Shared servers will OOM or CPU-starve other projects if limits aren't set.
```yaml
deploy:
  resources:
    limits:
      cpus: '0.50'
      memory: 512M
    reservations:
      cpus: '0.25'
      memory: 256M
```
Apply limits to `mysql`, `api`, and `web` services.

### 3. MySQL Sync Script (Pitfall Heavy)
Remote dumps (TencentDB, Alibaba RDS) almost always fail with default `mysqldump`. Use these exact flags:
```bash
mysqldump -h [REMOTE_HOST] -P [PORT] -u [USER] -p'[PASS]' \
  --lock-tables=false \
  --no-tablespaces \
  --set-gtid-purged=OFF \
  [DB] [TABLE] 2>/dev/null | sudo docker exec -i [CONTAINER] mysql -u[P] -p[P] [LOCAL_DB]
```
- **GTID Error**: `--set-gtid-purged=OFF` fixes `partial dump from a server that has GTIDs` warnings/errors.
- **Lock Error**: `--lock-tables=false` fixes `Access denied... RELOAD privilege` on read-only users.
- **Tablespaces Error**: `--no-tablespaces` fixes access denied on general tablespaces.
- **Pipe Directly**: Do not save to local disk if possible. Pipe directly into `docker exec -i ... mysql`.

### 4. Backend API (Schema Verification)
Remote DB schemas change. Hardcoding columns causes `Unknown column` 500s.
- **Defensive Querying**: Run `SHOW COLUMNS FROM table` dynamically, OR handle exceptions gracefully.
- **JSON Serialization**: `cursorclass=pymysql.cursors.DictCursor` makes mapping to JSON trivial.

### 5. Deployment & Verification
1. `tar czf deploy.tar.gz deploy/`
2. `scp deploy.tar.gz user@ip:/opt/[project]/`
3. `ssh user@ip "cd /opt/[project] && tar xzf deploy.tar.gz --strip-components=1 && sudo docker compose up -d --build"`
4. **Verify MySQL**: `sudo docker exec [db_container] mysql ... -e 'SHOW TABLES'`
5. **Test API**: `curl -s http://localhost:[PORT]/api/search/[SN]`
6. **Check Logs**: `sudo docker logs [api_container] --tail 20`

---

## Common Pitfalls & Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `Can't connect to local MySQL server through socket` | Docker MySQL just restarted or is initializing | `sleep 5` after `docker restart`, or check `docker ps` |
| `Bind for 0.0.0.0:PORT failed: port is already allocated` | Another Docker project uses the port | Change port in `docker-compose.yml`, `docker compose down`, `up -d` |
| `Unknown column 'xxx' in 'field list'` | Remote DB schema updated, local cache old | Run `SHOW COLUMNS`, update API query, rebuild API container |
| `ERROR 1146: Table doesn't exist` | Sync failed silently or table wasn't dumped | Check `SHOW TABLES` inside Docker. Re-run sync for specific table. |
| `Internal Server Error` on curl | API Python exception (usually DB related) | Check `docker logs [api]`. Usually missing column or table. |

---

## Related Skills
- `cloud-shared-server-deployment` - General cloud deployment rules
- `clm-admin-dashboard-building` - Desktop dashboard patterns
