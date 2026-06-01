# JioMart Infrastructure Architecture — Staging Environment

This directory houses the root Terraform orchestration for the **JioMart Retail Microservices Platform** staging (`staging`) environment. The infrastructure is completely decoupled, handles live high-availability traffic patterns, and incorporates specialized sequencing rules to prevent data plane bootstrap deadlocks.

---

## 🏗️ Staging Architecture Topology

Unlike the development workspace, the staging environment is a mirrored production-lite ecosystem running on a isolated network segment (`10.20.0.0/16`) to guarantee zero IP or routing collisions with other stages.


```

```
              ┌─────────────────────────────────────────────────────────┐
              │                 VPC (10.20.0.0/16)                      │
              │                                                         │

```

┌──────────┐     │  ┌──────────────┐    ┌──────────────┐    ┌───────────┐  │
│ Deployer │ ───┼─>│ Public Layer │ ──>│ Private Layer│ ──>│ DB Layer  │  │
│ (Laptop) │     │  │ (HA NAT GWs) │    │ (Bottlerocket│    │ (Multi-AZ │  │
└──────────┘     │  └──────────────┘    │  EKS Nodes)  │    │  MySQL)   │  │
│                      └──────────────┘    └───────────┘  │
└─────────────────────────────────────────────────────────┘

```

### 1. High Availability Networking Layer (`modules/vpc`)
* Configures multi-AZ public, private, and database-isolated subnets.
* Deploys multiple highly available NAT Gateways across active availability zones (`is_production = true` via variables) to validate production-grade failover routing.

### 2. State Management Layer (`modules/rds`)
* Provisions a production-ready, multi-AZ **MySQL 8.0** cluster database (`jiomart_orders_staging`).
* Security-hardened to accept traffic exclusively on port `3306` tracking via the EKS worker node security group ID wrapper (`module.eks.node_security_group_id`).

### 3. Decoupled Compute & EKS Layer (`modules/eks`)
* **Control Plane Module:** Provisions the master cluster API, activates public-facing access endpoints for remote engineering control, and prevents local laptop lockouts using direct administrative authorization properties.
* **Standalone Compute Module:** Manages automated scaling actions for high-efficiency container-optimized `BOTTLEROCKET_x86_64` machine architectures on `t3.medium` instances.

---

## 🚨 Critical Engineering Controls (The CoreDNS Deadlock Solution)

During deployment configuration, a race condition naturally exists within EKS where add-ons fail or loop indefinitely because worker compute nodes do not yet exist or do not have working network layer interfaces. Staging resolves this using strict lifecycle parameters within `cluster_addons`:

1. **`vpc-cni` (`before_compute = true`)**: Forces Terraform to install the AWS native networking interface driver onto the control plane master layers *before* any compute instances boot. This allows new nodes to instantly pull private IP space allocations.
2. **`coredns` (`before_compute = false`)**: CoreDNS runs as an internal cluster application framework container pod. Setting this parameter to `false` instructs Terraform: *"Deploy the rest of the node groups first; do not hang up validation waiting for CoreDNS pods to report healthy until there is live EC2 compute infrastructure available to host them."*

---

## 🛠️ Step-by-Step Deployment Orchestration Playbook

To ensure the balanced code dependencies execute cleanly without state collision traps, follow this precise operational sequence in your Windows PowerShell console.

### ⚠️ Critical Windows PowerShell Formatting Guardrails
PowerShell evaluates unquoted bracket variables like `this["vpc-cni"]` or targeted strings incorrectly due to string-slicing rules. Always wrap variable-targeting components inside **explicit double quotes** as shown below.

### Step 1: Initialize Workspace Context
Pull all downstream submodules and lock provider binary configurations for the staging workspace:
```powershell
terraform init

```

### Step 2: Validate the Syntax Topology

Ensure variable forwarding and backend module parameters parse cleanly without structural compile blocks:

```powershell
terraform validate

```

### Step 3: Global Automation Execution (Recommended)

Because our add-on dependency graph is completely solved in the code files using `before_compute`, **do not use resource targeting (`-target`) flags for normal staging deployments.** Run a single global execution loop:

```powershell
terraform apply

```

*Terraform will automatically read the module dependencies, construct the VPC, spin up the MySQL staging engine, configure the EKS master plane, provision the network layer, deploy the worker nodes, and finally start CoreDNS seamlessly.*

---

## 🔍 Staging Verification Post-Assessment

Once your terminal outputs `Apply complete!`, execute these verification loops from your laptop terminal to audit cluster connectivity and routing health:

```powershell
# 1. Capture the new staging context authentication signatures
aws eks update-kubeconfig --name jiomart-staging-cluster --region ap-south-1

# 2. Verify that all staging Bottlerocket worker instances are registered and healthy
kubectl get nodes

# 3. Verify all cluster pods (aws-node, coredns, kube-proxy) transitioned to 'Running'
kubectl get pods -n kube-system

```

---

## 🧹 Clean Environment Teardown and Resource De-Provisioning

To execute a complete de-provisioning cleanup loop and prevent rogue charges for ongoing staging clusters, run this teardown flow directly from your root directory:

```powershell
# 1. Execute a complete teardown of all tracked cloud resources
terraform destroy

# 2. Wipe the automated AWS safety-guarded diagnostic cluster log streams
aws logs delete-log-group --log-group-name "/aws/eks/jiomart-staging-cluster/cluster" --region ap-south-1

# 3. Confirm the local state files read as a completely blank tracking sheet
terraform state list
terraform show

# 4. Deep-clean local module caching engines and variable configurations safely
Remove-Item -Recurse -Force .terraform/
Remove-Item -Force .terraform.lock.hcl
Remove-Item -Force terraform.tfstate*

```

