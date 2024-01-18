FROM ubuntu:22.04

# Set noninteractive mode during the build
ARG DEBIAN_FRONTEND=noninteractive

RUN apt update
RUN apt -y install php8.1-cli
RUN apt -y install php-mysql

# Reset the noninteractive mode for future commands (if needed)
ARG DEBIAN_FRONTEND=interactive

WORKDIR /crud

COPY /crud/ /crud/

# Expose port 8000
EXPOSE 8000

# Command to start PHP server
CMD ["php", "-S", "0.0.0.0:8000"]