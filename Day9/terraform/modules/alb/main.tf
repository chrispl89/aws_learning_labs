resource "aws_lb_target_group" "tg" {
  name     = "${var.name_prefix}-${var.target_group_name}"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = merge(var.common_tags, { Name = "${var.name_prefix}-tg" })
}

resource "aws_lb_target_group_attachment" "att" {
  count            = length(var.instance_ids)
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = var.instance_ids[count.index]
  port             = var.app_port
}

resource "aws_lb" "alb" {
  name               = "${var.name_prefix}-${var.alb_name}"  # używa var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.subnet_ids

  tags = merge(var.common_tags, { Name = "${var.name_prefix}-alb" })
}


resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "alb_url" {
  value = "http://${aws_lb.alb.dns_name}"
}
