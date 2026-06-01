# JioMart Infrastructure Architecture — Development Environment

This directory houses the root Terraform orchestration for the **JioMart Retail Microservices Platform** development (`dev`) environment. The architecture is modularized, completely isolated via local state, and utilizes highly secure, minimal container-optimized Bottlerocket nodes.

---

## 🏗️ Architecture Blueprint

The infrastructure is provisioned sequentially across four decoupled operational phases to guarantee a clean dependency lifecycle:


```

[Phase 1: VPC Network] ──> [Phase 2: RDS Database] ──> [Phase 3: EKS Control Plane] ──> [Phase 4: Node Groups & Addons]

```

1. **Network Layer (`modules/vpc`)**: Establishes a multi-AZ VPC with public, private, and database-isolated subnet layers. Computes internet access out via a single cost-effective NAT Gateway.
2. **Database Layer (`modules/rds`)**: Deploys an isolated multi-AZ PostgreSQL database instance restricted explicitly via firewall ingress rules to EKS node traffic.
3. **EKS Control Plane (`modules/eks`)**: Deploys the Kubernetes master API engine, configures administrative API access entries, and registers the secure OpenID Connect (OIDC) identity provider federation.
4. **Data Plane & Add-ons**: Mounts managed worker node instances utilizing the `BOTTLEROCKET_x86_64` AMI and initializes core system daemonsets (`vpc-cni`, `kube-proxy`, `coredns`).

---

## 🚨 Critical Engineering Controls & Catch-22 Fixes

During the structural rollout of this infrastructure, several hidden dependencies and platform bugs were successfully engineered out of the codebase:

### 1. The EKS Node Group Lifecycle Hook (VPC-CNI Catch-22)
* **The Problem:** Managed Node Groups require a functional network plugin to perform their health check handshake with the Kubernetes control plane. However, default cluster add-ons try to install concurrently with the nodes. This creates a deadlock where Bottlerocket nodes boot up with `cni plugin not initialized`, hanging the Terraform apply for over 26 minutes until a timeout failure occurs.
* **The Solution:** The worker node components have been split into a decoupled module (`module.eks_managed_node_group`). The `cluster_addons` block configurations are explicitly forced to provision **before** the node infrastructure boots up:
  * `vpc-cni`: `before_compute = true` (Must be ready before instances boot).
  * `kube-proxy`: `before_compute = true`.
  * `coredns`: `before_compute = false` (Requires live nodes to host its scheduling pods).

### 2. Mandatory Cluster Access Entries
In EKS v20.x, the AWS API completely decoupled local IAM principals from administrative permissions. To prevent an immediate `Your IAM principal doesn't have access` lockout error upon creation, the control plane enforces:
```hcl
enable_cluster_creator_admin_permissions = true

```

### 3. Missing `cluster_service_cidr` Precondition

Extracting the managed node groups into a standalone standalone submodule breaks implicit state sharing. Bottlerocket user-data generation will fail validation unless the cluster internal service CIDR block range is explicitly forwarded output-to-input:

```hcl
cluster_service_cidr = module.eks.cluster_service_cidr

```

### 4. Local Kubectl Endpoint Traps

By default, enabling both public and private endpoint access routes local client lookups directly into private VPC network block spaces (`10.x.x.x` IPs), resulting in `dial tcp ... i/o timeout` errors. For local development engineering, access parameters are explicitly mapped to bypass internal subnets:

```hcl
cluster_endpoint_public_access  = true
cluster_endpoint_private_access = false

```

---

## 🛠️ Operational Execution Playbook

Due to the native multi-phase configuration paths, **do not run a raw global `terraform apply` on an empty account.** Execute deployment sequentially using explicit resource targeting strings wrapped properly to prevent terminal parsing errors.

### 💻 Windows PowerShell Syntax Warnings

PowerShell natively interprets the dot operator (`.`) inside expressions as method invocation flags. **You must wrap all module target flags in quotes** or use standard spacing to prevent string slicing errors.

### Phase 1: Provision the Foundations (Network)

```powershell
terraform apply -target="module.vpc"

```

*Verify that private routing tables cleanly register egress mapping to the target NAT Gateway instance.*

### Phase 2: Provision the State Engines (Database)

```powershell
terraform apply -target="module.auth_db"

```

### Phase 3: Provision the Master Plane & Core Networking Add-ons

```powershell
terraform apply -target="module.eks.module.eks"

```

*This handles the master architecture, registers policies, and provisions the `vpc-cni` daemonset.*

### Phase 4: Attach Compute Groups & Converge Everything

```powershell
terraform apply

```

*This attaches the Bottlerocket compute instances. They will discover the active CNI driver immediately and transition to a clean, healthy `Ready` state within 3 minutes.*

---

## 🛑 Post-Deployment Cluster Verification

Once the final convergence layer concludes, execute this tracking checklist to audit the health of your data plane:

```powershell
# 1. Update local client context credentials
aws eks update-kubeconfig --name jiomart-dev-cluster --region ap-south-1

# 2. Confirm worker nodes successfully registered on their own
kubectl get nodes

# 3. Check that the networking ecosystem is healthy
kubectl get pods -n kube-system

```

---

## 🧹 Complete Infrastructure De-Provisioning

To ensure your AWS account remains completely clear and to avoid orphaned asset billing, follow this teardown loop precisely:

```powershell
# 1. Reverse provision all managed assets
terraform destroy

# 2. Manually purge protected control plane log groups left behind by design
aws logs delete-log-group --log-group-name "/aws/eks/jiomart-dev-cluster/cluster" --region ap-south-1

# 3. Verify state transparency (Should return 'The state file is empty')
terraform show

# 4. Wipe local folder caches and state tracking systems securely
Remove-Item -Recurse -Force .terraform/
Remove-Item -Force .terraform.lock.hcl
Remove-Item -Force terraform.tfstate*

```
