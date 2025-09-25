output "vpc_id" {
  value = aws_vpc.this.id
}

output "subnet_a_id" {
  value = aws_subnet.a.id
}

output "subnet_b_id" {
  value = aws_subnet.b.id
}
