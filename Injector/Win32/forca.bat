for /F "TOKENS=1,2,*" %%a in ('tasklist /FI "IMAGENAME eq WoW.exe"') do set MyPID=%%b
echo %MyPID%