#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

mkdir -p ${PREFIX}/bin
mkdir -p ${PREFIX}/libexec/${PKG_NAME}

# Build package with dotnet publish
rm NuGet.config
tee ${SRC_DIR}/NuGet.config << EOF
<configuration>
  <packageSources>
    <add key="arcade" value="https://pkgs.dev.azure.com/dnceng/public/_packaging/dotnet-eng/nuget/v3/index.json" />
    <add key="dotnet-tools" value="https://pkgs.dev.azure.com/dnceng/public/_packaging/dotnet-tools/nuget/v3/index.json" />
  </packageSources>
</configuration>
EOF

mv global.json global_old.json
jq 'del(.tools)' global_old.json > global.json
framework_version="$(dotnet --version | sed -e 's/\..*//g').0"
dotnet publish --no-self-contained src/MSBuild/MSBuild.csproj --output ${PREFIX}/libexec/${PKG_NAME} --framework "net${framework_version}" -p:ErrorOnDuplicatePublishOutputFiles=false

# Create bash and batch wrappers
tee ${PREFIX}/bin/MSBuild << EOF
#!/bin/sh
exec \${DOTNET_ROOT}/dotnet exec \${CONDA_PREFIX}/libexec/msbuild/MSBuild.dll "\$@"
EOF

tee ${PREFIX}/bin/MSBuild.cmd << EOF
call %DOTNET_ROOT%\dotnet exec %CONDA_PREFIX%\libexec\msbuild\MSBuild.dll %*
EOF

# Download dependency licenses wtih dotnet-project-licenses
dotnet-project-licenses --input src/MSBuild/MSBuild.csproj -t -d license-files
