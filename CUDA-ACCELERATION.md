# CUDA GPU Object Detection (Nvidia)

The published `ispyagentdvr` image ships the VAAPI/NVDEC/NVENC driver stack, so **ffmpeg hardware decode/encode works out of the box** with `--runtime=nvidia`.

AgentDVR's **AI object detection on GPU** additionally needs the CUDA toolkit runtime and cuDNN (`libcudart`, `libcublas`, `libcudnn`) **inside the container**. The NVIDIA Container Toolkit only injects the host *driver* libraries — never the CUDA/cuDNN userspace. We deliberately don't bundle these in the published image: that layer alone is ~3 GB compressed (~6 GB on disk) versus ~370 MB for the entire current image, and it only benefits amd64 + Nvidia deployments.

The recommended pattern is a small overlay image built on top of the published one:

## Overlay Dockerfile

```dockerfile
FROM nvidia/cuda:12.9.1-cudnn-runtime-ubuntu24.04 AS cuda

FROM ghcr.io/mekayelanik/ispyagentdvr:latest

COPY --from=cuda /usr/local/cuda /usr/local/cuda
COPY --from=cuda /usr/lib/x86_64-linux-gnu/libcudnn* /usr/lib/x86_64-linux-gnu/

ENV PATH="/usr/local/cuda/bin:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin"
ENV LD_LIBRARY_PATH="/usr/local/cuda/lib64:/usr/local/cuda/targets/x86_64-linux/lib:/usr/lib/x86_64-linux-gnu"

RUN set -eux; \
    CUDA_LIB="$(find /usr/local/cuda -type d -path '*/targets/x86_64-linux/lib' | head -n 1)"; \
    echo "$CUDA_LIB" > /etc/ld.so.conf.d/cuda.conf; \
    echo "/usr/local/cuda/lib64" >> /etc/ld.so.conf.d/cuda.conf; \
    echo "/usr/lib/x86_64-linux-gnu" >> /etc/ld.so.conf.d/cuda.conf; \
    /sbin/ldconfig; \
    test -e /usr/lib/x86_64-linux-gnu/libcudnn.so.9; \
    test -e /usr/local/cuda/targets/x86_64-linux/lib/libcudart.so.12; \
    test -e /usr/local/cuda/targets/x86_64-linux/lib/libcublas.so.12
```

Build it:

```bash
docker build -t local/ispyagentdvr-cuda:12.9 .
```

## Compose example

```yaml
services:
  ispyagentdvr:
    image: local/ispyagentdvr-cuda:12.9
    container_name: agentdvr
    environment:
      - AGENTDVR_WEBUI_PORT=8090
      - TZ=Etc/UTC
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=all
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
    volumes:
      - ./config:/AgentDVR/Media/XML
      - ./media:/AgentDVR/Media/WebServerRoot/Media
      - ./models:/AgentDVR/Media/Models
      - ./commands:/AgentDVR/Commands
    ports:
      - 8090:8090
      - 3478:3478/udp
      - 50000-50100:50000-50100/udp
    runtime: nvidia
    restart: unless-stopped
```

Verify with `nvidia-smi` on the host — `/AgentDVR/Agent` should appear in the process list once detection runs.

## Notes

- **Host prerequisites:** latest Nvidia driver + [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-container-toolkit).
- **Slimmer option:** drivers ≥ 580 support CUDA 13 — basing the overlay on `nvidia/cuda:13.x-cudnn-runtime-ubuntu24.04` saves roughly 1 GB compressed. Only use it if AgentDVR's bundled ONNX runtime works with CUDA 13; when in doubt stay on 12.9.
- **amd64 only** — Nvidia CUDA images don't cover the arm/v7 targets this image publishes, and Jetson-class arm64 setups need L4T-specific bases.
- Rebuild the overlay after pulling a new `ispyagentdvr` tag; the CUDA stage is cached so rebuilds are quick.

Background discussion: [issue #96](https://github.com/MekayelAnik/ispyagentdvr-docker/issues/96).
