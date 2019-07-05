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

The client application is meant for Android devices, but should run as a desktop application too.

The Android version has also been tested to run on deviecs with Android runtimes (Sailfish OS & BlackBerry 10)

Contains: 
* A copy of qexifimageheader, originaly from Qt Extended 4.5
* Pre-built Android armv7/aarch64 OpenSSL library binaries
* Subway icons, https://github.com/mariuszostrowski/subway, CC-SA 4.0

Requires (submodule):
* qt5-barcodevideofilter, https://github.com/oniongarlic/qt5-barcodevideofilter

# Background

Part of a City of Turku internal furniture recycling pilot project, funded by City of Turku and Sitra.

# Requirements

## Configuration

The client needs to be configured with at least one organization profile that sets the API url and key.
Profiles are included from profile.pri, see profiles directory for an example profile definition in 
rw-example-profile directory.

To create your own profile:
* Choose a code for your profile, for example 'mycity'
* Make a copy of the rw-example-profile outside the source tree
* Rename all 'example' files and includes to mycity
* Edit mycity.json add specifiy API key and URLs.
* Include mycity.pri from profile.pri

### Application settings

The applications internal name can be changed in profile.pri, using defines below

* APP_NAME
* APP_ORG
* APP_DOMAIN

See http://doc.qt.io/qt-5/qcoreapplication.html#applicationName-prop

## Building

* Linux environment (not tested on OS X/Windows, but should work)
* Qt 5.12.4 or later
* Android SDK & NDK

## Kits

Configure the project to use Desktop 5.12.4 & Android armv7/aarch64/x86 5.12.4 Qt kits.

The source tree contains a pre-built OpenSSL 1.1.1 for armv7 and aarch64 Android that needs to be
included when packaged for https connections to work.

## Debug build

* Build & run

## Release build

* Android release build needs a certificate, you need to use your own.

# Usage

The client application talks with a API proxy, the proxy code is available at
* https://github.com/City-of-Turku/rw-apiproxy

Setup of the API proxy & backend service is out of scope for this client application.
