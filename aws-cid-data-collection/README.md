<!-- BEGIN_TF_DOCS -->
# AWS Cloud Intelligence Dashboards

![cudos](assets/images/cudos.png)

## Description

**Problem**: Organizations struggle with AWS cost visibility and optimization across multi-account environments. Manual cost analysis is time-consuming, lacks standardization, and fails to provide actionable insights into spending patterns, resource utilization, and optimization opportunities.

**Solution**: This Terraform module automates the deployment of AWS Cloud Intelligence Dashboards (CID) framework across your AWS Organization. It provisions a complete cost intelligence platform using AWS QuickSight, delivering pre-built dashboards that transform raw billing data into actionable insights for cost optimization, chargeback/showback, and resource rightsizing.

**Architecture Overview**: The module operates across two AWS accounts using a hub-and-spoke architecture:
- **Source (Management Account)**: Deploys data collection modules via CloudFormation StackSets, gathering cost, usage, and operational data from across your organization
- **Destination (Cost Analysis Account)**: Provisions QuickSight dashboards, Athena views, S3 storage, and data collection orchestration

The framework integrates with AWS Cost and Usage Reports (CUR 2.0), AWS Data Exports, and various AWS services to collect metrics on backups, budgets, compute optimizer recommendations, ECS workloads, health events, inventory, RDS utilization, and more.

**Multi-Account Strategy**: Designed for AWS Organizations with centralized billing. The module assumes you have:
- A management account (payer account) for organization-wide data collection
- A dedicated cost analysis account for QuickSight and dashboard hosting
- Optional: AWS Identity Center (formerly SSO) for dashboard access control

## Features

### Security by Default
- **Encrypted Storage**: AES-256 encryption on all S3 buckets for CloudFormation templates and dashboard configurations
- **Private Buckets**: Public access blocks enabled on all storage resources
- **IAM Least Privilege**: Scoped permissions for QuickSight data source access and cross-account data collection
- **SAML Federation**: Native integration with AWS Identity Center for centralized authentication

### Flexible Deployment Options
- **Modular Dashboard Selection**: Enable/disable individual dashboards (CUDOS v5, Cost Intelligence, KPI, TAO, Compute Optimizer)
- **Granular Data Collection**: Toggle specific modules (backup, budgets, ECS chargeback, health events, inventory, RDS utilization, rightsizing, transit gateway)
- **CUR Format Support**: Compatible with both legacy CUR and modern AWS Data Exports (CUR 2.0, FOCUS)
- **QuickSight Editions**: Support for both Enterprise and Standard editions with configurable user management

### Operational Excellence
- **CloudFormation Integration**: Uses official AWS CID framework CloudFormation templates for dashboard provisioning
- **Automated Data Collection**: Scheduled Lambda functions collect operational data across your organization
- **Version Management**: S3 lifecycle policies automatically clean up old template versions after 90 days
- **Cross-Region Support**: Handles services that require us-east-1 deployment (QuickSight, CUR)

### Cost Intelligence Capabilities
- **Comprehensive Dashboards**: CUDOS (Cost & Usage), Cost Intelligence, KPI, Trusted Advisor Organizational view, Compute Optimizer
- **Chargeback/Showback**: Tag-based cost allocation with configurable primary and secondary tags
- **Optimization Insights**: Integration with AWS Compute Optimizer, Trusted Advisor, and rightsizing recommendations
- **Anomaly Detection**: Cost anomaly alerts and budget tracking across accounts

## Deployment Architecture

The module implements a hub-and-spoke architecture across AWS accounts:

![deployment-architecture](assets/images/cid-deployment.png)

**Data Flow**:
1. **Management Account**: AWS Organizations data, CUR/Data Exports, and cross-account data collection via Lambda functions
2. **Member Accounts**: Data collectors deploy via StackSets to gather resource-specific metrics
3. **Cost Analysis Account**: Centralized S3 storage, Athena views, Glue catalog, and QuickSight dashboards
4. **End Users**: Access dashboards via QuickSight (authenticated through IAM or AWS Identity Center)

## Operational Considerations

