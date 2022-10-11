import os
import dataclasses
import shutil
import subprocess as sp



@dataclasses.dataclass
class paths:
    aws_cli_loc: str = ""
    tf_cli_loc: str = ""
    home_loc: str = os.environ["HOME"]


# Checks if AWS CLI is installed and updates location
def check_aws_dep(paths: paths) -> paths:
    aws_binary_location = shutil.which("aws")
    if aws_binary_location is None:
        raise Exception("AWS CLI binary not found. Is it installed and on $PATH")
    else:
        return dataclasses.replace(paths, aws_cli_loc=aws_binary_location)


# Checks if Terraform CLI is installed and updates location
def check_tf_dep(paths: paths) -> paths:
    terraform_binary_location = shutil.which("terraform")
    if terraform_binary_location is None:
        raise Exception("Terraform CLI binary not found. Is it installed and on $PATH")
    else:
        return dataclasses.replace(paths, tf_cli_loc=terraform_binary_location)


# Authenticates with AWS CLI
def aws_auth(paths: paths) -> bool:
    assert paths.aws_cli_location != ""
    assert paths.tf_cli_location != ""

    # Check for environment variables and create the configuration file
    if (os.getenv("TF_VAR_AWS_ACCESS_KEY")) and (os.getenv("TF_VAR_AWS_SECRET_ACCESS_KEY")):
        sp.call([paths.aws_cli_location, "configure", "set", "aws_access_key_id", os.getenv("TF_VAR_AWS_ACCESS_KEY")])
        sp.call([paths.aws_cli_location, "configure", "set", "aws_secret_access_key", os.getenv("TF_VAR_AWS_SECRET_ACCESS_KEY")])
        sp.call([paths.aws_cli_location, "configure", "set", "region", os.getenv("AWS_DEFAULT_REGION")])
        sp.call([paths.aws_cli_location, "configure", "set", "output", "json"])

    # If a configuration file doesnt exist - begin manual configuration
    if not os.path.exists(paths.home_location + "/.aws/credentials"):
        ret = sp.call([paths.aws_cli_location, "configure"])
        if ret != 0:
            raise Exception(
                "AWS CLI binary is not authenticating to AWS. If the error persists, try running `aws configure` in a shell"
            )
        if ret == 0:
            return True
    # If a configuration file does exist
    else:
        ret = sp.call([paths.aws_cli_location, "sts", "get-caller-identity"])
        if ret != 0:
            raise Exception("AWS CLI is not correctly authenticated")
        if ret == 0:
            return True


# Find all Terraform files
def find_deployment_files(wd: str) -> list[str, (str,str)]:
    def generate_tree():
        for (dname, _, files) in os.walk(wd):
            for file in files:
                if "main.tf" in file:
                    yield dname + "/", file
    return list(generate_tree())


# Initialize and Deploy TF files
def deploy_terraform(paths: paths, dirs: list[str, (str, str)]) -> list[bool]:

    init_array = [False] * len(dirs)
    deploy_array = [False] * len(dirs)

    for i, d in enumerate(dirs):

        init_command = "cd {} && {} init".format(d[0], paths.tf_cli_location)
        deploy_command = "cd {} && {} apply -auto-approve".format(d[0], paths.tf_cli_location)
        print(deploy_command)

        ret = sp.check_call(init_command, shell=True)

        if ret == 0:
            init_array[i] = True

        ret = sp.check_call(deploy_command, shell=True)

        if ret == 0:
            deploy_array[i] = True

    if False in init_array:
        print("TF initialization failed for one or more Terraforms")
    if False in deploy_array:
        print("TF deployment or update failed for one or more Terraforms")

    return deploy_array


# Main method
if __name__ == "__main__":

    # Create empty Dependency file
    deployment_deps = Dependencies()

    # Create File Structure
    file_dirs = find_deployment_files(os.getcwd())

    # Update Dependencies
    deployment_deps = check_aws_dep(deployment_deps)
    deployment_deps = check_tf_dep(deployment_deps)

    # Authenticate with AWS
    aws_auth(deployment_deps)

    # Initialize and Deploy
    deploy_terraform(deployment_deps, file_dirs)