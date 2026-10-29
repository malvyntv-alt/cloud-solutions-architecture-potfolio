# Teardown and retention

Repository setup executes none of these operations.

| Resource | Actual configuration |
|---|---|
| Aurora | deletion_protection defaults true; skip_final_snapshot=true |
| ALB | Same deletion-protection variable |
| ECR | force_delete=true, including images |
| Audit S3 | force_destroy=true, including versions |
| App secret | recovery_window_in_days=0 |
| CloudWatch logs | No explicit retain-on-destroy protection |
| Bootstrap S3/KMS | Separate root; destroy only after the regional stack |

Destroy can remove the DB WITHOUT a final snapshot, erase audit/images and immediately delete the app secret. Export evidence and independently back up/verify required data first. Versioning does not override force deletion.

Use the same base/HA arguments as deployment. Regional Aurora and ALB deletion protection default to false. Review a regional destroy plan and verify the account/backend before applying. After the regional stack is destroyed, back up the local bootstrap state and separately review/apply the bootstrap destroy plan to remove the state bucket, KMS key, and GitHub role.

enable_runtime=false does not stop Aurora/ALB/NAT charges. Bootstrap remains separate. Production retention hardening is a separate reviewed change; this project preserves source resource settings.
