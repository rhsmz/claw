# llama-server（OpenCL バックエンド）— WSL2 の /dev/dxg + ホスト D3D ライブラリ利用を想定。
# （# syntax=docker/dockerfile:1 は Hub 参照で creds エラーになりやすいため未使用）
# Intel GPU 向けに Adreno 専用カーネルは無効化（GGML_OPENCL_USE_ADRENO_KERNELS=OFF）。
#
# ビルド例: docker compose -f docker-compose.yml -f docker-compose.opencl-wsl.yml build opencl-inference

ARG UBUNTU_RELEASE=24.04

FROM ubuntu:${UBUNTU_RELEASE} AS build
ARG DEBIAN_FRONTEND=noninteractive
ARG LLAMA_CPP_REF=master

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg wget \
    build-essential cmake git pkg-config \
    python3-minimal \
    ocl-icd-opencl-dev ocl-icd-libopencl1 opencl-c-headers \
    && rm -rf /var/lib/apt/lists/*

# Intel GPU リポジトリ（OpenCL ICD / ランタイム）
RUN wget -qO - https://repositories.intel.com/gpu/intel-graphics.key \
    | gpg --dearmor -o /usr/share/keyrings/intel-graphics.gpg \
  && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/intel-graphics.gpg] https://repositories.intel.com/gpu/ubuntu noble client" \
    > /etc/apt/sources.list.d/intel-gpu-noble.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends intel-opencl-icd \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone --depth 1 --branch "${LLAMA_CPP_REF}" https://github.com/ggml-org/llama.cpp.git .

# 動的 CPU プラグインはコンテナ＋WSL 環境で登録に失敗することがあるため、CPU+OpenCL を静的リンク
RUN cmake -B build \
    -DGGML_NATIVE=OFF \
    -DGGML_OPENCL=ON \
    -DGGML_OPENCL_USE_ADRENO_KERNELS=OFF \
    -DGGML_BACKEND_DL=OFF \
    -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_CURL=OFF \
  && cmake --build build --config Release -j"$(nproc)"

RUN mkdir -p /out/lib \
  && find /src/build -name "*.so*" -exec cp -a {} /out/lib/ \; \
  && cp -a /src/build/bin/llama-server /out/llama-server

FROM ubuntu:${UBUNTU_RELEASE}
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg wget \
    libgomp1 \
    ocl-icd-libopencl1 \
    && wget -qO - https://repositories.intel.com/gpu/intel-graphics.key \
    | gpg --dearmor -o /usr/share/keyrings/intel-graphics.gpg \
  && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/intel-graphics.gpg] https://repositories.intel.com/gpu/ubuntu noble client" \
    > /etc/apt/sources.list.d/intel-gpu-noble.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends intel-opencl-icd clinfo \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN mkdir -p /app/models

COPY --from=build /out/lib/ /app/lib/
COPY --from=build /out/llama-server /app/llama-server

# compose の LD_LIBRARY_PATH が上書き。単体実行時は WSL では /usr/lib/wsl/lib を先に付けること
ENV LD_LIBRARY_PATH=/app/lib

COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh /app/llama-server

EXPOSE 8080
HEALTHCHECK --interval=15s --timeout=5s --start-period=120s --retries=5 \
  CMD curl -fsS http://127.0.0.1:8080/health >/dev/null || exit 1

ENTRYPOINT ["/app/entrypoint.sh"]
