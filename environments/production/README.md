# JioMart Infrastructure Architecture — Production Environment

This directory houses the root Terraform orchestration for the live, customer-facing **JioMart Retail Microservices Platform** production (`prod`) environment. The architecture is built for strict zero-downtime resiliency, full multi-AZ fault tolerance, and absolute network isolation.

---

## 🏗️ Production Architecture Topology

The production ecosystem occupies the primary `10.0.0.0/16` CIDR block segment, enforcing absolute data-plane isolation from both lower environments (`dev` and `staging`).


```

```
                          ┌─────────────────────────────────────────────────────────┐
                          │                 VPC (10.0.0.0/16)                       │
                          │                                                         │

```

┌──────────┐               │  ┌──────────────┐    ┌──────────────┐    ┌───────────┐  │
│ CI/CD    │               │  │ Public Layer │    │ Private Layer│    │ DB Layer  │  │
│ Pipeline │ ─────────────┼─>│ (3x Dedicated│ ──>│ (3x Nodes in │ ──>│ (Multi-AZ │  │
└──────────┘               │  │  NAT GWs)    │    │ Multi-AZ ARs)│    │ MySQL HA) │  │
│  └──────────────┘    └──────────────┘    └───────────┘  │
└─────────────────────────────────────────────────────────┘

```

### 1. Highly Available Network Backbone (`modules/vpc`)
* Spans three distinct Availability Zones (`ap-south-1a`, `ap-south-1b`, and `ap-south-1c`).
* Provisions three dedicated, redundant **NAT Gateways** (`is_production = true`). A failure in a single AWS availability zone will not cause network or egress degradation for the remaining application layers.

### 2. Synchronous State Management Layer (`modules/rds`)
* Deploys a high-performance **MySQL 8.0** database cluster configured with **Multi-AZ synchronous replication** (`multi_az = true`). 
* In the event of an infrastructure or primary storage outage, AWS automatically flips operations to the hot standby secondary replica in a separate AZ with zero data loss and automated DNS failover routing.

### 3. Hardened Production Compute Plane (`modules/eks`)
* **Control Plane Module:** Provisions the master EKS API endpoints. Public internet-facing access configurations match operational compliance requirements, while preventing admin API credential lockouts.
* **Decoupled Data Plane Submodule:** Manages a baseline of **3 container-optimized `BOTTLEROCKET_x86_64` instances** running on **On-Demand `t3.medium` instances** to ensure maximum lifecycle compute stability and avoid unexpected Spot instance termination events.

---

## 🚨 Critical Engineering Controls (The CoreDNS Deadlock Solution)

To prevent resource creation failures during pipeline runs, our child module configuration utilizes strict dependency rules inside the EKS cluster `cluster_addons` block:

1. **`vpc-cni` (`before_compute = true`)**: Installs the native Amazon VPC container network interface plugin directly onto the control plane master nodes *before* the EC2 worker instances boot. This guarantees that when Bottlerocket nodes launch, they can immediately claim and assign private IP addresses to application workloads.
2. **`coredns` (`before_compute = false`)**: Since CoreDNS runs as an internal application container pod, setting this parameter to `false` instructs Terraform: *"Deploy the rest of the node groups first; do not hang up validation waiting for CoreDNS pods to report healthy until there is live EC2 compute infrastructure available to host them."*

---

## 🛠️ Step-by-Step Production Change Management Playbook

To minimize risk and comply with enterprise change management standards, **never execute a direct or targeted `terraform apply` on raw files in the production directory.** Always utilize a plan-driven, audited execution loop.

### 💻 Windows PowerShell Syntax Reminder
PowerShell natively evaluates unquoted bracket variables like `this["vpc-cni"]` incorrectly. Always wrap variable-targeting components inside **explicit double quotes** when interacting with state configurations.

### Step 1: Initialize the Production Context
Pull all downstream submodules and lock production-grade provider binary configurations:
```powershell
terraform init

```

### Step 2: Validate Code Composition

Ensure variable forwarding and backend module parameters parse cleanly without structural compilation blocks:

```powershell
terraform validate

```

### Step 3: Generate the Audited Execution Plan

Generate an immutable, binary plan file and output it locally. This allows you to inspect exactly what changes will take place before a single API call is sent to AWS:

```powershell
terraform plan -out=prod.tfplan

```

*Carefully audit the generated plan summary. Verify that it says exactly what resources are being added or changed, ensuring zero unexpected destructions.*

### Step 4: Execute the Audited Change Plan

Apply the exact inspected plan file file. This guarantees that Terraform will execute only what you approved in Step 3, with zero live deviation:

```powershell
terraform apply "prod.tfplan"

```

---

## 🔍 Post-Deployment Cluster Verification

Once the final convergence layer concludes, execute this tracking checklist from your workstation to audit production connectivity:

```powershell
# 1. Capture the new production context authentication signatures securely
aws eks update-kubeconfig --name jiomart-prod-cluster --region ap-south-1

# 2. Confirm worker nodes successfully registered and are balanced across all three AZs
kubectl get nodes -o wide

# 3. Check that the core networking daemonsets are running cleanly
kubectl get pods -n kube-system

```

---

## 🧹 Emergency Infrastructure De-Provisioning

To execute a complete de-provisioning cleanup loop for the production segment, execute this teardown sequence:

```powershell
# 1. Execute a complete teardown of all tracked cloud resources
terraform destroy

# 2. Wipe the automated AWS safety-guarded diagnostic cluster log streams
aws logs delete-log-group --log-group-name "/aws/eks/jiomart-prod-cluster/cluster" --region ap-south-1

# 3. Confirm the local state files read as a completely blank tracking sheet
terraform state list
terraform show

# 4. Deep-clean local module caching engines and variable configurations safely
Remove-Item -Recurse -Force .terraform/
Remove-Item -Force .terraform.lock.hcl
Remove-Item -Force terraform.tfstate*

```

