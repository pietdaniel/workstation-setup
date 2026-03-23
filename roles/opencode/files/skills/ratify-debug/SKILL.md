---
name: ratify-debug
description: "Debug Ratify/Gatekeeper admission webhook denials blocking pod deployments. Use when pods fail to create with 'validation.gatekeeper.sh' denied errors, ROKT_FAILED_VULNERABILITY_VERIFICATION, ROKT_MISSING_VERIFIER_REPORT, or other Ratify codes. Covers kubectl diagnostics, Datadog log queries, error code interpretation, and remediation steps."
---

# Ratify / Gatekeeper Admission Webhook Debugging

## Overview

Ratify is a supply-chain security tool that verifies container images before they are admitted to Kubernetes clusters. It is enforced via OPA Gatekeeper admission webhooks. When an image fails verification, pods cannot be created and the ReplicaSet will show `FailedCreate` events.

The ROKT SAST system scans images after they are pushed to ECR, generating SBOM and vulnerability reports that are attached as OCI artifacts. Ratify then checks these artifacts at admission time.

---

## Step 1: Identify the Ratify Denial via kubectl

When a deployment or Argo Rollout is stuck with 0 running pods, first check for admission webhook denials.

### 1a. Check ReplicaSet events

```bash
# List ReplicaSets to find the stuck one (DESIRED > 0, CURRENT = 0)
kubectl get rs -n <namespace> --context <context> -o wide

# Describe the failing ReplicaSet for FailedCreate events
kubectl describe rs <replicaset-name> -n <namespace> --context <context>
```

Look for events like:
```
Warning  FailedCreate  replicaset-controller  Error creating: admission webhook "validation.gatekeeper.sh" denied the request: [ratify-constraint-notallowlist200] rokt_ratify_deny_code: <CODE>. subject: <image>. <reason>
```

Extract:
- **rokt_ratify_deny_code** - the Ratify error code (see Step 3)
- **subject** - the full image URI being blocked
- **reason** - human-readable explanation

### 1b. Check Kubernetes events directly

```bash
# Get FailedCreate events in the namespace
kubectl get events -n <namespace> --context <context> --field-selector reason=FailedCreate --sort-by='.lastTimestamp'
```

### 1c. For Argo Rollouts

```bash
# Describe the rollout - check Status.Conditions for ReplicaFailure
kubectl describe rollout <name> -n <namespace> --context <context>
```

The rollout Status will show:
- `Phase: Degraded`
- `Type: ReplicaFailure` with the Ratify denial message
- `Reason: ProgressDeadlineExceeded` if it has been failing long enough

### 1d. For Helm deployments

If using `helm --atomic`, the deployment will timeout without clear errors. While helm is waiting, describe the underlying Deployment/ReplicaSet directly to find the Ratify denial.

---

## Step 2: Check Datadog Logs for Gatekeeper & Ratify Details

### 2a. Check Gatekeeper violation logs

Search Datadog for Gatekeeper constraint violations to confirm the denial and determine if it is `deny` (actively blocking) or `dry-run` (monitoring only):

```
service:gatekeeper @constraint_kind:*RatifyVerification* @event_type:violation @resource_namespace:<namespace> kube_cluster_name:<cluster_name>
```

Key fields in these logs:
- `@constraint_action`: `deny` = actively blocking; `dry-run` = monitoring only, not blocking
- `@constraint_kind`: The specific Ratify constraint being evaluated

### 2b. Check Ratify verification logs

To see the detailed vulnerability/SBOM analysis results:

```
service:ratify "verify result for subject" kube_cluster_name:<cluster_name>
```

Narrow results by adding the image name (the `subject`). Filtering by namespace is NOT supported in Ratify logs - use the subject/image name instead.

### 2c. Determine the cluster name

Map the kubectl context to a cluster name for Datadog queries:
- `arn:aws:eks:<region>:<account>:cluster/<cluster-name>` → use `<cluster-name>` (e.g., `stage-eks`, `prod-eks`)

---

## Step 3: Interpret the Ratify Error Code

### ROKT_FAILED_VULNERABILITY_VERIFICATION

**Meaning:** The image contains packages/software with vulnerabilities that exceed the allowed severity threshold.

**What is blocked:**
- Severity: **CRITICAL**
- Specific CVE: **CVE-2021-44228** (Log4Shell)
- See the full block list at: `ROKT/policies-k8s/docs/ratify/ratify_block_list.md`

**Currently exempted vulnerabilities:**
- SNYK-DEBIAN12-ZLIB-6008963
- SNYK-DEBIAN11-ZLIB-6008961

