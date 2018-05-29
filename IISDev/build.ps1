Write-Host Building registry binary and image

$version = $env:GitVersion_NuGetVersionV2
Write-Host "Version is $version"

docker build -t iisdev .
docker tag iisdev:latest iisdev:$version
docker tag iisdev:latest dazinator/dev:latest
