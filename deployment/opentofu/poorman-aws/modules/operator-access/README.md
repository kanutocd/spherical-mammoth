# Operator access

Creates an attachable IAM policy limited to SSH port 22 through this EICE and to
instances carrying the expected ASG tag. Role ARNs supplied at the root receive
the policy; otherwise attach the output policy ARN separately. The same policy
can upload immutable release artifacts only under the deployment bucket prefix.
