# Terraform Auto-Deployer

Easily deploy your terraform files to AWS with just a push to GitHub!


## Getting Started

1. Fork the repo and clone a copy to your local machine
2. In your repo's secrets section, update the `AWS_ACCESS_KEY` and `AWS_SECRET_ACCESS_KEY` variables 
3. Configure your github runner to use the provided `main.yml` file
4. Push your `main.tf` and your `variables.tf` files to your repo and watch them automatically deploy to AWS


### Prerequisites

    All requirements are automatically downloaded and installed by the GitRunner machine.  
    
## How it works

1. Whenever a new `.tf` file is added/deleted/modified on the main branch the GitHub Runner will trigger
2. The GitHub Runner will download and install all the prequisties and run the included python script `deploy.py`
3. The Python script will authenticate and deploy/modify/tear-down any infrastructure
4. The Terraform State must be stored remotely ideally in AWS S3 

## Built With

  - Python 3
  - Hashicorp Terraform

## Authors

  - **Shaan Hashmi** - *Intial Build* -
    [ShaanHash](https://github.com/ShaanHash)


## License

This project is licensed under the [CC0 1.0 Universal](LICENSE.md)
Creative Commons License - see the [LICENSE.md](LICENSE.md) file for
details

