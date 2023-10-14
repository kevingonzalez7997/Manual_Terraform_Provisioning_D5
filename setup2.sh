#!/bin/bash
rm -rf Terraform_D5
source test/bin/activate
git clone https://github.com/kevingonzalez7997/Terraform_D5.git
cd Terraform_D5
pip install -r requirements.txt
pip install gunicorn
python database.py
sleep 1
python load_data.py
sleep 1 
python -m gunicorn app:app -b 0.0.0.0 -D && echo "Done"
