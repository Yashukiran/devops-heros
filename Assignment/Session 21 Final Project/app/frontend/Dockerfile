FROM nginxinc/nginx-unprivileged:1.29-alpine
# the official image runs envsubst on /etc/nginx/templates/*.template at startup
COPY nginx.conf /etc/nginx/templates/default.conf.template
COPY index.html /usr/share/nginx/html/index.html
ENV BACKEND_HOST=backend \
    NGINX_ENVSUBST_FILTER=BACKEND_
EXPOSE 8080
