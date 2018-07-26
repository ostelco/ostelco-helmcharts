#!/bin/bash

function gcloud_auth() {
  # populating the json credentials file from env variable
  if [ ! -z "${GOOGLE_CREDENTIALS}" ]; then
    echo $GOOGLE_CREDENTIALS > /tmp/credentials.json
    if [ $? != 0 ]; then
        echo "FAILED to write Google credentials into /tmp/credentials.json. Aborting!"
        exit 1
    else
      echo "Successfully populated /tmp/credentials.json"
      gcloud auth activate-service-account --key-file /tmp/credentials.json
      if [ $? != 0 ]; then
          echo "FAILED to authenticate to Google cloud. Aborting!"
          exit 1
      else
        echo "Successfully authenticated to Google cloud."
      fi
    fi
  else
    echo "Google credentials have not been set in the environment. Aborting!"
    exit 1
  fi
}

function sanity_check() {
  if [ -z "${GOOGLE_CREDENTIALS}" ]; then
    echo "GOOGLE_CREDENTIALS found empty. Exiting ..."
    exit 1
  fi

  if [ -z "${OSTELCO_HELM_REPO_NAME}" ]; then
    echo "OSTELCO_HELM_REPO_NAME found empty. Exiting ..."
    exit 1
  fi

  if [ -z "${OSTELCO_GCS_HELM_REPO_BUCKET_NAME}" ]; then
    echo "OSTELCO_GCS_HELM_REPO_BUCKET_NAME found empty. Exiting ..."
    exit 1
  fi
}

echo "performing sanity checks ..."
sanity_check

echo "authenticating to gcloud ..."
gcloud_auth

echo "initializing helm ..."
helm init --client-only

echo "creating repo URLs ..."
export OSTELCO_GCS_HELM_REPO_URL="https://storage.googleapis.com/${OSTELCO_GCS_HELM_REPO_BUCKET_NAME}/"

echo "adding helm repo ..."
helm repo add ${OSTELCO_HELM_REPO_NAME} ${OSTELCO_GCS_HELM_REPO_URL}

echo "creating .charts directory ..."
mkdir -p .charts

echo "linting ..."
for d in */ ; do
    echo "linting package $d"
    helm lint $d
    if [ $? -gt 0 ]; then
    echo "Package $d has errors ... Terminating!"
    exit 9
    fi
done

echo "packaging ..."
for d in */ ; do
    if [ "$d" != "docs/" ]; then     
      echo "packaging chart $d"
      helm package --dependency-update $d -d .charts
      if [ $? -gt 0 ]; then
        echo "Package $d has errors ... Terminating!"
        exit 9
      fi
    fi  
done


echo "generating index.yaml ..."
helm repo index .charts --url ${OSTELCO_GCS_HELM_REPO_URL}

echo "pushing charts to ${OSTELCO_HELM_REPO_NAME} repo ..."

# pushing charts to s3
gsutil cp -r .charts gs://${OSTELCO_HELM_REPO_NAME}/
if [ $? -gt 0 ]; then
    echo "Failed to push charts to GCS ... Terminating!"
    exit 9
fi

echo "updating repo ..."
helm repo update

echo "listing charts in ${OSTELCO_HELM_REPO_NAME} repo ..."
helm search ${OSTELCO_HELM_REPO_NAME}