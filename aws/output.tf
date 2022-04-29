output "elastic_url" {
  value = "http://${aws_instance.elastic.public_ip}:5601"
}

output "victim_url" {
  value = "http://${aws_instance.victim.public_ip}"
}