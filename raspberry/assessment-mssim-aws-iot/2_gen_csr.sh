#!/bin/bash

export TPM2TSSENGINE_TCTI="mssim:host=localhost,port=2321"

touch ~/.rnd
rm -f out/*.csr 2> /dev/null

if ! command -v jq &> /dev/null
then
  echo "jq could not be found. Install it by $ sudo apt install jq."
  exit
fi

# read from config file
thingname=`jq -r '.ThingName' config.jsn`

# Generate CSR
openssl req -new -engine tpm2tss -keyform engine -key 0x81000001 -subj "/CN=${thingname}/O=Infineon/C=SG" -out out/tpm.csr

# Read cert
#openssl x509 -in out/tpm.csr -text -noout