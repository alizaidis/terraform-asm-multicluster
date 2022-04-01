# terraform-asm-multicluster
Example pattern showcasing a multi cluster implementation of Anthos Service Mesh with private GKE clusters using Terraform.

# Installing Anthos Service Mesh on GKE with ASM Terraform module.

## Prerequistes 

1. This tutorial has been tested on [Cloud Shell](https://shell.cloud.google.com) which comes preinstalled with [Google Cloud SDK](https://cloud.google.com/sdk) and [Terraform](https://www.terraform.io/) which are required to complete this tutorial.

2. It is recommended to start the tutorial in a fresh project since the easiest way to clean up once complete is to delete the project. See [here](https://cloud.google.com/resource-manager/docs/creating-managing-projects) for more details.

## Deploy resources using Terraform.

1. Define the environment variables and set project. Replace `YOUR_PROJECT_ID` with that of a fresh project you created for this tutorial. Set the values of `GKE_CHANNEL` and `ENABLE_CNI` according to your requirements.

    ```
    export PROJECT_ID=YOUR_PROJECT_ID
    export GKE_CHANNEL="REGULAR"
    export ENABLE_CNI="false"
    gcloud config set project ${PROJECT_ID}
    ```

1. Create a working directory, clone this repo and switch to the appropriate branch

    ```bash
    mkdir ~/asm-tutorial && cd ~/asm-tutorial && export WORKDIR=$(pwd)
    git clone https://github.com/alizaidis/terraform-asm-sample.git
    cd terraform-asm-sample/terraform
    ```

1. Initialize, plan and apply Terraform to create VPC, Subnet, GKE cluster with private nodes and ASM. Type `yes` when Terraform apply asks to confirm.

    ```bash
    envsubst < variables.tf.tmpl > variables.tf
    terraform init
    terraform plan
    terraform apply
    ```

## Verify successful ASM installation

1. Verify that the GKE cluster membership to a Fleet was successful:

    ```bash
    gcloud container hub memberships list --project $PROJECT_ID
    ```

1. Inspect GKE cluster to verify that ASM was installed correctly. Start by getting cluster credentials.

    ```bash
    gcloud container clusters get-credentials "asm-cluster-1" --region "us-central1" --project $PROJECT_ID
    ```

1. Inspect the status of controlplanerevision CustomResource. Note values of fields under `Conditions`, you should see that `Reason` is set to `Provisioned` and that the provisioning process has completed successfully.

    ```bash
    kubectl describe controlplanerevision asm-managed -n istio-system
    ```

    The output is similar to the following:

    ```
        Name:         asm-managed
        Namespace:    istio-system
        Labels:       mesh.cloud.google.com/managed-cni-enabled=true
        Annotations:  <none>
        API Version:  mesh.cloud.google.com/v1beta1
        Kind:         ControlPlaneRevision
        Metadata:
        Creation Timestamp:  2022-02-04T19:10:56Z
        Generation:          1
        Managed Fields:
            API Version:  mesh.cloud.google.com/v1beta1
            Fields Type:  FieldsV1
            fieldsV1:
            f:metadata:
                f:annotations:
                .:
                f:kubectl.kubernetes.io/last-applied-configuration:
                f:labels:
                .:
                f:mesh.cloud.google.com/managed-cni-enabled:
            f:spec:
                .:
                f:channel:
                f:type:
            Manager:      kubectl-client-side-apply
            Operation:    Update
            Time:         2022-02-04T19:10:56Z
            API Version:  mesh.cloud.google.com/v1alpha1
            Fields Type:  FieldsV1
            fieldsV1:
            f:status:
                .:
                f:conditions:
            Manager:         Google-GKEHub-Controllers-Servicemesh
            Operation:       Update
            Time:            2022-02-04T19:12:50Z
        Resource Version:  14573
        UID:               2b7d5d2c-438d-4a14-9c62-625545ac80d7
        Spec:
        Channel:  regular
        Type:     managed_service
        Status:
        Conditions:
            Last Transition Time:  2022-02-04T19:18:04Z
            Message:               The provisioning process has completed successfully
            Reason:                Provisioned
            Status:                True
            Type:                  Reconciled
            Last Transition Time:  2022-02-04T19:18:04Z
            Message:               Provisioning has finished
            Reason:                ProvisioningFinished
            Status:                True
            Type:                  ProvisioningFinished
            Last Transition Time:  2022-02-04T19:18:04Z
            Message:               Provisioning has not stalled
            Reason:                NotStalled
            Status:                False
            Type:                  Stalled
        Events:                    <none>
    ```
    
1. Review the status of the controlplanerevision custom resource named asm-managed, the `RECONCILED` field should be set to `True`.
    
    ```bash
    kubectl get controlplanerevisions -n istio-system
    ```

    The output is similar to the following:

    ```bash
            NAME          RECONCILED   STALLED   AGE
            asm-managed   True         False     14m
    ```

1. Review the `ConfigMaps` in the istio-system namespace.

    ```bash
    kubectl get configmaps -n istio-system
    ```

    The output is similar to the following:
 
    ```bash
        NAME                   DATA   AGE
        asm-options            1      20m
        env-asm-managed        3      8m2s
        istio-asm-managed      1      20m
        istio-gateway-leader   0      8m1s
        istio-leader           0      8m1s
        kube-root-ca.crt       1      20m
        mdp-eviction-leader    0      12m
    ```

## Clean up

1. The easiest way to prevent continued billing for the resources that you created for this tutorial is to delete the project you created for the tutorial. Run the following command from Cloud Shell and enter `y` when asked to confirm.

   ```bash
    gcloud config unset project
    echo y | gcloud projects delete $PROJECT_ID
    rm -rf $WORKDIR
    ```
