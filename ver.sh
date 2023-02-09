#/bin/bash
sed -ie "s#tag: \"develop\"#tag: \"$MS_VERSION\"#g" ./helm/charts/dataflow/charts/$MS_NAME/values.yaml
sed -ie "s#version: 0.0.1#version: \"$MS_VERSION\"#g" ./helm/charts/dataflow/charts/$MS_NAME/Chart.yaml
sed -ie "s#appVersion: \"0.0.1\"#appVersion: \"$MS_VERSION\"#g" ./helm/charts/dataflow/charts/$MS_NAME/Chart.yaml