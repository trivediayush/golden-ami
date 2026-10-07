output "pipeline_name" {
  description = "Name of the Golden AMI Image Builder pipeline."
  value       = aws_imagebuilder_image_pipeline.golden_ami.name
}
