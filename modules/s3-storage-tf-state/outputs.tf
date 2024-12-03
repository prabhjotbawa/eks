output "bucket_id" {
  description = "ID of the bucket"
  value       = aws_s3_bucket.terraform_state.id
}

