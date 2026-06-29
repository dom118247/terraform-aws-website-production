# verify mythirdspace.co.uk domain for sending emails
resource "aws_sesv2_email_identity" "website" {
  email_identity = var.domain_name

  tags = {
    Project = var.project
  }
}

# DKIM records — prove to email providers the emails are genuinely from mythirdspace.co.uk
resource "aws_route53_record" "ses_dkim" {
  count   = 3 # SES generates 3 DKIM records

  zone_id = var.zone_id
  name    = "${aws_sesv2_email_identity.website.dkim_signing_attributes[0].tokens[count.index]}._domainkey"
  type    = "CNAME"
  ttl     = 300
  records = ["${aws_sesv2_email_identity.website.dkim_signing_attributes[0].tokens[count.index]}.dkim.amazonses.com"]
}
