# cloud-terraform
# *Cloud Security and Automation Using Terraform on Google Cloud Storage*

This project showcases the automation of managing a static website hosted on Google Cloud Storage (GCS) using Terraform. While the GCS bucket was created manually, Terraform was employed to automate key aspects of infrastructure management, such as access controls, security policies, and the provisioning of website configurations. This setup demonstrates the integration of cloud automation, security best practices, and vulnerability management using common industry tools like Terraform and OWASP ZAP for vulnerability scanning.

## *Project Overview*

Objective: Automate the configuration and management of a static website hosted on Google Cloud Storage using Terraform, with an emphasis on security best practices and performing vulnerability assessments.

Scope:

	•	Automation: Use Terraform for managing and automating specific configuration tasks such as security policies and access control on an existing GCS bucket.
	•	Security: Implement security controls and manage IAM roles to ensure the least-privilege access.
	•	Vulnerability Management: Perform vulnerability assessments using OWASP ZAP.

## *Architecture Overview*

Components:

	•	Google Cloud Storage (GCS): Manually created and hosts the static website.
	•	Terraform: Automates the management of the GCS bucket configuration, access policies, and security measures.
	•	Google Cloud IAM: Provides role-based access control to GCS resources.
	•	Vulnerability Scanning: Conducted using OWASP ZAP.

*Architecture Diagram*:
![Architecture Diagram](screenshot\architecture.jpg) <!-- Replace with actual path to the diagram image -->

## *Project Breakdown*

Step 1: Google Cloud Storage Setup (Manual)

	1. *Create a Google Cloud Project*: Enable the Google Cloud Storage API.