**Resolution:**
1. Check the Ratify logs in Datadog (Step 2b) to identify the exact CVEs detected
2. Update the base image to the latest patch version (e.g., `alpine:3.20` → `alpine:3.21`)
3. Update application dependencies (`go mod tidy`, `npm update`, etc.)
4. Remove unnecessary packages from the Dockerfile
5. Rebuild and redeploy the image
6. If the vulnerability is a false positive or acceptable risk, contact the ROKT Security Engineering team for an exemption

### ROKT_MISSING_VERIFIER_REPORT

**Meaning:** The image does not have SBOM and vulnerability reports attached as OCI artifacts in ECR. The ROKT SAST system generates these after image push.

**Resolution:**
1. **If the image was recently pushed:** Wait a few minutes for the SAST system to scan the image and attach reports, then retry the deployment
2. **If significant time has passed:** The SAST system may be malfunctioning - contact the Security Engineering team

### ROKT_MISSING_SBOM_REPORT

**Meaning:** The image is missing only the SBOM (Software Bill of Materials) report artifact.

**Resolution:** Same as ROKT_MISSING_VERIFIER_REPORT - wait for SAST processing or contact Security Engineering.

### ROKT_MISSING_VULNERABILITY_REPORT

**Meaning:** The image is missing only the vulnerability scan report artifact.

**Resolution:** Same as ROKT_MISSING_VERIFIER_REPORT - wait for SAST processing or contact Security Engineering.

### ROKT_FAILED_SBOM_VERIFICATION

**Meaning:** The image contains packages or software that are explicitly blocked by the ROKT security team (irrespective of vulnerability severity).

**Resolution:**
1. Check the blocked packages list at `ROKT/policies-k8s/docs/ratify/ratify_block_list.md`
2. Remove or replace the blocked package
3. If you need an exemption, contact the ROKT Security Engineering team

---

## Step 4: Fix the Image

### Common fixes for ROKT_FAILED_VULNERABILITY_VERIFICATION

1. **Update base image:**
   ```dockerfile
   # Before (outdated, may have CRITICAL CVEs)
   FROM alpine:3.20
   # After (latest stable)
   FROM alpine:3.21
   ```

2. **Update system packages in the image:**
   ```dockerfile
   RUN apk update && apk upgrade --no-cache
   ```

3. **Update application dependencies:**
   ```bash
   # Go
   go get -u ./... && go mod tidy
   # Node
   npm audit fix
   # Python
   pip install --upgrade <packages>
   ```

4. **Use multi-stage builds** to minimize runtime image surface area (only copy the compiled binary, not build tools).

5. **Rebuild and push** the image through CI, then trigger a new deployment.

### Common fixes for ROKT_MISSING_*_REPORT

1. Simply wait 2-5 minutes after the image is pushed to ECR for the SAST system to process it
2. Retry the deployment / trigger a new rollout
3. If reports never appear, escalate to Security Engineering

---

## Step 5: Verify the Fix

After rebuilding and redeploying:

```bash
# Check that pods are now running
kubectl get pods -n <namespace> --context <context>

# Check that the ReplicaSet has the correct number of replicas
kubectl get rs -n <namespace> --context <context> -o wide

# Verify no more FailedCreate events
kubectl get events -n <namespace> --context <context> --field-selector reason=FailedCreate --sort-by='.lastTimestamp'

# For Argo Rollouts, check the rollout status
kubectl describe rollout <name> -n <namespace> --context <context>
```

Also verify in Datadog that the Gatekeeper violations have stopped:
```
service:gatekeeper @constraint_kind:*RatifyVerification* @event_type:violation @resource_namespace:<namespace> kube_cluster_name:<cluster_name>
```

---

## Quick Reference: Full Debug Sequence

1. `kubectl get rs -n <ns> --context <ctx> -o wide` — find stuck ReplicaSet (DESIRED > CURRENT)
2. `kubectl describe rs <rs-name> -n <ns> --context <ctx>` — get Ratify error code and subject image
3. Datadog: `service:gatekeeper @constraint_kind:*RatifyVerification* @event_type:violation @resource_namespace:<ns> kube_cluster_name:<cluster>` — confirm deny vs dry-run
4. Datadog: `service:ratify "verify result for subject" kube_cluster_name:<cluster>` + filter by image name — get vulnerability details
5. Fix image (update base image, deps, remove blocked packages)
6. Rebuild, push, redeploy
7. Verify pods are running and Gatekeeper violations have stopped
