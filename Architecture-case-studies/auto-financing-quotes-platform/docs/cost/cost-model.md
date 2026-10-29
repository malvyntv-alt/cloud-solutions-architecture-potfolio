# Cost model

## Cost

The demo reduces database and compute redundancy; it is not a free-tier/serverless deployment.

Estimate with AWS Pricing Calculator using your actual region and duration:
- Aurora instance-hours, storage, I/O and backups.
- ALB hours/capacity units; NAT gateway hours/processing and public IPv4.
- Fargate task CPU/memory-hours (web + continuously running publisher).
- CloudWatch logs, embedded metrics, alarms, dashboard and Container Insights.
- WAF, Cognito active users/features, Secrets Manager, Route 53, ECR and audit storage.
- SQS requests, Lambda duration and SES sends.
- HA expansion and later cross-region transfer, replicas and standby capacity.

The $150 default is only an editable budget ALERT threshold. It is not an estimate, an enforced limit, or a promise the deployment costs less than that.

Run timed exercises and tear down deliberately. A later serverless implementation could lower idle cost, but would be a different design decision.


## Estimate and measure

Record region/profile, duration, DB/task capacity, traffic/storage, NAT bytes and logs. Attach dated calculator assumptions and observed billing with attribution delays.

No measured cost is published for this edition. Activate the Project cost tag; a blank alarm_email provides no budget recipient. Keep a teardown deadline.
