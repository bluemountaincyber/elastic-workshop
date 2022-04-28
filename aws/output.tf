output "opensearch_url" {
  value = "http://${aws_instance.opensearch.public_ip}:5601"
}

output "victim_url" {
  value = "http://${aws_instance.victim.public_ip}"
}