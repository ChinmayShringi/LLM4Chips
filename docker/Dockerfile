# Microwatt OpenFrame Development Environment
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

WORKDIR /work

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential git wget curl \
    python3 python3-pip \
    gnat zlib1g-dev \
    clang bison flex libreadline-dev gawk tcl-dev libffi-dev \
    libboost-system-dev libboost-python-dev libboost-filesystem-dev \
    verilator gtkwave \
    vim nano less tree \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install GHDL (VHDL simulator)
RUN cd /tmp && \
    git clone https://github.com/ghdl/ghdl.git && \
    cd ghdl && \
    git checkout v3.0.0 && \
    mkdir build && cd build && \
    ../configure --with-llvm-config=/usr/bin/llvm-config --prefix=/usr/local && \
    make -j$(nproc) && make install && \
    cd /tmp && rm -rf ghdl

# Install Yosys (synthesis)
RUN cd /tmp && \
    git clone https://github.com/YosysHQ/yosys.git && \
    cd yosys && \
    git checkout yosys-0.34 && \
    make config-clang && make -j$(nproc) && make install && \
    cd /tmp && rm -rf yosys

# Install GHDL-Yosys plugin
RUN cd /tmp && \
    git clone https://github.com/ghdl/ghdl-yosys-plugin.git && \
    cd ghdl-yosys-plugin && \
    make -j$(nproc) && make install && \
    cd /tmp && rm -rf ghdl-yosys-plugin

# Install Python packages
RUN pip3 install --no-cache-dir \
    cocotb pytest pyverilog numpy pandas matplotlib

ENV PATH="/usr/local/bin:${PATH}"

RUN echo "=== Installed Tools ===" && \
    ghdl --version && echo "" && \
    yosys -V && echo "" && \
    python3 --version

CMD ["/bin/bash"]
