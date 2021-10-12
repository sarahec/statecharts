FROM gitpod/workspace-full

# Install custom tools, runtime, etc.
RUN brew tap dart-lang/dart && brew install dart

# Change the PUB_CACHE to /workspace so dependencies are preserved.
ENV PUB_CACHE=/workspace/.pub_cache

# add executables to PATH
RUN echo 'export PATH=${PUB_CACHE}/bin:$PATH' >>~/.bashrc

ENV DF_VERSION=2
