#!/bin/bash

function get_lambda_environment_variables {
    local lambda_function_name=$1
    local response
    response=$(aws lambda get-function-configuration --function-name "$lambda_function_name")
    
    # Extract environment variables
    local environment_variables
    environment_variables=$(echo "$response" | jq -r '.Environment.Variables // {}')
    
    echo "$environment_variables"
}

function write_to_json_file {
    local data=$1
    local output_file=$2
    echo "$data" | jq '.' > "$output_file"
}

function get_lambda_functions_in_stack {
    local stack_name=$1
    local response
    response=$(aws cloudformation describe-stack-resources --stack-name "$stack_name")
    
    # Filter for Lambda functions
    local lambda_functions
    lambda_functions=$(echo "$response" | jq -r '.StackResources[] | select(.ResourceType == "AWS::Lambda::Function") | [.LogicalResourceId, .PhysicalResourceId] | @tsv')

    echo "$lambda_functions"
}

function parse_toml {
    local toml_file="$1"
    local key="$2"
    
    # Search for the key and print its value
    awk -v k="$key" '
        BEGIN { in_array = 0 }
        $1 ~ /^\[/ {
            gsub(/[\[\]]/, "")
            in_array = 0
        }
        in_array && $1 == k {
            sub(/^[[:space:]]*'"$key"'[[:space:]]*=[[:space:]]*/, "")
            sub(/"$/, "")
            gsub(/^"/, "")
            print $0
        }
        $1 == k && $2 == "=" {
            sub(/^[[:space:]]*'"$key"'[[:space:]]*=[[:space:]]*/, "")
            sub(/"$/, "")
            gsub(/^"/, "")
            print $0
        }
        $1 ~ /^\[/ && $0 ~ /\['"$key"'\]/ {
            in_array = 1
        }
    ' "$toml_file"
}

function get_stack_name_from_samconfig {
    # Check if samconfig.toml exists
    if [ ! -f "samconfig.toml" ]; then
        return
    fi

    # Load samconfig.toml and extract stack name
    local stack_name
    # stack_name=$(cat samconfig.toml | jq -r '.default.deploy.parameters."stack_name"')
    stack_name=$(parse_toml "samconfig.toml" "stack_name")

    if [ "$stack_name" == "null" ]; then
        return
    fi

    echo "$stack_name"
}

function main {
    local stack_name
    local output_file="vars.json"
    
    # Setup command-line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --stack-name)
                stack_name=$2
                shift
                ;;
        esac
        shift
    done

    # Get CloudFormation stack name from command-line arguments
    if [ -z "$stack_name" ]; then
        stack_name=$(get_stack_name_from_samconfig)

        # If stack_name is still not found, prompt the user to enter it manually
        while [ -z "$stack_name" ]; do
            read -p "Enter the CloudFormation stack name: " stack_name
        done
    fi

    # Check if the CloudFormation stack exists
    aws cloudformation describe-stacks --stack-name "$stack_name" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Error: CloudFormation stack '$stack_name' does not exist."
        exit 1
    fi

    lambda_functions=$(get_lambda_functions_in_stack "$stack_name")

    output_data="{}"

    # Iterate over Lambda functions and get environment variables
    while IFS=$'\t' read -r logical_id physical_id; do
        environment_variables=$(get_lambda_environment_variables "$physical_id")
        output_data=$(echo "$output_data" | jq ". + {\"$logical_id\": $environment_variables}")
    done <<< "$lambda_functions"

    write_to_json_file "$output_data" "$output_file"

    echo "Environment variables for all Lambdas in the stack '$stack_name' written to $output_file"
}

main "$@"
