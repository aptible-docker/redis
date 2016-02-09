#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

REDIS_NAME="redis-${REDIS_VERSION}"
REDIS_ARCHIVE="${REDIS_NAME}.tar.gz"
REDIS_URL="http://download.redis.io/releases/${REDIS_ARCHIVE}"
REDIS_BUILD_DEPS=(alpine-sdk linux-headers)

apk-install "${REDIS_BUILD_DEPS[@]}"

redis_build_dir="/tmp/redis-build"
mkdir "${redis_build_dir}"
pushd "${redis_build_dir}"

wget "${REDIS_URL}"
echo "${REDIS_SHA1SUM}  ${REDIS_ARCHIVE}" | sha1sum -c -
tar -xf "${REDIS_ARCHIVE}"
pushd "${REDIS_NAME}"

# Get the Alpine Linux no backtrace patch. Backtrace isn't available in Muslc,
# but Redis 2.8.x doesn't check for Glibc before enabling it.
NO_BACKTRACE_PATCH="redis-no-backtrace.patch"
wget "https://raw.githubusercontent.com/alpinelinux/aports/115f0915bb5bb7c9c36b43c7fbfe0dd11435580c/main/redis/${NO_BACKTRACE_PATCH}"

patch -p1 -i "./${NO_BACKTRACE_PATCH}"

make all PREFIX=/usr/local MALLOC=libc
make install

popd
popd

rm -rf "${redis_build_dir}"
apk del "${REDIS_BUILD_DEPS[@]}"
