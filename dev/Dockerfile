FROM openresty/openresty:bullseye-fat

# Install lua-resty-http
RUN opm get ledgetech/lua-resty-http

# Install lua-resty-url
RUN opm get 3scale/lua-resty-url

# Create mount point for /dev
VOLUME /usr/local/openresty/nginx/conf 

# Create mount point for /lib
VOLUME /usr/local/openresty/site/plugins

EXPOSE 80 443

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]
