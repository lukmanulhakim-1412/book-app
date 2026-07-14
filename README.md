# Book Tracker App - DevOps Implementation

**Chosen Role:** DevOps & Infrastructure Engineer (Mid-Level)

## Overview

This repository contains the completed DevOps and Infrastructure assignment for the Cinte technical assessment. The objective was to design and implement a robust CI/CD pipeline, containerize the application, provision cloud infrastructure via code, and establish a monitoring stack.

## Architecture

```text
┌─────────────────┐       ┌─────────────────┐       ┌──────────────────────┐
│  Developer Push │ ────> │ GitHub Actions  │ ────> │ GitHub Container Reg │
└─────────────────┘       └─────────────────┘       └──────────────────────┘
                                                               │ (Pulls Images)
                                                               ▼
┌──────────────────────────────────────────────────────────────────────────┐
│ AWS EC2 (t3.small) / Ubuntu 24.04                                        │
│                                                                          │
│  ┌─────────────────────────┐         ┌───────────────────────────────┐   │
│  │     App Stack (Docker)  │         │   Monitoring Stack (Docker)   │   │
│  │                         │         │                               │   │
│  │  [ Nginx Proxy ] *:80   │         │  [ Grafana ] *:3000           │   │
│  │         │               │ <~~~~~> │         │                     │   │
│  │         ▼               │ metrics │         ▼                     │   │
│  │  [ Frontend ] *:8080    │         │  [ Prometheus ] *:9090        │   │
│  │  [ Backend ] *:5001     │         │  [ cAdvisor ] *:8081          │   │
│  │  [ PostgreSQL ] *:5432  │         │  [ Postgres Exporter ] *:9187 │   │
│  └─────────────────────────┘         └───────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────────┘
```

## Decisions & Notes

1. **Local vs Production Compose**: I separated `docker/book-app/docker-compose.local.yml` (builds from source for local dev/testing) and `docker/book-app/docker-compose.yml` (pulls pre-built images from GHCR for production).
2. **Monitoring Modularization**: Created a dedicated `docker/monitoring` folder with its own `docker-compose.yml` to keep the app stack lean and modular. Grafana is auto-provisioned with a default Container Metrics dashboard.
3. **SSM over SSH**: In the Terraform configuration, Port 22 is completely closed. Access to the EC2 instance is handled securely via AWS Systems Manager (SSM) Session Manager to adhere to security best practices.
4. **CI/CD Optimization**: The GitHub Actions pipeline utilizes GitHub's cache for Docker layers to significantly reduce build times and includes health checks before pushing the images.
5. **Security Scanning**: I integrated Trivy for container image scanning in the CI pipeline, but configured it to not block the build upon finding vulnerabilities. Resolving the actual application/OS vulnerabilities is outside the scope of my DevOps infrastructure responsibilities for this test.

## How to Run & Test

### 1. Provision Infrastructure (Terraform)
1. Ensure your AWS CLI is configured with the necessary permissions (`~/.aws/credentials`).
2. Navigate to the terraform directory:
   ```bash
   cd terraform
   terraform init
   terraform apply
   ```
3. Use the outputted Instance ID to securely connect via SSM:
   ```bash
   aws ssm start-session --target <instance-id>
   ```

### 2. Run the Application
*Note: You must have [Docker](https://docs.docker.com/engine/install/) or Podman installed on your host system before running these commands. Replace `podman-compose` with `docker compose` if you are using Docker.*
```bash
cd docker/book-app
podman-compose -f docker-compose.local.yml up -d --build
```
- **Frontend UI**: [http://localhost:8080](http://localhost:8080)
- **Backend API**: [http://localhost:5001/api/books](http://localhost:5001/api/books)

### 3. Run the Monitoring Stack
*The application stack must be running first so the monitoring tools can attach to the `book-app_app_network`.*
```bash
cd docker/monitoring
podman-compose up -d
```
- **Grafana**: [http://localhost:3000](http://localhost:3000) (Login: `admin` / `admin`)
- **Prometheus**: [http://localhost:9090](http://localhost:9090)

## Rollback Strategy

If a deployment fails or introduces a critical bug:
1. **Application Rollback**: Revert the commit in Git, or manually update the production `docker/book-app/docker-compose.yml` to pull a specific older image tag from GHCR instead of `latest`, then run `docker compose up -d` on the server.
2. **Infrastructure Rollback**: If a Terraform change causes issues, revert the `.tf` file changes in version control and run `terraform apply`. To completely destroy the environment: `terraform destroy`.

## Incident Response Runbook

### Scenario: High Memory Usage (OOM Kills)
**Alert**: Grafana shows container memory utilization hitting 100%.
**Triage**:
1. Open Grafana Dashboards -> "Container Metrics (cAdvisor)".
2. Identify the specific container consuming the most memory.
3. Check the application logs for memory leaks or large queries:
   ```bash
   docker logs book-app_backend_1 --tail 100
   ```
**Mitigation**:
1. If the container is stuck, manually restart it: `docker restart book-app_backend_1`.
2. If the application is genuinely resource-starved under high traffic, vertically scale the instance by updating the `t3.small` instance in `terraform/variables.tf` to `t3.medium`, and run `terraform apply`.

### Scenario: Service Down (Backend API Unreachable)
**Alert**: Frontend UI fails to load books, API returns 502/503.
**Triage**:
1. Check Prometheus target health at `http://localhost:9090/targets`. Is the backend target down?
2. Check if the container exited unexpectedly: `docker ps -a`.
**Mitigation**:
1. Ensure the PostgreSQL database is healthy (`docker logs book-app_database_1`). The backend depends on the database to start.
2. Restart the backend service: `docker compose -f docker-compose.yml restart backend`.

## Future Improvements (TODOs)

- **Environment Separation**: Implement strict separation of configuration via `.env` files for distinct environments (e.g., `development`, `staging`, `production`). Move all hardcoded variables out of the Compose configuration.
- **Secrets Management**: Integrate a secure secrets manager (such as AWS Secrets Manager, HashiCorp Vault, or Infisical) to inject database credentials and API keys dynamically at runtime, rather than storing them in plaintext.
- **Auto-Scaling & Load Balancing**: Update the Terraform infrastructure to use an Auto Scaling Group (ASG) behind an Application Load Balancer (ALB) to automatically scale the application based on traffic load.
- **Configuration Management**: Create Ansible playbooks to automatically install Docker, set up the initial server environment, and configure an Nginx reverse proxy on the EC2 instances.
