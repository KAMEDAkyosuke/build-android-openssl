#!/bin/sh

for OPT in "$@"; do
    case $OPT in
        '--api' )
            API=$2
            ;;
    esac
    shift
done

if [ -z $API ]; then
    echo '--api not set.' 1>&2
    exit 1
fi

ORIG_PATH=$PATH
CURRENT_DIR=`pwd`

if [ -z $ANDROID_HOME ]; then
    echo 'environment variable $ANDROID_HOME not set.' 1>&2
    exit 1
fi

NDK=$ANDROID_HOME/ndk-bundle
ARCH=(arm arm64 x86 x86_64)
OS_COMPILER=(android-arm android-arm64 android-x86 android-x86_64)
ANDROID_ABI=(armeabi-v7a arm64-v8a x86 x86_64)

if [ ! -e openssl ]; then
    git clone git@github.com:openssl/openssl.git openssl
fi

cd openssl
git checkout -b OpenSSL_1_1_1-stable remotes/origin/OpenSSL_1_1_1-stable
cd ../


rm -rf include
mkdir include
cp -r openssl/include/openssl include/

rm -rf lib
mkdir lib

rm -rf toolchains

len=$((${#ARCH[@]} - 1))
for i in `seq 0 $len`; do
    cd $CURRENT_DIR
    mkdir -p lib/${ANDROID_ABI[$i]}

    # see. https://developer.android.com/ndk/guides/standalone_toolchain?hl=JA
    $NDK/build/tools/make_standalone_toolchain.py \
        --arch ${ARCH[$i]} \
        --api $API \
        --install-dir=toolchains/${ARCH[$i]}

    # Add the standalone toolchain to the search path.
    export ANDROID_NDK_HOME=`pwd`/toolchains/${ARCH[$i]}
    export PATH=$ORIG_PATH:$ANDROID_NDK_HOME/bin

    # openssl configure create custom bin name, so we do not needs below settings.

    ## Tell configure what tools to use.
    # target_host=aarch64-linux-android
    # export AR=$target_host-ar
    # export AS=$target_host-clang
    # export CC=$target_host-clang
    # export CXX=$target_host-clang++
    # export LD=$target_host-ld
    # export STRIP=$target_host-strip

    # Tell configure what flags Android requires.
    export CFLAGS="-fPIE -fPIC -DOPENSSL_NO_STDIO=1"
    export LDFLAGS="-pie"

    cd openssl

    set +e
    make distclean
    set -e

    ./Configure ${OS_COMPILER[$i]} -D__ANDROID_API__=$API no-ui-console no-stdio no-rc4

    make -j 4

    cp libcrypto.a $CURRENT_DIR/lib/${ANDROID_ABI[$i]}/libcrypto.a
    cp libssl.a $CURRENT_DIR/lib/${ANDROID_ABI[$i]}/libssl.a
done

