#!/bin/sh

set -e

INPUT_ENV_VARIABLES=("INPUT_AWS_ACCESS_KEY_ID" "INPUT_AWS_SECRET_ACCESS_KEY" "INPUT_AWS_REGION" "INPUT_AWS_ACCOUNT_ID")
SEVERITY_LEVELS=("CRITICAL" "HIGH" "MEDIUM" "LOW")

function trigger_scan() {
  validate_aws_env_variables
  validate_docker_info
  aws_docker_login
  aws ecr start-image-scan --registry-id  $INPUT_AWS_ACCOUNT_ID --repository-name $INPUT_AWS_ECR_REPO --image-id imageTag=$INPUT_AWS_ECR_TAG --region $AWS_REGION 
  if [[ $? -eq 255 ]]; then
    echo "Unable to trigger the scan for the image. Please check the logs for the error! Exiting!"
    exit 1
  else
    echo "Trigged the scan manually! Will fetch the scanned results once the scan is complete"
  fi

  aws ecr wait image-scan-complete --registry-id  $INPUT_AWS_ACCOUNT_ID --repository-name $INPUT_AWS_ECR_REPO --image-id imageTag=$INPUT_AWS_ECR_TAG --region $AWS_REGION
  if [[ $? -eq 255 ]]; then
    echo "Error in figuring out if image scan is complete.. Exiting!"
    exit 1
  else
    echo "Image scan completed. Fetching the scanned results"
  fi

  result=$(aws ecr describe-image-scan-findings \
    --registry-id $INPUT_AWS_ACCOUNT_ID \
    --repository-name "$INPUT_AWS_ECR_REPO" \
    --image-id imageTag="$INPUT_AWS_ECR_TAG"\
    --region $AWS_REGION)

  severity_results=$(echo $result | jq '.imageScanFindings.findingSeverityCounts')

  for level in "${SEVERITY_LEVELS[@]}"
  do
    severity_count=$(echo $severity_results | jq ".$level")
    if [ -z "$severity_count" ]; then
      echo ""
    elif [[ "$severity_count" -gt 0 ]]; then
      vulnerable_package="true"
      echo "$severity_count packages with $level severity are found in your image!"
    fi
  done

  if [[ $vulnerable_package -ne "true" ]]; then
    echo "Hurrray! No vulnerable package found in the image"
    exit 0
  else
    # Do nothing
    image_digest=$(echo $result | jq '.imageId.imageDigest' | tr -d '"') 
    scan_report_link="https://console.aws.amazon.com/ecr/repositories/$INPUT_AWS_ECR_REPO/image/$image_digest/scan-results?region=$AWS_REGION"
    echo "Please refer this report to have more info on the vulnerable packages - $scan_report_link"
    exit 1
  fi
}

function validate_docker_info() {
  if [ -z "$INPUT_AWS_ECR_TAG" ]; then
    echo 'Tag value not passed. Will be triggering the scan for the image with the latest tag'
    INPUT_AWS_ECR_TAG='latest'
  fi

  if [ -z "$INPUT_AWS_ECR_REPO" ]; then
    echo "Please specify the aws ecr repo name!"
    exit 1
  fi
}

function aws_docker_login() {
  cmd=$(aws ecr get-login --no-include-email --region $AWS_REGION)
  $cmd
}

function validate_aws_env_variables() {
  for env_variable in "${INPUT_ENV_VARIABLES[@]}"
  do
    if [ -z "${!env_variable}" ]; then
      echo "Please set ${env_variable} to proceed further!"
      exit 1
    fi
  done
  export AWS_ACCESS_KEY_ID=${INPUT_AWS_ACCESS_KEY_ID}
  export AWS_SECRET_ACCESS_KEY=${INPUT_AWS_SECRET_ACCESS_KEY}
  export AWS_REGION=${INPUT_AWS_REGION}
}

trigger_scan