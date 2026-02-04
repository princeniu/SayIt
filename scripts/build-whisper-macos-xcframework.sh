#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUBMODULE_DIR="${ROOT_DIR}/SayIt/SayIt/ThirdParty/whisper.cpp"
OUTPUT_XCFRAMEWORK="${ROOT_DIR}/SayIt/vendor/whisper.cpp/build-apple/whisper.xcframework"
BUILD_DIR="${SUBMODULE_DIR}/build-macos"
HEADERS_DIR="${SUBMODULE_DIR}/build-macos-headers"

if [ ! -d "${SUBMODULE_DIR}" ]; then
  echo "whisper.cpp submodule not found at ${SUBMODULE_DIR}" >&2
  exit 1
fi

mkdir -p "${HEADERS_DIR}"

CC_PATH="$(xcrun --find clang)"
CXX_PATH="$(xcrun --find clang++)"

COMMON_CMAKE_ARGS=(
  -DCMAKE_OSX_DEPLOYMENT_TARGET=13.3
  -DCMAKE_OSX_SYSROOT=macosx
  -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"
  -DCMAKE_C_COMPILER="${CC_PATH}"
  -DCMAKE_CXX_COMPILER="${CXX_PATH}"
  -DCMAKE_BUILD_TYPE=Release
  -DBUILD_SHARED_LIBS=OFF
  -DWHISPER_BUILD_EXAMPLES=OFF
  -DWHISPER_BUILD_TESTS=OFF
  -DWHISPER_BUILD_SERVER=OFF
  -DGGML_METAL=ON
  -DGGML_METAL_EMBED_LIBRARY=ON
  -DGGML_METAL_USE_BF16=ON
  -DGGML_BLAS_DEFAULT=ON
  -DGGML_OPENMP=OFF
)

pushd "${SUBMODULE_DIR}" >/dev/null

rm -rf "${BUILD_DIR}"

cmake -B "${BUILD_DIR}" -G "Unix Makefiles" \
  "${COMMON_CMAKE_ARGS[@]}" \
  -S .

cmake --build "${BUILD_DIR}" --target whisper -- -j4

LIB_WHISPER="${BUILD_DIR}/src/libwhisper.a"
LIB_GGML="${BUILD_DIR}/ggml/src/libggml.a"
LIB_GGML_BASE="${BUILD_DIR}/ggml/src/libggml-base.a"
LIB_GGML_CPU="${BUILD_DIR}/ggml/src/libggml-cpu.a"
LIB_GGML_METAL="${BUILD_DIR}/ggml/src/ggml-metal/libggml-metal.a"
LIB_GGML_BLAS="${BUILD_DIR}/ggml/src/ggml-blas/libggml-blas.a"

for lib in "${LIB_WHISPER}" "${LIB_GGML}" "${LIB_GGML_BASE}" "${LIB_GGML_CPU}" "${LIB_GGML_METAL}" "${LIB_GGML_BLAS}"; do
  if [ ! -f "${lib}" ]; then
    echo "Required library not found at ${lib}" >&2
    exit 1
  fi
done

LIB_MERGED="${BUILD_DIR}/libwhisper_all.a"
rm -f "${LIB_MERGED}"
libtool -static -o "${LIB_MERGED}" \
  "${LIB_WHISPER}" \
  "${LIB_GGML}" \
  "${LIB_GGML_BASE}" \
  "${LIB_GGML_CPU}" \
  "${LIB_GGML_METAL}" \
  "${LIB_GGML_BLAS}"

rm -rf "${HEADERS_DIR}"
mkdir -p "${HEADERS_DIR}"

cp include/whisper.h "${HEADERS_DIR}/"
cp ggml/include/ggml.h "${HEADERS_DIR}/"
cp ggml/include/ggml-alloc.h "${HEADERS_DIR}/"
cp ggml/include/ggml-backend.h "${HEADERS_DIR}/"
cp ggml/include/ggml-metal.h "${HEADERS_DIR}/"
cp ggml/include/ggml-cpu.h "${HEADERS_DIR}/"
cp ggml/include/ggml-blas.h "${HEADERS_DIR}/"
cp ggml/include/gguf.h "${HEADERS_DIR}/"

cat > "${HEADERS_DIR}/module.modulemap" << 'MODULEMAP'
module whisper {
  header "whisper.h"
  header "ggml.h"
  header "ggml-alloc.h"
  header "ggml-backend.h"
  header "ggml-metal.h"
  header "ggml-cpu.h"
  header "ggml-blas.h"
  header "gguf.h"

  link "c++"
  link framework "Accelerate"
  link framework "Metal"
  link framework "Foundation"

  export *
}
MODULEMAP

rm -rf "${OUTPUT_XCFRAMEWORK}"
mkdir -p "$(dirname "${OUTPUT_XCFRAMEWORK}")"

xcodebuild -create-xcframework \
  -library "${LIB_MERGED}" \
  -headers "${HEADERS_DIR}" \
  -output "${OUTPUT_XCFRAMEWORK}"

popd >/dev/null

echo "Built ${OUTPUT_XCFRAMEWORK}"
