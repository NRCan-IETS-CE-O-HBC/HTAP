# Use Ubuntu as the base image, which has good Wine support
FROM canmet/model_dev_container:3.9.0

USER root

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
# Add this line to set XDG_RUNTIME_DIR during build
ENV XDG_RUNTIME_DIR=/tmp/runtime-root

# Install necessary packages
RUN dpkg --add-architecture i386 && apt-get update
RUN apt-get update && apt-get install -y --install-recommends \
    wget \
    gnupg2 \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    cabextract \
    libvulkan1 \
    libvulkan1:i386 \
    mesa-vulkan-drivers \
    mesa-vulkan-drivers:i386 \
    winbind \
    x11-apps \
    xvfb \
    imagemagick \
    tesseract-ocr \
    x11-utils

# Add this after the env variable to create the directory
RUN mkdir -p $XDG_RUNTIME_DIR && chmod 700 $XDG_RUNTIME_DIR

# Install wine
ARG WINE_BRANCH="stable"
RUN wget -nv -O- https://dl.winehq.org/wine-builds/winehq.key | APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 apt-key add - \
    && echo "deb https://dl.winehq.org/wine-builds/ubuntu/ $(grep VERSION_CODENAME= /etc/os-release | cut -d= -f2) main" >> /etc/apt/sources.list \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && DEBIAN_FRONTEND="noninteractive" apt-get install -y --install-recommends winehq-${WINE_BRANCH} \
    && rm -rf /var/lib/apt/lists/*

# Install winetricks
RUN wget -nv -O /usr/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
    && chmod +x /usr/bin/winetricks



# Set up Wine prefix specifically for Hot2000
ENV WINEARCH=win32
ENV WINEPREFIX=/home/vscode/.wine_hot2000
ENV WINEDEBUG=-all

USER root

# Create wine prefix directory and set permissions
RUN mkdir -p /home/vscode/.wine_hot2000 && chown vscode:vscode /home/vscode/.wine_hot2000
RUN mkdir -p /opt/hot2000 && chown vscode:vscode /opt/hot2000 

# Copy the installer and setup script into the container as root
# Check if installer/installer.exe exists before proceeding
#RUN test -f installer/installer.exe || (echo "Error: installer/installer.exe not found." && exit 1)
COPY .devcontainer/installer.exe  /opt/hot2000/

# Now switch to vscode user
USER vscode

# Start Xvfb, install Wine runtime requirements and HOT2000
# Set Xvfb display number as environment variable
ENV XVFB_DISPLAY=:99

# Create Windows installer directory
RUN mkdir -p "$WINEPREFIX/drive_c/windows/installer" && chown vscode:vscode /home/vscode/.wine_hot2000

# Download Wine Mono installer
RUN wget -O "$WINEPREFIX/drive_c/windows/installer/wine-mono-10.0.0-x86.msi" \
    https://dl.winehq.org/wine/wine-mono/10.0.0/wine-mono-10.0.0-x86.msi

# Install Wine Mono
RUN echo "Installing Wine Mono and Visual C++ 2019..." 
RUN Xvfb $XVFB_DISPLAY -screen 0 1024x768x16 &
RUN sleep 2
RUN wine msiexec /i "$WINEPREFIX/drive_c/windows/installer/wine-mono-10.0.0-x86.msi" /qn
RUN wineboot -u && winetricks -q vcrun2019 || true