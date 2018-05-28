# escape=`
FROM microsoft/aspnet
EXPOSE 81 4022 4023
# https://www.richard-banks.org/2017/02/debug-net-in-windows-container.html
RUN Invoke-WebRequest -OutFile c:\rtools_setup_x64.exe -Uri https://aka.ms/vs/15/release/RemoteTools.amd64ret.enu.exe;
RUN & 'c:\rtools_setup_x64.exe' /install /quiet

ADD ./SetupBasicTools.ps1 /SetupBasicTools.ps1
ADD ./SetupBasicIIS.ps1 /SetupBasicIIS.ps1
ADD ./Setup.ps1 /Setup.ps1

RUN powershell -NoProfile -File C:\Setup.ps1