FROM nginx:latest

COPY ./risf.html /usr/share/nginx/html/index.html

# Créer un utilisateur non-root
RUN addgroup --system --gid 1001 appgroup && \
    adduser --system --uid 1001 --ingroup appgroup --shell /bin/false appuser

# Modifier les permissions des répertoires nginx nécessaires
RUN chown -R appuser:appgroup /var/cache/nginx && \
    chown -R appuser:appgroup /var/log/nginx && \
    chown -R appuser:appgroup /etc/nginx/conf.d && \
    touch /var/run/nginx.pid && \
    chown -R appuser:appgroup /var/run/nginx.pid

# Configuration pour permettre à nginx de s'exécuter en tant qu'utilisateur non-root
RUN sed -i '/user  nginx;/c\user  appuser;' /etc/nginx/nginx.conf

# Passer à l'utilisateur non-root
USER appuser

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
