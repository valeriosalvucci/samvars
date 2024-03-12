# samvars: SAM vars.json Generator

## Overview

This script, in python or bash, generates `vars.json`, a file used when testing locally your lambda function running: 

```bash
sam local invoke MyLambdaFunction --env-vars vars.json
```

`vars.json` contains the environment variables used by Lambda functions. The structure is as follows:

```json
{
  "LambdaFunctionName1": {
    "VariableName1": "VariableValue1",
    "VariableName2": "VariableValue2",
    ...
  },
  "LambdaFunctionName2": {
    "VariableName1": "VariableValue1",
    "VariableName2": "VariableValue2",
    ...
  },
  ...
}
```


## Installation

Clone the repository to your local machine:

```bash
git clone https://github.com/valeriosalvucci/samvars.git
```

Ensure that 
1. Your AWS CLI is configured with the necessary credentials
2. The cloludformation is deployed. samvars gets the parameter value from the deployed cloudformation.


## How to use

### Python version

Requirements
- Python 3.x
- AWS CLI configured with the necessary credentials
- boto3, toml

Install the required dependencies:
```bash
pip install -r requirements.txt
```

```bash
sam-app$ python samvars.py [ --stack-name YourCloudFormationStackName ]
```

### Bash version

Run the script by executing the following command:

```bash
sam-app$ sh samvars.sh [ --stack-name YourCloudFormationStackName ]
```

If the --stack-name parameter is omitted, the script will attempt to read the CloudFormation stack name from samconfig.toml. 
If samconfig.toml file is not present or does not contain the necessary information, the script will prompt you to enter the CloudFormation stack name manually.
  

