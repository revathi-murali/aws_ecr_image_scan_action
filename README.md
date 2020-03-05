## AWS ECR trigger image scan

This action allows you to trigger the image scan on the given image stored in a ECR repository and gives the info about the vulnerabilities present in the image

## Usage:

```
jobs:
  trigger-scan:
    runs-on: ubuntu-latest
    steps:
    - uses: revathi-murali/aws_ecr_image_scan_action@v1
      with:
        aws_access_key_id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws_secret_access_key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws_account_id: ${{ secrets.AWS_ACCOUNT_ID }}
        aws_region: 'us-east-1'
        aws_ecr_repo: 'sample-repo'
        aws_ecr_tag: '1.0' # Defaults to latest if nothing is passed
```