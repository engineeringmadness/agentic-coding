FROM ubuntu:latest

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Update system and install common server administration utilities
RUN apt-get update && apt-get upgrade -y

RUN apt-get install -y sudo curl wget git vim nano net-tools iputils-ping htop

RUN apt-get install -y ubuntu-minimal unminimize

# Restore standard documentation, man pages, and tools removed from the slim image
RUN yes | unminimize

# Miniconda (latest) into /opt/miniconda3, base env on PATH
RUN curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
        -o /tmp/miniconda.sh \
    && bash /tmp/miniconda.sh -b -p /opt/miniconda3 \
    && rm /tmp/miniconda.sh \
    && /opt/miniconda3/bin/conda clean -afy
ENV PATH=/opt/miniconda3/bin:$PATH

# Node.js 24
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user named "student" with a password "practice" for safety training
RUN useradd -rm -d /home/student -s /bin/bash -g root -G sudo -u 1001 student && \
    echo 'student:practice' | chpasswd

# Set the default directory and switch to the student user
WORKDIR /home/student
USER student

ENTRYPOINT ["/bin/bash"]
