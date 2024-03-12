import boto3
import json
import toml
import os
import argparse

def get_lambda_environment_variables(lambda_function_name):
    client = boto3.client('lambda')
    
    # Get Lambda function configuration
    response = client.get_function_configuration(FunctionName=lambda_function_name)

    # Extract environment variables
    environment_variables = response.get('Environment', {}).get('Variables', {})
    
    return environment_variables

def write_to_json_file(data, output_file):
    with open(output_file, 'w') as json_file:
        json.dump(data, json_file, indent=2)

def get_lambda_functions_in_stack(stack_name):
    client = boto3.client('cloudformation')

    # Get stack resources
    try:
        response = client.describe_stack_resources(StackName=stack_name)
    except client.exceptions.ClientError as e:
        if e.response['Error']['Code'] == 'ValidationError' and 'does not exist' in e.response['Error']['Message']:
            print(f"Error: CloudFormation stack '{stack_name}' does not exist.")
            exit(0)
        else:
            raise e

    # Filter for Lambda functions
    lambda_functions = [(resource['LogicalResourceId'], resource['PhysicalResourceId'])
                        for resource in response['StackResources']
                        if resource['ResourceType'] == 'AWS::Lambda::Function']

    return lambda_functions

def get_stack_name_from_samconfig():
    # Check if samconfig.toml exists
    if not os.path.exists('samconfig.toml'):
        print("samconfig.toml does not exist. Please provide the CloudFormation stack name.")
        return None

    # Load samconfig.toml and extract stack name
    with open('samconfig.toml', 'r') as toml_file:
        config = toml.load(toml_file)
        stack_name = config.get('default', {}).get('deploy', {}).get('parameters', {}).get('stack_name')
        return stack_name

def main():
    # Setup command-line arguments
    parser = argparse.ArgumentParser(description="Generate environment variables for Lambda functions in a CloudFormation stack (vars.json).")
    parser.add_argument("--stack-name", default=None, help="Specify the CloudFormation stack name")
    args = parser.parse_args()

    # Get CloudFormation stack name from command-line arguments
    stack_name = args.stack_name

    # If --stack-name is not provided, attempt to get it from samconfig.toml
    if stack_name is None:
        stack_name = get_stack_name_from_samconfig()

    # If stack_name is still not found, prompt the user to enter it manually
    if stack_name is None:
        stack_name = input("Enter the CloudFormation stack name: ")

    # Check if the CloudFormation stack exists
    lambda_functions = get_lambda_functions_in_stack(stack_name)

    output_data = {}

    # Iterate over Lambda functions and get environment variables
    for logical_id, physical_id in lambda_functions:
        environment_variables = get_lambda_environment_variables(physical_id)
        output_data[logical_id] = environment_variables

    # Write to JSON file
    output_file = "vars.json"
    write_to_json_file(output_data, output_file)

    print(f"Environment variables for all Lambdas in the stack '{stack_name}' written to {output_file}")

if __name__ == "__main__":
    main()
