# CocoChat App



CocoChat android and ios application.



# how to build

## 1、install flutter



## 2、install dependencies

```
flutter pub get
```

## 3、build apk

need a long time.

### 3.1 install android sdk

### 3.2 install dependencies

```bash
flutter pub get
```

### 3.3 create sign file

use the follow command to create sign file, notice to replace storepass and keypass.

```bash
cd ocochat-app/android
keytool -genkey -v -keystore app/cocochat-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias cocochat -storepass xxxx -keypass yyyy -dname "CN=zimu, OU=zimu, O=zimu, L=Beijing, ST=Beijing, C=CN"
```

signed file will be stored to : app/cocochat-release.jks

### 3.4 create key.properties

android\key.properties

```ini
storePassword=xxxx
keyPassword=yyyy
keyAlias=cocochat
storeFile=cocochat-release.jks
```

### 3.5 build

build release version

```bash
flutter build apk --release
```

## 4、build ios

TODO

