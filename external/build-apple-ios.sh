#!/bin/bash -e

IOS_SDK_VERSION="11.0"
# We can go down to 4.2 but -fembed-bitcode needs to be removed then
IOS_MIN_SDK_VERSION="6.0"

TVOS_SDK_VERSION="9.1"
TVOS_MIN_SDK_VERSION="6.0"

DEVELOPER=`xcode-select -print-path`

if [ ! -d "$DEVELOPER" ]; then
  echo "xcode path is not set correctly $DEVELOPER does not exist (most likely because of xcode > 4.3)"
  echo "run"
  echo "sudo xcode-select -switch <xcode path>"
  echo "for default installation:"
  echo "sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer"
  exit 1
fi

case $DEVELOPER in  
     *\ * )
           echo "Your Xcode path contains whitespaces, which is not supported."
           exit 1
          ;;
esac

build_iOS()
{
	ARCH=$1
  
	if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]]; then
		PLATFORM="iPhoneSimulator"
	else
		PLATFORM="iPhoneOS"
	fi
  
	export $PLATFORM
	export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	export CROSS_SDK="${PLATFORM}${IOS_SDK_VERSION}.sdk"
	export BUILD_TOOLS="${DEVELOPER}"
	export CFLAGS="-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -miphoneos-version-min=${IOS_MIN_SDK_VERSION} -fembed-bitcode"
	export CC="${BUILD_TOOLS}/usr/bin/gcc -arch ${ARCH}"

	echo "Building libvncserver for ${PLATFORM} ${IOS_SDK_VERSION} ${ARCH}"
	make rebuild

	mv libvncserver.a /tmp/libvncserver-ios-${ARCH}.a
}

build_iOS "armv7"
build_iOS "armv7s"
build_iOS "arm64"
build_iOS "x86_64"
build_iOS "i386"

lipo \
	"/tmp/libvncserver-ios-armv7.a" \
	"/tmp/libvncserver-ios-armv7s.a" \
	"/tmp/libvncserver-ios-arm64.a" \
	"/tmp/libvncserver-ios-x86_64.a" \
	"/tmp/libvncserver-ios-i386.a" \
	-create -output libvncserver.a

rm -rf /tmp/libvncserver-*.a
