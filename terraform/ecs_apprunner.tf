# ECS Cluster for Persistent Database & Service Containers
resource "aws_ecs_cluster" "data_cluster" {
  name = "englishhive-data-cluster"
}
