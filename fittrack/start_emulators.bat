@echo off
set "JAVA_HOME=C:\Users\joelh\dev\OpenJDK\jdk-24.0.2"
set "PATH=C:\Users\joelh\dev\OpenJDK\jdk-24.0.2\bin;%PATH%"
firebase emulators:start --only auth,firestore