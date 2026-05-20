---
description: Use the `aws` CLI to query Rokt AWS environments. Always use `--profile`. Never run `aws sts get-caller-identity` or `aws configure list-profiles` first — assume the session is active. Load this skill whenever the task involves the AWS CLI, S3, EC2/VPC, IAM, CloudWatch, EKS, ELB, or any AWS resource lookup.
---

# Skill: aws-cli (Rokt)

## Rule 0: do not pre-probe auth

**Never run any of these "discovery" commands at the start of an AWS task:**

- `aws sts get-caller-identity`
- `aws configure list-profiles`
- `aws configure list`
- `aws sso login` (unless the user explicitly asked for it)

Assume the user has an active session. If a command fails with a credentials error, surface that one error to the user and ask which profile to use — do not preemptively probe.

## Rule 0a: auth failures — ask, don't fix

If you hit any auth error — `Token has expired and refresh failed`, `getting credentials: exec: executable aws failed with exit code 255`, `ExpiredToken`, `Unable to locate credentials`, kubectl `error: You must be logged in to the server (Unauthorized)`, or similar — **stop, surface the error, and ask the user to refresh their session**.

Do NOT:
- Run `aws sso login` yourself (it pops a browser flow you can't drive).
- Try alternate profiles hoping one works.
- Re-run the failed command in a loop.

Do say something like: *"AWS SSO session for `rokt-prod` looks expired — can you run `aws sso login --profile rokt-prod` (or your usual refresh) and let me know when it's good?"* Then wait. The user can fix it in seconds; you'll waste minutes guessing.

This applies equally to kubectl commands that depend on AWS auth (EKS clusters via `aws eks get-token`).

## Rule 1: always pass `--profile`

Every `aws` invocation must include `--profile <name>`. Common Rokt profiles:

- `rokt-prod` — production AWS account (`862031682474`)
- `rokt-stage` — staging AWS account (`940468149856`)
- `rokt-eng` — engineering tooling account (`035088524874`)
- `rokt-prod-breakglass` / `rokt-stage-breakglass` — elevated read/write
- Per-domain breakglass: `backup-{env}-breakglass`, `calendar-{env}-breakglass`, `log-{env}-breakglass`

Use `--profile rokt-prod` for prod investigations unless the user specifies otherwise.

## Rule 2: always pass `--region`

S3 bucket lookups, EC2 describes, etc. are region-scoped. The user's environment may default to a region that isn't where the resource lives. Common Rokt regions:

- `us-west-2` (hub region for most prod services)
- `us-east-1`
- `eu-west-1`
- `ap-southeast-2`

## Rule 3: be efficient

- Combine multiple AWS calls in a single message using parallel bash tool calls when they are independent.
- Use `--output json | jq` for any complex filtering. Default text output is hard to parse.
- Prefer `--query` (server-side JMESPath) over piping large JSON through jq when possible.
- For paged APIs, use `--max-items` (e.g., `--max-items 50`).

## Rule 4: prefer read-only

Default to describe/list/get. Never run `delete`, `terminate`, `put`, `update`, or `create` actions without explicit user confirmation in the current message.

## Common patterns

### S3
```bash
aws --profile rokt-prod --region us-west-2 s3api head-object \
  --bucket rokt-prod-us-west-2-transactions-external-data \
  --key geoip/GeoIP2-City.mmdb

aws --profile rokt-prod --region us-west-2 s3api get-bucket-policy \
  --bucket rokt-prod-us-west-2-transactions-external-data --output text | jq .

aws --profile rokt-prod --region us-west-2 s3 ls \
  s3://rokt-prod-us-west-2-transactions-external-data/geoip/ --human-readable
```

### VPC endpoints (S3 gateway endpoint health, route tables)
```bash
aws --profile rokt-prod --region us-west-2 ec2 describe-vpc-endpoints \
  --filters "Name=service-name,Values=com.amazonaws.us-west-2.s3" \
  --query 'VpcEndpoints[].{Id:VpcEndpointId,State:State,Type:VpcEndpointType,VpcId:VpcId,RouteTableIds:RouteTableIds}' \
  --output table
```

### EC2 / node lookups
```bash
aws --profile rokt-prod --region us-west-2 ec2 describe-instances \
  --instance-ids i-0e0aab818e5d0f2ba \
  --query 'Reservations[].Instances[].{Id:InstanceId,AZ:Placement.AvailabilityZone,State:State.Name,SubnetId:SubnetId,LaunchTime:LaunchTime,InstanceType:InstanceType}' \
  --output table
```

### CloudWatch metrics (network errors, dropped packets, NAT bytes)
```bash
aws --profile rokt-prod --region us-west-2 cloudwatch get-metric-statistics \
  --namespace AWS/NATGateway \
  --metric-name ErrorPortAllocation \
  --start-time 2026-05-11T14:00:00Z --end-time 2026-05-11T19:00:00Z \
  --period 300 --statistics Sum
```

### IAM (role / policy inspection)
```bash
aws --profile rokt-prod iam get-role --role-name <name>
aws --profile rokt-prod iam list-attached-role-policies --role-name <name>
aws --profile rokt-prod iam get-policy-version --policy-arn <arn> --version-id v1
```

### CloudTrail (recent API calls — useful for "did someone change this bucket policy?")
```bash
aws --profile rokt-prod --region us-west-2 cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=rokt-prod-us-west-2-transactions-external-data \
  --start-time 2026-05-11T13:00:00Z --max-items 20 \
  --query 'Events[].{Time:EventTime,Event:EventName,User:Username,Source:EventSource}' \
  --output table
```

### EKS
```bash
aws --profile rokt-prod --region us-west-2 eks describe-cluster --name prod-eks \
  --query 'cluster.{Status:status,Version:version,Endpoint:endpoint,VPC:resourcesVpcConfig.vpcId}'
```

## Quick chain for incident-style S3-from-pod issues

When asked "why is service X failing to reach S3?", run in parallel:

```bash
# 1. Bucket policy
aws --profile rokt-prod --region <region> s3api get-bucket-policy --bucket <name>
# 2. S3 gateway endpoint state + route tables
aws --profile rokt-prod --region <region> ec2 describe-vpc-endpoints --filters "Name=service-name,Values=com.amazonaws.<region>.s3"
# 3. Recent bucket policy / endpoint mutations
aws --profile rokt-prod --region <region> cloudtrail lookup-events --lookup-attributes AttributeKey=ResourceName,AttributeValue=<bucket-or-vpce>
# 4. Object actually exists and is readable
aws --profile rokt-prod --region <region> s3api head-object --bucket <name> --key <key>
```

Then cross-reference with Datadog logs/spans + kubectl pod status.
