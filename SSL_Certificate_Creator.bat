@echo off
setlocal EnableDelayedExpansion
title CAST Self-Signed Certificate Generator

REM ==========================================
REM CONFIGURATION
REM ==========================================
set "KEY_NAME=private_key.key"
set "CRT_NAME=public_key.crt"
set "P12_NAME=gateway.p12"
set "JKS_NAME=gateway.jks"
set "ALIAS_NAME=gateway"

REM OpenSSL Download Page
set "OPENSSL_URL=https://slproweb.com/products/Win32OpenSSL.html"

echo ==========================================
echo    CAST SELF-SIGNED CERTIFICATE CREATOR
echo ==========================================
echo.

REM ==========================================
REM CHECK FOR OPENSSL
REM ==========================================
:CHECK_OPENSSL
echo [*] Checking for OpenSSL...

REM Check PATH, Program Files, and Git
where openssl >nul 2>nul
if %errorlevel% EQU 0 goto :OPENSSL_FOUND

if exist "%PROGRAMFILES%\OpenSSL-Win64\bin\openssl.exe" (
    set "PATH=%PROGRAMFILES%\OpenSSL-Win64\bin;%PATH%"
    goto :OPENSSL_FOUND
)
if exist "%PROGRAMFILES%\Git\usr\bin\openssl.exe" (
    set "PATH=%PROGRAMFILES%\Git\usr\bin;%PATH%"
    goto :OPENSSL_FOUND
)

REM Manual Install Prompt
echo.
echo [X] OPENSSL NOT FOUND.
echo ---------------------------------------------------------------------
echo 1. Opening download page: %OPENSSL_URL%
echo 2. Download and install "Win64 OpenSSL v3.x Light".
echo 3. Install to default location.
echo 4. Press ANY KEY here once installed.
echo ---------------------------------------------------------------------
start "" "%OPENSSL_URL%"
pause
goto :CHECK_OPENSSL

:OPENSSL_FOUND
echo [OK] OpenSSL is ready.

REM ==========================================
REM CHECK FOR JAVA KEYTOOL
REM ==========================================
echo.
echo [*] Checking for Java Keytool...
where keytool >nul 2>nul
if %errorlevel% NEQ 0 (
    echo [X] 'keytool' command not found. Please install Java.
    pause
    exit /b 1
)
echo [OK] Java Keytool found.

REM ==========================================
REM USER INPUTS
REM ==========================================
echo.
echo ==========================================
echo              CERTIFICATE DETAILS
echo ==========================================
echo.
echo Please enter the Fully Qualified Domain Name (FQDN) for this machine.
echo (e.g., myserver.company.com or localhost)
echo.
set /p "FQDN=Enter FQDN: "

if "%FQDN%"=="" (
    echo FQDN cannot be empty.
    pause
    exit /b
)

echo.
echo Please create a password for the Keystore.
set /p "KSPASS=Enter Password: "

if "%KSPASS%"=="" (
    echo Password cannot be empty.
    pause
    exit /b
)

REM ==========================================
REM STEP 1: GENERATE SELF-SIGNED CERT & KEY
REM ==========================================
echo.
echo ------------------------------------------
echo STEP 1: Generating Self-Signed Cert
echo ------------------------------------------
echo.

REM -x509 outputs a certificate instead of a CSR
REM -days 3650 makes it valid for 10 years
REM -subj automates the questions (Country, Org, CN)
openssl req -x509 -newkey rsa:2048 -nodes -keyout "%KEY_NAME%" -out "%CRT_NAME%" -days 3650 -subj "/C=US/ST=State/L=City/O=Organization/OU=IT/CN=%FQDN%"

if not exist "%CRT_NAME%" (
    echo [X] Failed to create certificate.
    pause
    exit /b 1
)
echo [OK] Private Key created: %KEY_NAME%
echo [OK] Public Cert created: %CRT_NAME%

REM ==========================================
REM STEP 2: CONVERT TO PKCS#12
REM ==========================================
echo.
echo ------------------------------------------
echo STEP 2: Create PKCS#12 Keystore (.p12)
echo ------------------------------------------
echo.

openssl pkcs12 -export -in "%CRT_NAME%" -inkey "%KEY_NAME%" -name "%ALIAS_NAME%" -out "%P12_NAME%" -passout pass:%KSPASS%

if not exist "%P12_NAME%" (
    echo [X] Failed to create .p12 file.
    pause
    exit /b 1
)
echo [OK] PKCS#12 file created: %P12_NAME%

REM ==========================================
REM STEP 3: CONVERT TO JAVA KEYSTORE (JKS)
REM ==========================================
echo.
echo ------------------------------------------
echo STEP 3: Create Java Keystore (.jks)
echo ------------------------------------------
echo.

if exist "%JKS_NAME%" del "%JKS_NAME%"

keytool -importkeystore -srckeystore "%P12_NAME%" -destkeystore "%JKS_NAME%" -srcstoretype PKCS12 -srcstorepass %KSPASS% -deststorepass %KSPASS%

if not exist "%JKS_NAME%" (
    echo [X] Failed to create .jks file.
    pause
    exit /b 1
)
echo [OK] JKS file created: %JKS_NAME%

REM ==========================================
REM STEP 4: IMPORT TO JAVA TRUSTSTORE (CACERTS)
REM ==========================================
echo.
echo ------------------------------------------
echo STEP 4: Import to Java Truststore (cacerts)
echo ------------------------------------------
echo.
echo [*] Attempting to locate Java cacerts file...

REM Try to find cacerts based on keytool location
for /f "delims=" %%i in ('where keytool') do set "JAVA_BIN=%%~dpi"
REM Remove trailing backslash and bin
set "JAVA_HOME_GUESS=%JAVA_BIN:bin\=%"

set "CACERTS_PATH=%JAVA_HOME_GUESS%lib\security\cacerts"

if not exist "%CACERTS_PATH%" (
    echo [!] Could not automatically find 'cacerts' at: 
    echo     "%CACERTS_PATH%"
    echo.
    echo     You can import it manually later if needed using:
    echo     keytool -import -alias %ALIAS_NAME% -file %CRT_NAME% -keystore "path_to_cacerts"
    goto :FINISH
)

echo [OK] Found cacerts at: "%CACERTS_PATH%"
echo [*] Importing %CRT_NAME% into Truststore...

REM Check if alias already exists and delete it to prevent error
keytool -delete -alias "%FQDN%" -keystore "%CACERTS_PATH%" -storepass changeit >nul 2>nul

REM Import
keytool -import -trustcacerts -alias "%FQDN%" -file "%CRT_NAME%" -keystore "%CACERTS_PATH%" -storepass changeit -noprompt

if %errorlevel% EQU 0 (
    echo [OK] Successfully imported certificate to Java Truststore.
) else (
    echo [X] Failed to import to Truststore. 
    echo     (Note: This usually requires Administrator privileges).
)

:FINISH
echo.
echo ==========================================
echo              PROCESS COMPLETE
echo ==========================================
echo Files generated in %CD%:
echo.
echo 1. Private Key: %KEY_NAME%
echo 2. Public Cert: %CRT_NAME%
echo 3. PKCS12:      %P12_NAME%
echo 4. Java Store:  %JKS_NAME%
echo.
echo Password: %KSPASS%
echo.
pause