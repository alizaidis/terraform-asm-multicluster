echo "Starting a fresh run on project: $1 in ~/run/$1/"
export PROJECT_ID=$1
mkdir ~/run/$1 && cd ~/run/$1
git clone https://github.com/alizaidis/terraform-asm-multicluster.git
cd terraform-asm-multicluster && git checkout issue-2
gcloud config set project $PROJECT_ID
echo "project_id = \"$PROJECT_ID\"" > terraform.tfvars
gsutil mb -p ${PROJECT_ID} gs://${PROJECT_ID}-tfstate
gsutil versioning set on gs://${PROJECT_ID}-tfstate
terraform init -backend-config="bucket=${PROJECT_ID}-tfstate"
terraform plan
terraform apply --auto-approve
gcloud builds submit --region=us-west1 --worker-pool="projects/${PROJECT_ID}/locations/us-west1/workerPools/private-build-pool" --config cloudbuild.yaml .
