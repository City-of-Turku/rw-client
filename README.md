# Resource wise recycling system mobile client application

License: GPLv3

A mobile application client for managing internal recycling of products, using
barcodes for tracking products.

Products can be just about anything, but in the scope of this project includes
furniture, devices, etc

Currently implemented features are:

* Browsing available products
* Searching of products
* Adding products (picture, barcode, attributes)

Planned features include
* Making orders
* Managing orders

Part of a City of Turku internal furniture recycling pilot project, funded by City of Turku and Sitra.

The client application is meant for Android devices, but should run as a desktop application too.

The Android version has also been tested to run on deviecs with Android runtimes (Sailfish OS & BlackBerry 10)

Contains: 
* A copy of qexifimageheader, originaly from Qt Extended 4.5
* Pre-built Android armv7 OpenSSL library binaries
* Subway icons, https://github.com/mariuszostrowski/subway, CC-SA 4.0

Requires:
* qt5-barcodevideofilter, https://github.com/oniongarlic/qt5-barcodevideofilter

# Background

Part of a City of Turku internal furniture recycling pilot project, funded by City of Turku and Sitra.

# Requirements

## Configuration

The client needs to be configured with URL to API server and API Key. They
are defined in a .pri file that gets included by the main rw-client.pro project file.

See profiles directory for an example.

### API Proxy configuration
* API_KEY needs to be set to a random string shared by the client and the API proxy
* API_SERVER_PRODUCTION must point to the intended production environment API
* API_SERVER_SANDBOX should point to a development setup of the API proxy

### Application settings

* APP_NAME
* APP_ORG
* APP_DOMAIN

See http://doc.qt.io/qt-5/qcoreapplication.html#applicationName-prop

## Building

* Linux environment (not tested on OS X/Windows, but should work)
* Qt 5.8.0 or later
* Android SDK & NDK

## Kits

Configure the project to use Desktop 5.8.0 & Android armv7/x86 5.8.0 Qt kits.

The source tree contains a pre-built OpenSSL for armv7 Android that needs to be
included when packaged for https connections to work.

## Debug build

* Build & run

## Release build

* Android release build needs a certificate

# Usage

The client application talks with a API proxy, the proxy code is available at
* https://github.com/DigiTurku/rw-apiproxy

The API_URL build time defined must point to a API endpoint serviced by the API proxy.

Setup of the API proxy & backend service is out of scope for this client application.