### Prerequisites
- **AWS Organizations**: Must be enabled with consolidated billing
- **CUR/Data Exports**: Cost and Usage Report or AWS Data Exports (CUR 2.0) must be configured
- **QuickSight**: Enterprise edition required for Identity Center integration; Standard edition supports IAM-only auth
- **IAM Permissions**: Deploying account needs `cloudformation:*`, `quicksight:*`, `s3:*`, `iam:*`, `lambda:*` permissions
- **Cross-Account Access**: Management account must trust cost analysis account for S3 data replication

### Deployment Time
- **Initial Deployment**: 30-45 minutes (includes CloudFormation stack creation, QuickSight resource provisioning, and Athena view setup)
- **Dashboard Availability**: QuickSight dashboards may take an additional 10-15 minutes after infrastructure provisioning for initial data ingestion
- **Data Refresh**: Lambda-based collectors run hourly/daily depending on the module; full historical data population can take 24-48 hours

### Known Limitations
- **QuickSight Region**: QuickSight must be enabled in the same region as your Athena workgroup (typically us-east-1 or your primary region)
- **CUR Lag**: Cost and Usage Report data has a 24-hour delay; current-day costs are estimates
- **Data Export Regions**: AWS Data Exports (CUR 2.0) are currently limited to specific regions; check AWS documentation for availability
- **SPICE Capacity**: QuickSight SPICE (in-memory engine) has capacity limits; Enterprise edition required for larger datasets
- **Module Dependencies**: Some data collection modules require specific AWS services to be enabled (e.g., AWS Backup, Compute Optimizer, Trusted Advisor)
- **StackSet Deployment**: Cross-account data collection uses CloudFormation StackSets; requires service-managed or self-managed StackSet permissions

### Cost Considerations
- **QuickSight Licensing**: Enterprise edition costs $18/user/month (or $5/reader/month); Standard edition is $9/user/month
- **Athena Queries**: Charged per TB scanned; optimize with partitioning and date filters
- **Lambda Invocations**: Data collectors run on schedules; costs typically $10-50/month depending on org size
- **S3 Storage**: Dashboard configurations and CloudFormation templates; typically <1GB ($0.02/month)
- **Data Transfer**: Cross-account S3 replication may incur transfer costs if accounts are in different regions

### Security Considerations
- **SAML Metadata**: Store SAML metadata files in a secure location; they contain sensitive IdP configuration
- **Bucket Policies**: The module uses least-privilege bucket policies; review before deployment in regulated environments
- **QuickSight VPC**: QuickSight Enterprise supports VPC connections; configure via `enable_lake_formation` for private Athena access
- **CloudFormation Drift**: Dashboards deployed via CloudFormation may drift if modified manually in QuickSight; use `cid-cmd` CLI for updates

## Upgrading Dashboards

Dashboard definitions are managed by AWS via CloudFormation templates. To upgrade to newer dashboard versions:

