# Full-Stack Application Deployment (Technical Test)

A fully containerized application deployed to AWS App Runner with a complete CI/CD pipeline, infrastructure-as-code (Terraform), and auto-scaling capabilities.

## Architecture Overview

*   **Frontend:** React (Vite) served via Nginx.
*   **Backend:** Node.js (Express) API.
*   **Infrastructure:** AWS App Runner (Serverless Containers) provisioned via Terraform.
*   **Container Registry:** AWS Elastic Container Registry (ECR).
*   **State Management:** Terraform state is securely managed remotely via an AWS S3 backend.
*   **CI/CD:** GitHub Actions automates building, tagging, and deploying zero-downtime updates.

### Public URLs
*   **Frontend UI:** `https://y2nhrtgr9z.eu-west-3.awsapprunner.com/`
*   **Backend API:** `https://jpk6h6z7ge.eu-west-3.awsapprunner.com/api/message`
*   **Health Check:** `https://jpk6h6z7ge.eu-west-3.awsapprunner.com/health`

---

## How to Run Locally

The project is fully containerized for a seamless local developer experience.

**Prerequisites:** Docker and Docker Compose.

1. Clone the repository.
2. Run the following command from the root directory:

    docker-compose up --build

3. Access the Frontend at `http://localhost:80`
4. Access the Backend at `http://localhost:8081`

---

## CI/CD & GitHub Workflows

This project utilizes two specialized GitHub Action workflows to manage the lifecycle of the infrastructure and the application code.

### 1. Infrastructure Management (`terraform-apply.yml`)
This workflow is triggered manually via **workflow_dispatch**. It allows engineers to provision or modify AWS resources without local CLI access.
*   **Dynamic Actions:** Provides a UI choice to run either a `terraform plan` (for impact analysis) or `terraform apply` (for execution).
*   **Secure State:** Authenticates with AWS to access the S3 Remote Backend, ensuring the infrastructure state is consistent across the team.

### 2. Automated Deployment Pipeline (`aws-deploy.yml`)
Triggered automatically on every **push to the main branch**. This pipeline handles the full build-to-deploy lifecycle:
*   **Infrastructure Discovery:** The pipeline initializes Terraform to dynamically fetch the Backend API URL from the remote state. This URL is injected into the Frontend build as a build argument (`VITE_API_URL`).
*   **Containerization:** It builds optimized Docker images for both services and pushes them to **AWS ECR**.
*   **Rolling Updates:** Once the new images are pushed, AWS App Runner detects the update and performs a rolling deployment, replacing instances only after health checks pass to ensure zero downtime.

---

## Key Technical Decisions

*   **AWS App Runner vs. ECS:** App Runner was selected for rapid delivery of a fully managed, auto-scaling service. However, following the 2026 deprecation notice, the roadmap includes a migration to **Amazon ECS Express Mode** for long-term support.
*   **Dynamic Decoupling:** By querying the Terraform state during the CI/CD build, the Frontend remains decoupled from the Backend's physical infrastructure. If the Backend moves to a different URL, the Frontend automatically updates during the next deployment.
*   **S3 Remote Backend:** Moving `terraform.tfstate` to S3 prevents state loss (as GitHub Action runners are ephemeral) and enables team collaboration.

---

## System Behavior Under Load

To demonstrate the system's auto-scaling capabilities, an aggressive load test was executed using **k6** to breach the AWS App Runner concurrency threshold (`max_concurrency = 20`).

**Scenario:** 
The test utilized **200 Virtual Users (VUs)** with zero sleep delay, hammering the `/health` endpoint to stack TCP connections and trigger a scale-out.

**Results & Analysis:**
*   **Throughput:** The system processed **1,308,964 requests** at a sustained rate of ~5,000 requests per second.
*   **Latency:** Median response time was held at a remarkable **19.2ms**.
*   **Scalability:** As the load increased, AWS App Runner successfully provisioned additional capacity, scaling from 1 instance to **4 active instances**.

![K6 Load Test Results](./load-test/k6_results.png)
![Request Count Spike](./load-test/request_count.png)
![Active Instances Scaling](./load-test/active_instances.png)

### How to Reproduce the Load Test

1. Ensure your backend URL is set in `load-test/script.js`.
2. Run the test via Docker:

**On Mac/Linux:**

    docker run --rm -i grafana/k6 run - < load-test/script.js

**On Windows (PowerShell):**

    Get-Content load-test\script.js | docker run --rm -i grafana/k6 run -

---

## Known Limitations and Possible Improvements

1.  **Migration to ECS:** Transitioning infrastructure to ECS Fargate for long-term AWS support.
2.  **Database Integration:** Implementing an RDS or DynamoDB instance via Terraform for persistent data storage.
3.  **Security Hardening:** Integrating AWS WAF and rate-limiting at the App Runner level to mitigate the minor failure rate seen during extreme 5,000 RPS surges.
