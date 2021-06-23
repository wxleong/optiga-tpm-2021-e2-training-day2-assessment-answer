# Introduction

This guide is intended for Ubuntu only (tested on Ubuntu 18.04.5 LTS). 

# Answer

<p align="center">
    <img src="https://github.com/wxleong/optiga-tpm-2021-e2-training-day2-assessment-answer/blob/master/media/iot-core-final-assessment.jpg" width="80%">
</p>

1. Launch the Microsoft TPM 2.0 simulator and leave it running in the background.
    ```
    $ cd ~
    $ tpm2-simulator
    ```

2. Download the repository:
    ```
    $ git clone https://github.com/wxleong/optiga-tpm-2021-e2-training-day2-assessment-answer ~/optiga-tpm-2021-e2-training-day2-assessment-answer
    ```

3. Install dependencies (e.g., [AWS Command Line Interface](https://aws.amazon.com/cli/), [command-line JSON processor](https://stedolan.github.io/jq/)).
    ```
    $ sudo apt install awscli jq git
    $ sudo snap install cmake --classic
    ```
    Set up git with your user name and email.
    ```
    $ git config --global user.name "your name"
    $ git config --global user.email your-email@example.com
    ```

4. Set AWS account credential and region.
    ```
    $ aws configure
    AWS Access Key ID [None]: <YOUR-PERSONAL-ACCESS-KEY-ID>
    AWS Secret Access Key [None]: <YOUR-PERSONAL-SECRET-ACCESS-KEY>
    Default region name [None]: ap-southeast-1
    Default output format [None]: json
    ```
    Check if the configuration is done correctly.
    ```
    $ cat ~/.aws/credentials
    $ cat ~/.aws/config
    ```

5. Get the AWS IoT endpoint and save it for later.
    ```
    $ aws iot describe-endpoint --endpoint-type iot:Data-ATS
    ```

<ins><b>Step 1: Provisioning & Onboarding</b></ins>

6. Device onboarding. First, navigate to:
    ```
    $ cd ~/optiga-tpm-2021-e2-training-day2-assessment-answer/ubuntu/assessment-mssim-aws-iot
    ```
    Go to the file `config.jsn` and edit the parameters (`ThingName` and `PolicyName`) to include your name so that you can be identified for later assessment (**no spaces allowed**):
    ```
    {
      "ThingName": "tpm-e2-training-day2-thing-<YOUR-NAME>",
      "PolicyName": "tpm-e2-training-day2-policy-<YOUR-NAME>"
    }
    ```
    The John Doe sample:
    ```
    {
      "ThingName": "tpm-e2-training-day2-thing-john-doe",
      "PolicyName": "tpm-e2-training-day2-policy-john-doe"
    }
    ```
    Finally, execute the scripts:
    ```
    $ ./0_clean-up.sh
    $ ./1_init-key.sh
    $ ./2_gen_csr.sh
    $ ./3_create_awsiot_thing.sh
    $ ls out/
    ```
    You will receive AmazonRootCA1.pem.crt (ca certificate) and tpm.crt (device certificate).

7. Sign in to your [AWS IoT account](https://ap-southeast-1.console.aws.amazon.com/). Select the option of `IAM user`.
    <p align="center">
        <img src="https://github.com/wxleong/optiga-tpm-2021-e2-training-day2/blob/master/media/iot-core-iam-page.jpg" width="70%">
    </p>
    
    Sign in using your IAM user account.
    <p align="center">
        <img src="https://github.com/wxleong/optiga-tpm-2021-e2-training-day2-assessment-answer/blob/master/media/iot-core-signin-page.jpg" width="70%">
    </p>

    Confirm that you are in the right region.
    <p align="center">
        <img src="https://github.com/wxleong/optiga-tpm-2021-e2-training-day2-assessment-answer/blob/master/media/iot-core-region.jpg" width="70%">
    </p>

    Navigate to IoT Core (search for the keyword "IoT Core")  
    <p align="center">
        <img src="https://github.com/wxleong/optiga-tpm-2021-e2-training-day2-assessment-answer/blob/master/media/iot-core-navigate.jpg" width="70%">
    </p>
    
8. To verify if device onboarding step is sucessful (showing here is the John Doe sample). First, check if a thing has been created.
    <p align="center">
        <img src="https://github.com/wxleong/optiga-tpm-2021-e2-training-day2-assessment-answer/blob/master/media/iot-core-things-page.jpg" width="70%">
    </p>
    
    Click on the thing and check if there is a certificate attached to it.
    <p align="center">
        <img src="https://github.com/wxleong/optiga-tpm-2021-e2-training-day2-assessment-answer/blob/master/media/iot-core-cert-page.jpg" width="70%">
    </p>
    
    Click on the certificate to view the details.
    <p align="center">
        <img src="https://github.com/wxleong/optiga-tpm-2021-e2-training-day2-assessment-answer/blob/master/media/iot-core-cert-details-page.jpg" width="70%">
    </p>
    The certificate id is the SHA-256 hash of a device certificate. You can generate this value by:

    ```
    $ cd ~/optiga-tpm-2021-e2-training-day2-assessment-answer/ubuntu/assessment-mssim-aws-iot
    $ openssl x509 -noout -fingerprint -sha256 -in out/tpm.crt
    ```

    Check if there is a policy attached to the certificate.
    <p align="center">
        <img src="https://github.com/wxleong/optiga-tpm-2021-e2-training-day2-assessment-answer/blob/master/media/iot-core-policy-page.jpg" width="70%">
    </p>
    
    Click on the policy to view the details.
    <p align="center">
        <img src="https://github.com/wxleong/optiga-tpm-2021-e2-training-day2-assessment-answer/blob/master/media/iot-core-policy-details-page.jpg" width="70%">
    </p>

<ins><b>Step 2: Connect Device to AWS IoT Core</b></ins>

9. Download the AWS IoT Device SDK and work on tag 202103.00.
    ```
    $ git clone https://github.com/aws/aws-iot-device-sdk-embedded-c ~/aws-iot-device-sdk-embedded-c
    $ cd ~/aws-iot-device-sdk-embedded-c
    $ git checkout 202103.00
    $ git submodule update --init --recursive
    ```

10. Patch the AWS IoT Device SDK to enable TPM OpenSSL engine and to disable TPM platform hierarchy.
    ```
    $ cd ~/aws-iot-device-sdk-embedded-c
    $ git am ~/optiga-tpm-2021-e2-training-day2-assessment-answer/ubuntu/integrate-tpm.patch
    ```
    <!-- $ git am ~/optiga-tpm-2021-e2-training-day2-assessment-answer/ubuntu/disable-tpm-platform-hierarchy.patch -->

11. Generate build files. <br>
    Edit the command line to include the endpoint, client identifier, and name of the thing (**no spaces allowed**):
    ```
    $ cd ~/aws-iot-device-sdk-embedded-c
    $ cmake -S. -Bbuild \
      -DAWS_IOT_ENDPOINT="<ENDPOINT-FROM-STEP-5>" \
      -DTHING_NAME="<THINGNAME-FROM-STEP-6>" \
      -DCLIENT_IDENTIFIER="<YOUR-NAME>" \
      -DROOT_CA_CERT_PATH="${HOME}/optiga-tpm-2021-e2-training-day2-assessment-answer/ubuntu/assessment-mssim-aws-iot/out/AmazonRootCA1.pem.crt" \
      -DCLIENT_PRIVATE_KEY_PATH="/ignored" \
      -DCLIENT_CERT_PATH="${HOME}/optiga-tpm-2021-e2-training-day2-assessment-answer/ubuntu/assessment-mssim-aws-iot/out/tpm.crt"
    ```
    The John Doe sample:
    ```
    $ cmake -S. -Bbuild \
      -DAWS_IOT_ENDPOINT="4389ntvsaefag8-ats.iot.ap-southeast-1.amazonaws.com" \
      -DTHING_NAME="tpm-e2-training-day2-thing-john-doe" \
      -DCLIENT_IDENTIFIER="john-doe" \
      -DROOT_CA_CERT_PATH="${HOME}/optiga-tpm-2021-e2-training-day2-assessment-answer/ubuntu/assessment-mssim-aws-iot/out/AmazonRootCA1.pem.crt" \
      -DCLIENT_PRIVATE_KEY_PATH="/ignored" \
      -DCLIENT_CERT_PATH="${HOME}/optiga-tpm-2021-e2-training-day2-assessment-answer/ubuntu/assessment-mssim-aws-iot/out/tpm.crt"
    ```
    The output should look like this:
    <p align="center">
        <img src="https://github.com/wxleong/optiga-tpm-2021-e2-training-day2-assessment-answer/blob/master/media/aws-iot-sdk-cmake.jpg" width="100%">
    </p>

12. Build sample applications.
    ```
    $ cd ~/aws-iot-device-sdk-embedded-c/build
    $ make -j$(nproc)
    ```

13. Start the sample application mqtt_demo_mutual_auth and leave it running. 
    ```
    $ cd ~/aws-iot-device-sdk-embedded-c/build/bin
    $ ./mqtt_demo_mutual_auth
    ```
    The output should look like this:
    <p align="center">
        <img src="https://github.com/wxleong/optiga-tpm-2021-e2-training-day2-assessment-answer/blob/master/media/aws-iot-sdk-sample-app.jpg" width="100%">
    </p>

14. Back to the AWS IoT Core website, click on the "Test" option to enter MQTT test client. Subscribe to the topic `<CLIENT_IDENTIFIER>/example/topic` (The John Doe sample: `john-doe/example/topic`). You will see the message "Hello World!"
    <p align="center">
        <img src="https://github.com/wxleong/optiga-tpm-2021-e2-training-day2-assessment-answer/blob/master/media/iot-core-test-page.jpg" width="70%">
    </p>

15. Stop the running application before deleting the onboarded device from AWS IoT Core.
    ```
    $ cd ~/optiga-tpm-2021-e2-training-day2-assessment-answer/ubuntu/assessment-mssim-aws-iot
    $ ./4_clean_awsiot_thing.sh