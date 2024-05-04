# Start with a Debian base image
FROM debian:buster as build-stage

# Install necessary packages
RUN apt-get update && apt-get install -y \
    build-essential \
    libpcre3 libpcre3-dev \
    zlib1g zlib1g-dev \
    libssl-dev \
    wget \
    ca-certificates

# Download and unpack NGINX and the RTMP module
WORKDIR /tmp
RUN wget http://nginx.org/download/nginx-1.26.0.tar.gz && tar -zxvf nginx-1.26.0.tar.gz
RUN wget https://github.com/arut/nginx-rtmp-module/archive/v1.2.2.tar.gz && tar -zxvf v1.2.2.tar.gz

# Build NGINX with the RTMP module
WORKDIR /tmp/nginx-1.26.0
RUN ./configure --add-module=/tmp/nginx-rtmp-module-1.2.2 && make && make install
RUN useradd -d /etc/nginx/ -s /sbin/nologin nginx

# Final stage based on nginx to keep image size down
FROM build-stage
COPY --from=build-stage /usr/local/nginx/sbin/nginx /usr/sbin/nginx

# Create log directory and set up symbolic links
RUN mkdir -p /var/log/nginx && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# Install necessary runtime libraries
RUN apt-get update && apt-get install -y libpcre3 zlib1g libssl1.1 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Expose ports for HTTP and RTMP
EXPOSE 80 1935

# Command to run NGINX
CMD ["nginx", "-g", "daemon off;"]

