FROM ubuntu:25.04

RUN apt-get update -y && \
    apt-get install -y sysstat build-essential curl git htop man unzip vim wget tree

WORKDIR /

CMD ["bash"]