output "app_id" {
  value = aws_amplify_app.this.id
}
output "default_domain" {
  value = aws_amplify_app.this.default_domain
}
output "branch_name" {
  value = aws_amplify_branch.this.branch_name
}
output "build_spec" {
  value = aws_amplify_app.this.build_spec
}
output "app_root" {
  value = aws_amplify_app.this.environment_variables["AMPLIFY_MONOREPO_APP_ROOT"]
}
