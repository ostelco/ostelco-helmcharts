# OSTELCO Helm Charts

[![CircleCI](https://circleci.com/gh/ostelco/ostelco-helmcharts/tree/master.svg?style=svg&circle-token=783d0e9de3673a1c0a24f414219654a03c91a3a9)](https://circleci.com/gh/ostelco/ostelco-helmcharts/tree/master)

This repo contains ostelco helm charts source code.

## Using the charts

The charts are continuously built and pushed to a Helm repo. The repo is public and can be used as follows:

```
helm repo add ostelco https://storage.googleapis.com/pi-ostelco-helm-charts-repo/
helm repo update
helm search ostelco
```