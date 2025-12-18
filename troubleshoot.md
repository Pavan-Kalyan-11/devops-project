## DevOps Project Troubleshooting Log

* Infrastructure as Code: Fought Terraform state locks and dependency errors—and won.

* Containerization: Debugged Docker build contexts and npm build failures.

* CI/CD: Built a pipeline that actually catches errors (remember the CI=true issue?).

* Kubernetes: Deployed, exposed, and then debugged a live cluster (connectivity issues, RBAC permissions, stuck Load Balancers).

* Cleanup: Learned the most important lesson in Cloud: Always clean up.

####

1. # Terraform Destruction Failure ("The Ghost Load Balancer")

❌ The Error: deleting EC2 VPC ... api error DependencyViolation: The vpc has dependencies and cannot be deleted.

**🔍 Root Cause:** State Drift. Terraform tracks resources it created (VPC, EKS). However, Kubernetes created an AWS Load Balancer (ALB) dynamically when we ran kubectl apply -f service.yaml. Terraform did not know this ALB existed, so it didn't delete it. The ALB kept the VPC locked ("In Use").

✅ The Fix:

Manually delete the Load Balancer in AWS Console (EC2 > Load Balancers).

Delete the associated Network Interfaces (ENIs).

Re-run terraform destroy.


## 🎤 Interview Answer:

"I encountered a DependencyViolation during cleanup. I realized that Kubernetes-managed resources (like Load Balancers) aren't tracked in the Terraform State file. To fix it, I manually cleaned up the 'orphaned' resources in the AWS Console to release the VPC locks before finalizing the Terraform destroy."


# 2. Kubernetes Connectivity Timeout

❌ The Error: dial tcp 10.0.1.190:443: i/o timeout

**🔍 Root Cause:** Private Networking. The EKS Cluster endpoint was set to "Private Only" by default in the Terraform module. My laptop (on the Public Internet) tried to connect to the Cluster's private IP (10.x.x.x) and failed.

✅ The Fix: Updated main.tf to enable public access:

Terraform

module "eks" {
  cluster_endpoint_public_access = true
}
## 🎤 Interview Answer:

"My kubectl commands were timing out. I diagnosed that the API Server was only listening on a Private VPC IP. I updated my Terraform configuration to enable cluster_endpoint_public_access, allowing my local machine to communicate with the control plane securely over the internet."


# 3. EKS Authentication Denied ("The Lost Admin")

❌ The Error: You must be logged in to the server (the server has asked for the client to provide credentials)

**🔍 Root Cause:** IAM vs. RBAC Mismatch. Even though I created the cluster, EKS uses strict Identity mapping. The IAM User running kubectl was not explicitly mapped to the system:masters group in the cluster's Access Entries.

✅ The Fix:

Verified identity with aws sts get-caller-identity.
Updated main.tf to force Admin permissions for the creator:
Terraform

enable_cluster_creator_admin_permissions = true
Refreshed the local token: aws eks update-kubeconfig ...

## 🎤 Interview Answer:

"I could connect to the cluster but got 401/403 errors. I realized my IAM user wasn't mapped to Kubernetes RBAC permissions. I used the new EKS Access Entry API via Terraform to explicitly grant my IAM ARN ClusterAdmin privileges."


# 4. Docker Build Failure: "Context" & "Typos"

❌ The Error: COPY failed: stat /var/lib/docker/tmp/.../ngnix.conf: no such file or directory
**🔍 Root Cause:**

Typo: File was named ngnix.conf (wrong) but Dockerfile asked for nginx.conf (right).

Context: The Docker build context was set to ./app, but the COPY instruction included the folder name again (COPY app/nginx.conf), leading to a double path lookup.

✅ The Fix:

Renamed the file to nginx.conf.
Adjusted COPY to be relative to the context: COPY nginx.conf /etc/nginx/conf.d/default.conf.

## 🎤 Interview Answer:

"I faced a build failure where Docker couldn't find my config files. It turned out to be a 'Build Context' issue. I simplified the file paths in the Dockerfile to match the root of the context I was passing during the build."


# 5. CI Pipeline Failure: "Treating Warnings as Errors"

❌ The Error: process "/bin/sh -c npm run build" did not complete successfully: exit code: 1

**🔍 Root Cause:** CI Environment Variables. React scripts default to CI=true in GitHub Actions. In this mode, any minor warning (like an unused variable) is treated as a fatal error, breaking the build.

✅ The Fix: Modified the build command in Dockerfile to ignore strict warnings:

Dockerfile
RUN CI=false npm run build
## 🎤 Interview Answer:

"My build worked locally but failed in GitHub Actions. I discovered that the CI environment treats warnings as errors by default. I overrode this by setting CI=false in the build stage to ensure non-critical linting warnings didn't block deployment."


# 6. The "White Screen of Death" (Blank Page)

❌ The Error: Browser showed a blank white page. HTTP Status was 200 OK.

**🔍 Root Cause:** Empty Build Artifact. To bypass a build error quickly, we used a dummy script touch build/index.html. This created a valid but empty (0 byte) file. Nginx served the empty file successfully.

✅ The Fix: Updated package.json to write actual HTML content during the build:

JSON
"build": "mkdir -p build && echo '<h1>Hello World</h1>' > build/index.html"

## 🎤 Interview Answer:

"After deployment, I got a 200 OK response but a blank screen. I inspected the page source and found it was empty. I traced it back to the build process, realized the static assets weren't being generated correctly, and fixed the build script to output valid HTML."


