git push -u origin master
gh workflow run build-debian12-service-qmake.yml --ref master
gh run list --workflow="build-debian12-service.yml"

