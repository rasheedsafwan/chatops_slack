import json
import os
import boto3

lambda_client = boto3.client("lambda")

def handler(event, context):
    """
    Triggered via Slack command through AWS Chatbot.
    Expects event to contain the target function name.
    """
    # 1. Handle case where AWS Chatbot passes the payload as a raw string
    if isinstance(event, str):
        try:
            event = json.loads(event)
        except json.JSONDecodeError:
            raise ValueError("Failed to parse incoming payload string into valid JSON")

    # 2. Extract target function now that event is guaranteed to be a dictionary
    target_function = event.get("function_name")

    if not target_function or not target_function.startswith("chatopsbot-"):
        raise ValueError("Refusing: target must be a chatopsbot-managed function")

    # A "restart" for Lambda = force a new execution environment
    # by updating a harmless config value (e.g. an env var timestamp)
    response = lambda_client.update_function_configuration(
        FunctionName=target_function,
        Environment={"Variables": {"LAST_RESTART": context.aws_request_id}}
    )

    return {
        "statusCode": 200,
        "body": f"Restarted {target_function}. New revision: {response['RevisionId']}"
    }
