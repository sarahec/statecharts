FROM gitpod/workspace-full

# Install custom tools, runtime, etc.
RUN brew tap dart-lang/dart && brew install dart