1. **Install cid-cmd CLI**: Download the latest version of the official [CID command-line tool](https://github.com/aws-samples/aws-cudos-framework-deployment?tab=readme-ov-file#install)
   ```bash
   python3 -m pip install --upgrade cid-cmd
   ```

2. **Run Dashboard Upgrade**: Execute the CLI to select and upgrade specific dashboards
   ```bash
   cid-cmd upgrade
   ```

3. **Review Athena Views**: Inspect Athena views for custom modifications before confirming upgrades to avoid overwriting customizations

4. **Update Terraform Variable**: After upgrading, update the `cfn_dashboards_version` variable to match the deployed version for state consistency
   ```hcl
   cfn_dashboards_version = "4.4.0"  # Update to match cid-cmd deployment
   ```

**Note**: Dashboard schema changes may require re-creating QuickSight datasets. Test upgrades in a non-production environment first.

## Advanced Features

### SCAD (Savings with Cost Anomaly Detection)
Enable SCAD for ML-powered cost anomaly detection integrated with CUDOS dashboards:
```hcl
enable_scad = true  # In both source and destination modules
```

Requires AWS Data Exports (CUR 2.0) to be enabled. See the [AWS CID Workshop](https://catalog.workshops.aws/awscid/en-US/dashboards/additional/cora) for details.

### Compute Optimization Hub
Centralized compute rightsizing recommendations across EC2, Lambda, and ECS:
```hcl
enable_compute_optimization_hub = true
enable_compute_optimizer_module = true
```

### Tag-Based Chargeback
Configure custom tags for cost allocation and showback reporting:
```hcl
data_collection_primary_tag_name   = "CostCenter"
data_collection_secondary_tag_name = "Project"
```

Dashboards will group costs by specified tags, enabling department-level chargeback.

### AWS License Manager Integration
Track license usage alongside infrastructure costs:
```hcl
enable_license_manager_module = true
```

Requires AWS License Manager to be configured with license rules.

## Troubleshooting

### QuickSight User Not Found
**Error**: `User 'admin' does not exist in QuickSight`

**Resolution**: Ensure QuickSight subscription is active and user is created before deploying dashboards. Set `enable_quicksight_admin = true` and provide `quicksight_admin_email`.

### CloudFormation Stack Timeout
**Error**: Stack creation exceeds 60-minute timeout

**Resolution**: Increase timeout in `timeouts` block or deploy dashboards incrementally by disabling some initially:
```hcl
enable_cudos_v5_dashboard = true
enable_tao_dashboard      = false  # Deploy in second phase
```

### Athena Query Permissions Error
**Error**: `Insufficient permissions to access S3 bucket`

**Resolution**: Verify `destination_bucket_arn` is correctly passed from destination to source module and cross-account bucket policies allow management account access.

### SSO Integration Failure
**Error**: `SAML provider already exists`

**Resolution**: If migrating from manual deployment, import existing SAML provider:
```bash
terraform import 'module.destination.aws_iam_saml_provider.saml[0]' arn:aws:iam::ACCOUNT_ID:saml-provider/PROVIDER_NAME
```

## References

- [AWS Cloud Intelligence Dashboards Workshop](https://catalog.workshops.aws/awscid/)
- [Identity Center Integration Guide](https://cloudyadvice.com/2022/04/29/implementing-cudos-cost-intelligence-dashboards-for-an-enterprise/)
- [Official CID Framework](https://github.com/awslabs/cid-framework)
- [CID Command-Line Tool](https://github.com/aws-samples/aws-cudos-framework-deployment)
- [AWS Cost and Usage Reports Documentation](https://docs.aws.amazon.com/cur/latest/userguide/what-is-cur.html)

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.36.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cloudformation"></a> [cloudformation](#module\_cloudformation) | git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git | 1a431dd0ccc2478399fce247a75caf40a109bb10 |
| <a name="module_dashboard_bucket"></a> [dashboard\_bucket](#module\_dashboard\_bucket) | git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git | 1a431dd0ccc2478399fce247a75caf40a109bb10 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudformation_stack.cudos_data_collection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack) | resource |
| [aws_cloudformation_stack.dashboards](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack) | resource |
| [aws_cloudformation_stack.data_export_destination](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack) | resource |
| [aws_iam_role.cudos_sso](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.cudos_sso](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_saml_provider.saml](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_saml_provider) | resource |
| [aws_quicksight_account_subscription.subscription](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/quicksight_account_subscription) | resource |
| [aws_quicksight_group.groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/quicksight_group) | resource |
| [aws_quicksight_group_membership.members](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/quicksight_group_membership) | resource |
| [aws_quicksight_user.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/quicksight_user) | resource |
| [aws_quicksight_user.users](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/quicksight_user) | resource |
| [aws_s3_bucket_lifecycle_configuration.bucket_lifecycle](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_object.cloudformation_templates](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cudos_sso](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cudos_sso_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.dashboards_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_athena_query_results_bucket"></a> [athena\_query\_results\_bucket](#input\_athena\_query\_results\_bucket) | The name of the Athena query results bucket | `string` | `""` | no |
| <a name="input_athena_workgroup"></a> [athena\_workgroup](#input\_athena\_workgroup) | The name of the Athena workgroup | `string` | `""` | no |
| <a name="input_cfn_dashboards_version"></a> [cfn\_dashboards\_version](#input\_cfn\_dashboards\_version) | The version of the CUDOS dashboards | `string` | `"4.3.7"` | no |
| <a name="input_cloudformation_bucket_name"></a> [cloudformation\_bucket\_name](#input\_cloudformation\_bucket\_name) | The name of the bucket to store the CloudFormation | `string` | n/a | yes |
| <a name="input_dashboard_suffix"></a> [dashboard\_suffix](#input\_dashboard\_suffix) | The suffix for the dashboards | `string` | `""` | no |
| <a name="input_dashboards_bucket_name"></a> [dashboards\_bucket\_name](#input\_dashboards\_bucket\_name) | The name of the bucket to store the dashboards configurations | `string` | n/a | yes |
| <a name="input_data_buckets_kms_keys_arns"></a> [data\_buckets\_kms\_keys\_arns](#input\_data\_buckets\_kms\_keys\_arns) | The ARNs of the KMS keys for the data buckets | `list(string)` | `[]` | no |
| <a name="input_data_collection_primary_tag_name"></a> [data\_collection\_primary\_tag\_name](#input\_data\_collection\_primary\_tag\_name) | The primary tag name for the data collection | `string` | `"owner"` | no |
| <a name="input_data_collection_secondary_tag_name"></a> [data\_collection\_secondary\_tag\_name](#input\_data\_collection\_secondary\_tag\_name) | The secondary tag name for the data collection | `string` | `"environment"` | no |
| <a name="input_database_name"></a> [database\_name](#input\_database\_name) | The name of the Athena database | `string` | `""` | no |
| <a name="input_deployment_type"></a> [deployment\_type](#input\_deployment\_type) | The type of deployment | `string` | `null` | no |
| <a name="input_enable_backup_module"></a> [enable\_backup\_module](#input\_enable\_backup\_module) | Indicates if the Backup module should be enabled | `bool` | `true` | no |
| <a name="input_enable_budgets_module"></a> [enable\_budgets\_module](#input\_enable\_budgets\_module) | Indicates if the Budget module should be enabled | `bool` | `true` | no |
| <a name="input_enable_compute_optimizer_dashboard"></a> [enable\_compute\_optimizer\_dashboard](#input\_enable\_compute\_optimizer\_dashboard) | Indicates if the Compute Optimizer dashboard should be enabled | `bool` | `true` | no |
| <a name="input_enable_compute_optimizer_module"></a> [enable\_compute\_optimizer\_module](#input\_enable\_compute\_optimizer\_module) | Indicates if the Compute Optimizer module should be enabled | `bool` | `true` | no |
| <a name="input_enable_compute_optimizization_hub"></a> [enable\_compute\_optimizization\_hub](#input\_enable\_compute\_optimizization\_hub) | Indicates if the Compute Optimizization Hub module should be enabled | `bool` | `false` | no |
| <a name="input_enable_cost_anomaly_module"></a> [enable\_cost\_anomaly\_module](#input\_enable\_cost\_anomaly\_module) | Indicates if the Cost Anomaly module should be enabled | `bool` | `true` | no |
| <a name="input_enable_cost_intelligence_dashboard"></a> [enable\_cost\_intelligence\_dashboard](#input\_enable\_cost\_intelligence\_dashboard) | Indicates if the Cost Intelligence dashboard should be enabled | `bool` | `true` | no |
| <a name="input_enable_cudos_v5_dashboard"></a> [enable\_cudos\_v5\_dashboard](#input\_enable\_cudos\_v5\_dashboard) | Indicates if the CUDOS V5 framework should be enabled | `bool` | `true` | no |
| <a name="input_enable_ecs_chargeback_module"></a> [enable\_ecs\_chargeback\_module](#input\_enable\_ecs\_chargeback\_module) | Indicates if the ECS Chargeback module should be enabled | `bool` | `false` | no |
| <a name="input_enable_health_events_module"></a> [enable\_health\_events\_module](#input\_enable\_health\_events\_module) | Indicates if the Health Events module should be enabled | `bool` | `true` | no |
| <a name="input_enable_inventory_module"></a> [enable\_inventory\_module](#input\_enable\_inventory\_module) | Indicates if the Inventory module should be enabled | `bool` | `true` | no |
| <a name="input_enable_kpi_dashboard"></a> [enable\_kpi\_dashboard](#input\_enable\_kpi\_dashboard) | Indicates if the KPI dashboard should be enabled | `bool` | `true` | no |
| <a name="input_enable_lake_formation"></a> [enable\_lake\_formation](#input\_enable\_lake\_formation) | Indicates if the Lake Formation should be enabled | `bool` | `false` | no |
| <a name="input_enable_license_manager_module"></a> [enable\_license\_manager\_module](#input\_enable\_license\_manager\_module) | Indicates if the License Manager module should be enabled | `bool` | `false` | no |
| <a name="input_enable_org_data_module"></a> [enable\_org\_data\_module](#input\_enable\_org\_data\_module) | Indicates if the Organization Data module should be enabled | `bool` | `true` | no |
| <a name="input_enable_prerequisites_quicksight"></a> [enable\_prerequisites\_quicksight](#input\_enable\_prerequisites\_quicksight) | Indicates if the prerequisites for QuickSight should be enabled | `bool` | `true` | no |
| <a name="input_enable_prerequisites_quicksight_permissions"></a> [enable\_prerequisites\_quicksight\_permissions](#input\_enable\_prerequisites\_quicksight\_permissions) | Indicates if the prerequisites for QuickSight permissions should be enabled | `bool` | `true` | no |
| <a name="input_enable_quicksight_admin"></a> [enable\_quicksight\_admin](#input\_enable\_quicksight\_admin) | Enable the creation of an admin user (var.quicksight\_admin\_username) in QuickSight | `bool` | `true` | no |
| <a name="input_enable_quicksight_subscription"></a> [enable\_quicksight\_subscription](#input\_enable\_quicksight\_subscription) | Enable QuickSight subscription | `bool` | `false` | no |
| <a name="input_enable_rds_utilization_module"></a> [enable\_rds\_utilization\_module](#input\_enable\_rds\_utilization\_module) | Indicates if the RDS Utilization module should be enabled | `bool` | `true` | no |
| <a name="input_enable_rightsizing_module"></a> [enable\_rightsizing\_module](#input\_enable\_rightsizing\_module) | Indicates if the Rightsizing module should be enabled | `bool` | `true` | no |
| <a name="input_enable_scad"></a> [enable\_scad](#input\_enable\_scad) | Indicates if the SCAD module should be enabled, only available when Cora enabled | `bool` | `false` | no |
| <a name="input_enable_sso"></a> [enable\_sso](#input\_enable\_sso) | Enable integration with identity center for QuickSight | `bool` | `true` | no |
| <a name="input_enable_tao_dashboard"></a> [enable\_tao\_dashboard](#input\_enable\_tao\_dashboard) | Indicates if the TAO dashboard should be enabled | `bool` | `false` | no |
| <a name="input_enable_tao_module"></a> [enable\_tao\_module](#input\_enable\_tao\_module) | Indicates if the TAO module should be enabled | `bool` | `true` | no |
| <a name="input_enable_transit_gateway_module"></a> [enable\_transit\_gateway\_module](#input\_enable\_transit\_gateway\_module) | Indicates if the Transit Gateway module should be enabled | `bool` | `true` | no |
| <a name="input_glue_data_catalog"></a> [glue\_data\_catalog](#input\_glue\_data\_catalog) | The name of the Glue data catalog | `string` | `"AwsDataCatalog"` | no |
| <a name="input_lambda_layer_bucket_prefix"></a> [lambda\_layer\_bucket\_prefix](#input\_lambda\_layer\_bucket\_prefix) | The prefix for the Lambda layer bucket | `string` | `"aws-managed-cost-intelligence-dashboards"` | no |
| <a name="input_payer_accounts"></a> [payer\_accounts](#input\_payer\_accounts) | List of additional payer accounts to be included in the collectors module | `list(string)` | `[]` | no |
| <a name="input_quicksight_admin_email"></a> [quicksight\_admin\_email](#input\_quicksight\_admin\_email) | The email address for the QuickSight admin user. Required if var.create\_quicksight\_admin\_user is true | `string` | `null` | no |
| <a name="input_quicksight_admin_username"></a> [quicksight\_admin\_username](#input\_quicksight\_admin\_username) | The username for the QuickSight admin user | `string` | `"admin"` | no |
| <a name="input_quicksight_dashboard_owner"></a> [quicksight\_dashboard\_owner](#input\_quicksight\_dashboard\_owner) | The username for the QuickSight user who will own the dashboards. This user needs to exist. By default, it will be the admin user which is created by the module. | `string` | `"admin"` | no |
| <a name="input_quicksight_data_set_refresh_schedule"></a> [quicksight\_data\_set\_refresh\_schedule](#input\_quicksight\_data\_set\_refresh\_schedule) | The schedule for the Quicksight data set refresh | `string` | `""` | no |
| <a name="input_quicksight_data_source_role_name"></a> [quicksight\_data\_source\_role\_name](#input\_quicksight\_data\_source\_role\_name) | The name of the Quicksight data source role | `string` | `"CidQuickSightDataSourceRole"` | no |
| <a name="input_quicksight_groups"></a> [quicksight\_groups](#input\_quicksight\_groups) | Map of groups with user membership to be added to QuickSight | <pre>map(object({<br/>    description = optional(string)<br/>    namespace   = optional(string)<br/>    members     = optional(list(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_quicksight_subscription_account_name"></a> [quicksight\_subscription\_account\_name](#input\_quicksight\_subscription\_account\_name) | The account name for the QuickSight quicksight\_subscription edition | `string` | `null` | no |
| <a name="input_quicksight_subscription_authentication_method"></a> [quicksight\_subscription\_authentication\_method](#input\_quicksight\_subscription\_authentication\_method) | The identity for the QuickSight quicksight\_subscription edition | `string` | `"IAM_AND_QUICKSIGHT"` | no |
| <a name="input_quicksight_subscription_edition"></a> [quicksight\_subscription\_edition](#input\_quicksight\_subscription\_edition) | The edition for the QuickSight quicksight\_subscription | `string` | `"ENTERPRISE"` | no |
| <a name="input_quicksight_subscription_email"></a> [quicksight\_subscription\_email](#input\_quicksight\_subscription\_email) | The email address for the QuickSight quicksight\_subscription edition | `string` | `null` | no |
| <a name="input_quicksight_users"></a> [quicksight\_users](#input\_quicksight\_users) | Map of user accounts to be registered in QuickSight | <pre>map(object({<br/>    identity_type = string<br/>    namespace     = optional(string, "default")<br/>    role          = optional(string, "READER")<br/>  }))</pre> | `{}` | no |
| <a name="input_saml_iam_role_name"></a> [saml\_iam\_role\_name](#input\_saml\_iam\_role\_name) | Name of the role all authentication users are initially given | `string` | `"aws-cudos-sso"` | no |
| <a name="input_saml_metadata"></a> [saml\_metadata](#input\_saml\_metadata) | The configuration for the SAML identity provider | `string` | `""` | no |
| <a name="input_saml_provider_name"></a> [saml\_provider\_name](#input\_saml\_provider\_name) | The name of the SAML provider | `string` | `"aws-cudos-sso"` | no |
| <a name="input_share_dashboard"></a> [share\_dashboard](#input\_share\_dashboard) | Indicates if the dashboard should be shared | `string` | `"yes"` | no |
| <a name="input_stack_name_cloud_intelligence"></a> [stack\_name\_cloud\_intelligence](#input\_stack\_name\_cloud\_intelligence) | The name of the CloudFormation stack to create the dashboards | `string` | `"CI-Cloud-Intelligence-Dashboards"` | no |
| <a name="input_stack_name_collectors"></a> [stack\_name\_collectors](#input\_stack\_name\_collectors) | The name of the CloudFormation stack to create the collectors | `string` | `"CidDataCollectionStack"` | no |
| <a name="input_stack_name_data_exports"></a> [stack\_name\_data\_exports](#input\_stack\_name\_data\_exports) | The name of the CloudFormation stack to create the Data Exports | `string` | `"CidDataExportsDestinationStack"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cfn_dashboards_version"></a> [cfn\_dashboards\_version](#output\_cfn\_dashboards\_version) | The version of the CUDOS dashboards |
| <a name="output_cloudformation_bucket_arn"></a> [cloudformation\_bucket\_arn](#output\_cloudformation\_bucket\_arn) | The name of the bucket where to store the CloudFormation |
| <a name="output_dashboard_bucket_arn"></a> [dashboard\_bucket\_arn](#output\_dashboard\_bucket\_arn) | The name of the bucket where to store the dashboards |
| <a name="output_destination_account_id"></a> [destination\_account\_id](#output\_destination\_account\_id) | The ID of the data collection account |
| <a name="output_destination_bucket_arn"></a> [destination\_bucket\_arn](#output\_destination\_bucket\_arn) | The name of the bucket where to replicate the data from the CUR |
| <a name="output_destination_bucket_name"></a> [destination\_bucket\_name](#output\_destination\_bucket\_name) | The name of the bucket where to replicate the data from the CUR |
<!-- END_TF_DOCS -->
