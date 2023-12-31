# Manual Terraform Infrastructure (5)
### October 14, 2023
#### Kevin Gonzalez


## Purpose

This deployment utilizes Terraform (Infrastructure as Code) to provision the infrastructure needed to host a banking application server. To streamline processes, Jenkins is integrated for automated building and testing, and webhooks are used to trigger Jenkins. Gunicorn is the chosen application hosting solution.
![DiagramD5](Terraform_D5.png)
## Deployment Steps

### 1. Provisioning Infrastructure

Terraform, is an open-source Infrastructure as Code (IaC) tool that simplifies infrastructure management with its declarative configuration language. It supports multiple cloud providers and efficient provisioning.

In this deployment, Terraform creates the following [resources](https://github.com/kevingonzalez7997/Terraform_D5/blob/main/main.tf):

- 1 Virtual Private Cloud (VPC)
- 2 Availability Zones (AZs)
- 2 Public Subnets
- 2 EC2 instances (Jenkins and App)
- 1 Route Table
- Security Group with open ports: 8080, 8000, and 22

Additionally, Terraform's capabilities are used to install [Jenkins](https://github.com/kevingonzalez7997/Jenkins_install) during the EC2 creation process. The following command is included in the first EC2 resource block.
- `user_data = "${file("jenkins_install_script.sh")}"`

### 2. Jenkins Server SSH

Jenkins, an open-source continuous integration (CI) server, is responsible for building, testing, and deploying software projects. After installing the Jenkins server via the provisioning step, SSH keys are generated.

In this deployment, the application is deployed on a separate EC2 instance (App). Pulling source code from GitHub, Jenkins will then transfer the required files to the App EC2.
- Set a Jenkins server password: `sudo passwd jenkins`
- Log in to the Jenkins server: `sudo su - jenkins -s /bin/bash`
- Generate SSH keys: `ssh-keygen`
- Copy the public key content and paste it into the `authorized_keys` file of the second instance.

Before Continuing ensure the necessary prerequisites are in place:

- Install software-properties-common: `sudo apt install -y software-properties-common`
- Add the deadsnakes repository for Python 3.7: `sudo add-apt-repository -y ppa:deadsnakes/ppa`
- Install Python 3.7: `sudo apt install -y python3.7`
- Set up a Python 3.7 virtual environment: `sudo apt install -y python3.7-venv`
**Deadsnakes is a repository that contains alternative Python versions. It allows you to install multiple Python versions on your Ubuntu system. 

## 3. App Server Set-up

The second EC2 will host the banking app. The following requirements must be installed to ensure the application is deployed properly.

- Install software-properties-common: `sudo apt install -y software-properties-common`
- Add the deadsnakes repository for Python 3.7: `sudo add-apt-repository -y ppa:deadsnakes/ppa`
- Install Python 3.7: `sudo apt install -y python3.7`
- Install Python 3.7 virtual environment: `sudo apt install -y python3.7-venv`

## 4. Jenkins Pipeline
Most people use GitHub as their repository platform. The code will be pulled from a GitHub repository that has been created as it is a more practical approach.

- Create a new Jenkins item and select "Multi-branch pipeline."
  - Configure Jenkins Credentials Provider as needed.
- Copy and import the Repository URL where the application source code resides.
- Use your GitHub username and the generated key from GitHub as your credentials.
- since there are two versions of Jenkinsfile ensure that the version you are running reflects this section in the build configuration
- Run build and view logs
- The application won't deploy because it hasn't been configured, however, given the first log, the repo local path can be found. This path will be used to send the required files from the Jenksins server to the application server. 

## 5. File Transfer and Execution (Jenkinsfilev1)

As previously mentioned, `setup.sh` must be copied to the App server since the application won't be hosted on the Jenkins server. This step becomes part of the Jenkins pipeline, automating server changes. The following script was created and installed in the Jenkins

- Copy `setup.sh` to the App server: `scp /var/lib/jenkins/workspace/Deployment_5_main/setup.sh ubuntu@AppIP:/home/ubuntu` This is where the path from [Declarative: Checkout SCM](https://github.com/kevingonzalez7997/Terraform_D5/blob/main/Results/SCM_Path.png)
- SSH into the App server and run the setup script: `ssh ubuntu@App.IP 'bash -s </home/ubuntu/setup.sh'`

With the SSH connection established, `bash -s` reads from standard input, and input redirection (`<`) provides the script to `bash` from a file.

## 6. File Transfer and Execution (jenkinsfilev2)

The application runs twice, each time with distinct configurations. In the second Jenkins config file, a kill script is incorporated, allowing for the redeployment of new information.

- Copy `setup.sh` to the App server: `scp /var/lib/jenkins/workspace/Deployment_5_main/setup.sh ubuntu@AppIP:/home/ubuntu`
- SSH into the App server and run the setup script: `ssh ubuntu@App.IP 'bash -s </home/ubuntu/setup.sh'`

- Copy `pkill.sh` to the App server: `scp /var/lib/jenkins/workspace/Deployment_5_main/pkill.sh ubuntu@AppIP:/home/ubuntu`
- Run the pkill script on the App server: `ssh ubuntu@AppIP 'bash -s' </home/ubuntu/pkill.sh`
### 7. AWS permissions
- select the current working instance
	- `Actions>Security>Modify IAM role>CloudWatchAgentServer Role`
This is important as this will allow Cloudwatch to have access to the EC2 and access log files

### 8. Installing CloudWatch
Minimizing downtime is one of the main concepts for a successful application. To optimize the application from the previous build a monitor system has been implemented. Since we are using AWS, Cloudwatch was utilized to maintain the native Integration. Another pro is that, it is more cost-efficient as you only pay for the services that you need.

To install run
-`Wget https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb` to download the install package file

-`sudo dpkg -i -E ./amazon-cloudwatch-agent.deb` to run the install package

-`cd /opt/aws/amazon-cloudwatch-agent/bin/` cd into app location 

-`sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard`
This will launch the setup wizard and allow you to configure in greater detail

-`/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json`
Will launch the agent, status can be checked with:
-`sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status`


## TroubleShooting
1. **Establish SSH Connection**: Before initiating the deployment script, verify that an SSH connection has been successfully established. If an SSH connection isn't established, SSH issues can be ruled out as the root cause.

2. **Running the "setup" File**: When executing the "setup" file, make sure it's done after establishing the SSH connection. Running it prematurely may lead to permission [errors](https://github.com/kevingonzalez7997/Terraform_D5/blob/main/Results/First_build.png). (Optional)To avoid this, use the following command:
`bash -s < setup_script.sh`

3. **Multi-Branch Jenkins**: If Jenkins is not displaying any steps, particularly in a multi-branch setup, confirm that the correct version of [Jenkinsfilev](https://github.com/kevingonzalez7997/Terraform_D5/blob/main/Results/Jenkinsfile_version.png) is selected.

4. **Server Loggin**: If no password is created for Jenkins, a default might be generated. Sign out reset the password and try again.

## Obersvations

- When creating a route table, terraform creates a default table. It can be referenced to the VPC attaching it to the IGW. This is more efficient than creating a routing table and then having to associate it with the subnets and gateway.
- When an EC2 is shut down and relaunched a new public IP is associated. The private IP can be used to further streamline the pipeline. 

## Optimization 
- Evaluating the deployment and resource monitoring, a potential option might be to launch a large EC2 instance. Given that there isn't significant traffic and usage remains moderate, the CPU utilization doesn't exceed [50%](https://github.com/kevingonzalez7997/Terraform_D5/tree/main/Results). This consideration aims to guarantee uninterrupted access for users.
- The utilization of modules and variables could also enhance the functionality of Terraform.
- The application is also a single point of failure and could be replicated to further increase resiliency 
## Conclusion 
In conclusion, this deployment employs Terraform (Infrastructure as Code) for infrastructure provisioning to host a banking application server. Jenkins is integrated for automated building and testing, with webhooks serving as triggers. Gunicorn is the selected application hosting solution. Monitoring was introduced with CloudWatch for system resource monitoring, no metric or issues were identified, confirming the deployment's robustness and stability.
