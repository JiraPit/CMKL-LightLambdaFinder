gcloud auth configure-docker asia-southeast1-docker.pkg.dev
gcloud config set project cmkl-lambdafinder
docker login -u _json_key --password-stdin asia-southeast1-docker.pkg.dev/ <cmkl-lambdafinder-e9e5e1e1144e.json
docker build -t asia-southeast1-docker.pkg.dev/cmkl-lambdafinder/lambda-finder/lambda-finder .
docker push asia-southeast1-docker.pkg.dev/cmkl-lambdafinder/lambda-finder/lambda-finder
