
# AWS CI/CD Assignment

## Structure
- /infra: Terraform code, tests, lint configs
- /web: Website (frontend), Lambda code, tests, lint configs
- buildspec-infra.yml: Infrastructure pipeline
- buildspec-web.yml: Web pipeline

## Setup Instructions
1. Add AWS credentials and CloudFront distribution ID to pipeline secrets.
2. Push changes to the develop branch to trigger pipelines.
3. Pipelines will lint, test, build, and deploy automatically.

## Architecture Diagram
[Insert diagram here: S3 <-> CloudFront <-> Website, API Gateway <-> Lambda <-> DynamoDB]

## Demo Steps
1. Push to develop branch.
2. Show pipeline triggers and failures on lint/test errors.
3. Fix errors and show successful deploys.
4. Show CloudFront URL serving the site.
5. Submit contact form and verify data in DynamoDB.
6. Show CloudFront invalidation for instant updates.

## Screenshots/Links
- [Pipeline failure screenshot]
- [Pipeline success screenshot]
- [CloudFront URL]
- [DynamoDB data screenshot]

---

For details, see infra/README.md and web/README.md.
# pipelines-terraform