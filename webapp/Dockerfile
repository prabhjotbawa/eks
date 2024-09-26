FROM nginx:alpine
LABEL authors="prabhjotbawa"

# Remove the default Nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy the sample page into the container
COPY index.html /usr/share/nginx/html/

# Expose port 80
# Not needed, but good practice
EXPOSE 80

# Start Nginx when the container launches
CMD ["nginx", "-g", "daemon off;"]