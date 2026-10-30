# Iam module

Owns the Lambda role and inline policy. Allows only GetItem/UpdateItem on the table and writes to the named Lambda log group. API module owns log creation. No visitor credentials, user accounts or GitHub tokens.
