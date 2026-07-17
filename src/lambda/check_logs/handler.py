import boto3
import time

logs_client = boto3.client("logs")

def handler(event, context):
    """
    Expects event: { "function_name": "chatopsbot-restart-function-dev", "minutes": 10 }
    Returns the most recent log lines for that function.
    """
    function_name = event.get("function_name")
    minutes = event.get("minutes", 10)

    if not function_name or not function_name.startswith("chatopsbot-"):
        return {"statusCode": 400, "body": "Refusing: target must be a chatopsbot-managed function"}

    log_group = f"/aws/lambda/{function_name}"
    start_time = int((time.time() - (minutes * 60)) * 1000)

    try:
        response = logs_client.filter_log_events(
            logGroupName=log_group,
            startTime=start_time,
            limit=50
        )
    except logs_client.exceptions.ResourceNotFoundException:
        return {"statusCode": 404, "body": f"No log group found for {function_name}"}

    lines = [event["message"].strip() for event in response.get("events", [])]

    return {
        "statusCode": 200,
        "body": "\n".join(lines) if lines else "No log events in the given window."
    }