*Service Account*: Set up a service account with the necessary permissions.
   - [How to Create a Service Account](https://cloud.google.com/iam/docs/creating-managing-service-accounts) <!-- Link to official Google Cloud documentation -->
	2.	Create a GCS Bucket:
	•	Navigate to the GCS section in the Google Cloud Console and manually create a bucket.
	•	Enable the website configuration by specifying the index.html as the main page.
	•	Ensure public access is enabled for serving static website content

![bucket](C:\Users\BlackAngel\Desktop\terraform\screenshot\simplllllebucket.jpg) <!-- Replace with actual path to the diagram image -->
![bucket](screenshot\simplebucket.jpg) <!-- Replace with actual path to the diagram image -->
![bucetupload](screenshot\simplbucketupload.jpg) <!-- Replace with actual path to the diagram image -->


  




## Step 2: Automating Configuration Using Terraform

Although the GCS bucket was created manually, Terraform is used for automating the following configurations:

	•	Managing IAM roles and access controls for the bucket.
	•	Enforcing security policies such as lifecycle rules, versioning, and public access prevention for sensitive resources.
	•	Configuring the bucket for static website hosting.

*Terraform Configuration *:
# Declare variables for GCP credentials, project ID, and region
variable "GOOGLE_APPLICATION_CREDENTIALS" {
  description = "Path to the service account key file"
  type        = string
}

variable "GCP_PROJECT_ID" {
  description = "Google Cloud project ID"
  type        = string
}

variable "GCP_REGION" {
  description = "Google Cloud region"
  type        = string
}

# Define the Google Cloud provider
provider "google" {
  credentials = file(var.GOOGLE_APPLICATION_CREDENTIALS)
  project     = var.GCP_PROJECT_ID
  region      = var.GCP_REGION
}

# Reference an existing GCS bucket (replace with your bucket name)
data "google_storage_bucket" "existing_bucket" {
  name = "simplllle-bucket"
}

# IAM member to allow public access to the bucket
resource "google_storage_bucket_iam_member" "public_access" {
  bucket = data.google_storage_bucket.existing_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Backend bucket pointing to the existing GCS bucket for CDN integration
resource "google_compute_backend_bucket" "website_backend" {
  name        = "website-backend-bucket"
  bucket_name = data.google_storage_bucket.existing_bucket.name
  enable_cdn  = true # Enable Cloud CDN
}

# URL map for routing requests to the backend bucket
resource "google_compute_url_map" "website_url_map" {
  name            = "website-url-map"
  default_service = google_compute_backend_bucket.website_backend.id
}

# Target HTTP proxy to handle requests
resource "google_compute_target_http_proxy" "website_http_proxy" {
  name    = "website-http-proxy"
  url_map = google_compute_url_map.website_url_map.id
}

# Global forwarding rule for handling HTTP traffic (can be modified to HTTPS)
resource "google_compute_global_forwarding_rule" "website_forwarding_rule" {
  name       = "website-forwarding-rule"
  target     = google_compute_target_http_proxy.website_http_proxy.id
  port_range = "80"
  ip_protocol = "TCP"
}

# Output the website URL using Cloud CDN and Load Balancer's global IP
output "cdn_website_url" {
  value = "http://${google_compute_global_forwarding_rule.website_forwarding_rule.ip_address}"
}


*Commands Executed*:
- terraform init: Initializes the Terraform project.
- terraform apply: Deploys the infrastructure as defined in main.tf.

*Deployment Results*:
bash
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:
website_url = "https://storage.googleapis.com/my-static-website-bucket/index.html"


*Terraform Configuration Screenshot*:
![Terraform Configuration](screenshot\terraform-config.jpg) <!-- Replace with actual path to the
![Terraform Configuration](screenshot\terraforminit.jpg)<!-- Replace with actual screenshot -->
![Terraform Apply](screenshot\terraformapply.jpg) <!-- Replace with actual screenshot -->


### *Step 3: IAM Role Configuration*

- *IAM Roles and Permissions*: Configured to follow the principle of least privilege.

*IAM Roles Diagram*:
![IAM Roles Diagram](screenshot\terraformiamroles.jpg)<!-- Replace with actual path to the diagram image -->

### *Step 4: Vulnerability Scanning*

*Tool Used: **OWASP ZAP*

*Key Findings*:
- Absence of Anti-CSRF Tokens
- CSP Wildcard Directive
- Missing Anti-Clickjacking Header
- X-Frame Options Defined via Meta
- Cross-Domain JavaScript Source File Inclusion
- X-Content-Type Options Header Missing

*Vulnerability Scan Report:
![Vulnerability Scan Report](https://drive.google.com/file/d/1tGEdCdAfsiOU2Ft-JTIR-SAOHV_1PZGP/view?usp=drivesdk) <!-- Replace with actual screenshot -->

Mitigation Strategies

1. Absence of Anti-CSRF Tokens

Vulnerability: Cross-Site Request Forgery (CSRF) attacks exploit the trust a web application has in the user’s browser, allowing attackers to perform actions on behalf of authenticated users.

Mitigation:

	•	Implement CSRF Tokens: Generate a unique token for each user session and include it in requests to validate their authenticity. This token should be included in all forms and validated on the server side.
	•	Use Frameworks and Libraries: Many modern web frameworks (e.g., Angular, React) include built-in mechanisms for handling CSRF protection. Ensure these are configured properly in your application.

Further Reading: OWASP CSRF Prevention Cheat Sheet

2. CSP Wildcard Directive

Vulnerability: A Content Security Policy (CSP) wildcard directive (e.g., default-src *) can be exploited by attackers to inject malicious content.

Mitigation:

	•	Specify CSP Directives: Define explicit sources for content in your CSP policy. For example:

Content-Security-Policy: default-src 'self'; img-src 'self' https://trusted-images.example.com; script-src 'self' https://trusted-scripts.example.com


	•	Use CSP Reporting: Configure CSP to report violations, allowing you to monitor and adjust policies as needed.

Further Reading: MDN Web Docs - Content Security Policy

3. Missing Anti-Clickjacking Header

Vulnerability: Clickjacking attacks trick users into clicking on something different from what they perceive, potentially leading to unintended actions.

Mitigation:

	•	Implement X-Frame-Options Header: This header controls whether your site can be framed. For instance:

X-Frame-Options: DENY

	•	This prevents your site from being embedded in a frame or iframe.
	•	Use Content Security Policy Frame Ancestors: An alternative to X-Frame-Options, CSP can be used to specify allowed sources:

Content-Security-Policy: frame-ancestors 'none'



Further Reading: OWASP Clickjacking Defense Cheat Sheet

4. X-Content-Type Options Header Missing

Vulnerability: The absence of the X-Content-Type-Options header allows browsers to interpret files in unexpected ways, which can be exploited by attackers.

Mitigation:

	•	Implement X-Content-Type-Options Header: Add the following header to your responses:

X-Content-Type-Options: nosniff

	•	This prevents browsers from MIME-sniffing and forces them to adhere to the declared content type.

Further Reading: MDN Web Docs - X-Content-Type-Options

5. X-Frame Options Defined via Meta

Vulnerability: Defining X-Frame-Options via meta tags is less secure than using HTTP headers, as meta tags can be easily manipulated.

Mitigation:

	•	Define X-Frame Options via HTTP Headers: Use HTTP headers to set frame options rather than meta tags. Example configuration:

X-Frame-Options: DENY



Further Reading: OWASP X-Frame-Options

6. Cross-Domain JavaScript Source File Inclusion

Vulnerability: Allowing JavaScript sources from untrusted domains can expose your site to cross-site scripting (XSS) attacks.

Mitigation:

	•	Restrict JavaScript Sources: Configure CSP to allow only trusted domains. For example:

Content-Security-Policy: script-src 'self' https://trusted-scripts.example.com


	•	Regular Audits: Regularly audit third-party scripts and resources for security and integrity.

Further Reading: OWASP Cross-Site Scripting (XSS)

Conclusion: Implementing these mitigation strategies helps secure the application against common vulnerabilities. Regular security assessments and updates are crucial to maintaining robust protection.

## *Security Enhancements*

- *Service Account*: Configured with minimal required permissions.
- *IAM Roles*: Managed to enforce least privilege access.
- *Environment Configuration*: Terraform state is managed without sensitive data exposed.

*Security Best Practices Diagram*:
![Security Best Practices](path/to/security-best-practices.png) <!-- Replace with actual path to the diagram image -->

---

## *Test Results and Logs*

*Terraform Output*:
- Successfully applied the Terraform configuration. The static website is live at the provided URL.
![url](http://34.49.94.227/index.html)

*Terraform Output Screenshot*:
![Terraform Output](screenshot\terrafofmapply.jpg) <!-- Replace with actual screenshot -->

---

## *Future Enhancements*
Future Enhancements

	•	CI/CD Pipeline: Automate the deployment of website updates via a CI/CD pipeline using GitHub Actions or Jenkins.
	•	Security Monitoring: Implement continuous monitoring using tools such as Google Cloud Security Command Center.
	•	TLS Encryption: Enable encryption in transit for all website traffic by integrating Cloudflare or setting up HTTPS.


---

## *Repository and Code Structure*

*Repository Structure*:

/terraform
  /.terraform
    /license
    /.terraform\providers\registry.terraform.io\hashicorp\google\6.2.0\windows_amd64\terraform-provider-google_v6.2.0_x5.exe
 /screenshot
 /gitatrributes
 /gitignore
 /.terraform.lock.hcl
 /main.tf
 /README.md
 /terraform.tfstate
 /terraform.tfstate.backup
 ![Terraformcode](screenshot\code.jpg) <!-- Replace with actual screenshot -->


*Setup Instructions*:
1. Clone the repository: git clone <repository-url>
2. Navigate to the project directory: cd <project-folder>
3. Configure the service account credentials:
   bash
   export GOOGLE_APPLICATION_CREDENTIALS="<path-to-your-json-key>"
   
4. Initialize Terraform: terraform init
5. Apply the Terraform configuration: terraform apply


---

## *Conclusion*

This project demonstrates a robust approach to cloud automation and security management. By showcasing Terraform automation, security controls, and vulnerability management.

---

## *Appendix*

*Useful Terraform Commands*:
- terraform init: Initializes the Terraform working directory.
- terraform plan: Previews the changes Terraform will make.
- terraform apply: Applies the changes required to reach the desired state.
- terraform destroy: Removes the infrastructure managed by Terraform.

*Key Tools Used*:
- *Terraform*: Infrastructure-as-Code tool.
- *OWASP ZAP*: Vulnerability scanning tool.
- *Google Cloud Storage*: Object storage service for hosting static content.

*Best Practices Applied*:
- *Security*: Applied least privilege access controls.
- *Automation*: Efficient cloud resource management through Terraform.

