SSL Certificate & Java Keystore Generator

Automated Utility for Windows

1. Overview

This utility is a Windows Batch script designed to automate the complex process of creating SSL
certificates for Java-based applications (such as CAST Imaging, Tomcat, or Jetty).

It performs the following actions automatically:

1. Environment Check: Verifies if OpenSSL and Java Keytool are installed.
2. Self-Signed Generation: Creates a private key and a self-signed public certificate.
3. Format Conversion: Bundles the keys into a PKCS#12 (.p12) format.
4. Keystore Creation: Imports the keys into a Java Keystore (.jks) with a custom Alias.
2. Prerequisites

Before running the script, ensure the following:

- Operating System: Microsoft Windows (10, 11, or Server).
- Java: JRE or JDK must be installed, and the keytool command must be accessible in the
    system PATH.
- Permissions: It is recommended to run the script as Administrator to ensure file write
    permissions and software installation (if needed).
3. The Script (SSL_Creator.bat) is attached
4. How to Use

Step 1: Run the Script

1. Navigate to the folder where SSL_Creator.bat is saved.
2. Right-click the file and select Run as Administrator.

Step 2: OpenSSL Check

- If OpenSSL is installed, the script proceeds immediately.
- If OpenSSL is missing:
    1. The script will automatically open the download page in your browser.
    2. Download the Win64 OpenSSL v3.x Light installer.
    3. Run the installer (use default settings).
    4. Return to the script window and press any key to continue.

Step 3: Enter Certificate Details

The script will prompt you for three inputs:

1. FQDN (Fully Qualified Domain Name):


```
o Enter the hostname of the server (e.g., myserver.company.com or localhost).
```
```
o If you leave this blank, it defaults to localhost.
```
2. Alias Name:

```
o Enter the identifier for the certificate inside the keystore
(e.g., tomcat, jetty, cast_gateway).
```
```
o If you leave this blank, it defaults to gateway.
```
3. Password:

```
o Enter a strong password. You will need this password later to configure your
application (e.g., server.xml).
```
Step 4: Completion

The script will generate the files and display a verification message showing the Alias Name inside
the keystore.

5. Output Files Explained

After the script finishes, you will find four files in the folder:

File Name Description

gateway.jks

```
Primary File. The Java Keystore containing the full certificate chain. Point your
Java application (Tomcat/Jetty) to this file.
```
public_key.crt
The public certificate. Distribute this to clients or import it into truststores if
needed.

private_key.key The raw private key. Keep this secure.

gateway.p

```
An intermediate format (PKCS#12) used to create the JKS. Can be used by non-
Java applications.
```
6. Troubleshooting

Error: 'keytool' command not found

- Cause: Java is not installed or not in the System PATH.
- Fix: Install Java (OpenJDK or Oracle JDK). Ensure bin folder is added to Environmental
    Variables.

Error: OpenSSL not found (after installing)

- Cause: You may have installed OpenSSL to a custom location.
- Fix: The script checks C:\Program Files\OpenSSL-Win64. If installed elsewhere, restart the
    script; the new PATH variable might not be active yet.


Browser Warning: "Not Secure"

- Cause: This script creates a Self-Signed Certificate. Browsers do not trust self-signed certs
    by default.
- Fix: This is normal for internal testing. You can proceed past the warning in the browser.
    For production, you must use a CA-signed certificate.


