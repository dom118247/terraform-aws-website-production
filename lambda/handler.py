import json
import boto3
import psycopg2
import os

def lambda_handler(event, context):
    body = json.loads(event['body'])
    signup_type = body.get('type')  # 'waitlist' or 'venue'

    # get DB password from Secrets Manager
    secret = get_secret(os.environ['DB_SECRET_ARN'])

    # write to RDS
    conn = psycopg2.connect(
        host=os.environ['DB_HOST'],
        dbname=os.environ['DB_NAME'],
        user=os.environ['DB_USER'],
        password=secret
    )

    cursor = conn.cursor()

    if signup_type == 'waitlist':
        cursor.execute(
            "INSERT INTO waitlist (email) VALUES (%s)",
            (body.get('email'),)
        )
    elif signup_type == 'venue':
        cursor.execute(
            "INSERT INTO venues (venue_name, contact_name, email, venue_type) VALUES (%s, %s, %s, %s)",
            (body.get('venue_name'), body.get('contact_name'), body.get('email'), body.get('venue_type'))
        )

    conn.commit()
    cursor.close()
    conn.close()

    # send confirmation email via SES
    send_confirmation(body.get('email'), signup_type)

    return {
        'statusCode': 200,
        'headers': {'Access-Control-Allow-Origin': '*'},
        'body': json.dumps({'message': 'Success'})
    }


def get_secret(secret_arn):
    client = boto3.client('secretsmanager', region_name=os.environ['AWS_REGION_NAME'])
    response = client.get_secret_value(SecretId=secret_arn)
    secret = json.loads(response['SecretString'])
    return secret['password']


def send_confirmation(email, signup_type):
    client = boto3.client('sesv2', region_name=os.environ['AWS_REGION_NAME'])

    if signup_type == 'waitlist':
        subject = "You're on the My Third Space waitlist"
        body    = "Thanks for signing up — we'll be in touch when we launch near you."
    else:
        subject = "My Third Space — venue registration received"
        body    = "Thanks for registering your venue — we'll be in touch shortly."

    client.send_email(
        FromEmailAddress=os.environ['SES_FROM'],
        Destination={'ToAddresses': [email]},
        Content={
            'Simple': {
                'Subject': {'Data': subject},
                'Body':    {'Text': {'Data': body}}
            }
        }
    )