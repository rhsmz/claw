# （Hub の dockerfile フロントエンド参照を避けるため syntax 行なし）
# Intel SYCL 版 llama.cpp の llama-server（OpenAI 互換 HTTP）をビルドする。
# 手順の正: https://github.com/ggml-org/llama.cpp/blob/master/docs/backend/SYCL.md
# ベースは llama.cpp 公式 .devops/intel.Dockerfile と同系統（deep-learning-essentials）。

ARG ONEAPI_VERSION=2025.3.2-0-devel-ubuntu24.04

FROM intel/deep-learning-essentials:${ONEAPI_VERSION} AS llama-build
ARG ONEAPI_VERSION
# Gemma 4 GGUF 等は古いタグで未対応のため既定は master（安定版に固定する場合はタグ/コミットを指定）
ARG LLAMA_CPP_REF=master
ARG GGML_SYCL_F16=OFF

RUN apt-get update && apt-get install -y --no-install-recommends \
    git ca-certificates libssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone --depth 1 --branch "${LLAMA_CPP_REF}" https://github.com/ggml-org/llama.cpp.git .

# setvars.sh が未定義の OCL_ICD_FILENAMES 等を参照するため nounset は使わない
RUN bash -c 'set -eo pipefail; \
  source /opt/intel/oneapi/setvars.sh --force; \
  EXTRA=""; \
  if [ "${GGML_SYCL_F16}" = "ON" ]; then EXTRA="-DGGML_SYCL_F16=ON"; fi; \
  cmake -B build \
    -DGGML_NATIVE=OFF \
    -DGGML_SYCL=ON \
    -DCMAKE_C_COMPILER=icx \
    -DCMAKE_CXX_COMPILER=icpx \
    -DGGML_BACKEND_DL=ON \
    -DGGML_BACKEND_DIR=/app/lib \
    -DGGML_CPU_ALL_VARIANTS=ON \
    -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_CURL=OFF \
    ${EXTRA} \
  && cmake --build build --config Release -j"$(nproc)"'

RUN mkdir -p /out/lib \
  && find /src/build -name "*.so*" -exec cp -a {} /out/lib/ \; \
  && cp -a /src/build/bin/llama-server /out/llama-server

FROM intel/deep-learning-essentials:${ONEAPI_VERSION}
ARG ONEAPI_VERSION
# 1: ランタイムに libggml-sycl を残す（/dev/dri 等で Intel GPU を使うとき）。0: CPU 動的バックエンドのみ（GPU 無し Docker で必須）
ARG KEEP_SYCL_PLUGIN=0

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates libgomp1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN mkdir -p /app/models

COPY --from=llama-build /out/lib/ /app/lib/
COPY --from=llama-build /out/llama-server /app/llama-server
RUN if [ "${KEEP_SYCL_PLUGIN}" != "1" ]; then rm -f /app/lib/libggml-sycl.so*; fi

ENV LD_LIBRARY_PATH=/app/lib

COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh /app/llama-server

EXPOSE 8080
HEALTHCHECK --interval=15s --timeout=5s --start-period=120s --retries=5 \
  CMD curl -fsS http://127.0.0.1:8080/health >/dev/null || exit 1

ENTRYPOINT ["/app/entrypoint.sh"]
