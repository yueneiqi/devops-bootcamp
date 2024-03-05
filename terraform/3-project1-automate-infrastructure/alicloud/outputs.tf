output "ecs_public_ip" {
  value = module.myapp-server.instance.public_ip
}