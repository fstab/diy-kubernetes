upstream kuard {
	server 172.16.0.1:32000;
	server 172.16.0.2:32000;
}

upstream prometheus {
	server 172.16.0.1:30900;
	server 172.16.0.2:30900;
}

upstream grafana {
	server 172.16.0.1:30902;
	server 172.16.0.2:30902;
}

upstream alertmanager {
	server 172.16.0.1:30903;
	server 172.16.0.2:30903;
}

server {
	listen 80 default_server;
	listen [::]:80 default_server;

	return 301 https://$host$request_uri;
}

# This should be replaced with Let's Encrypt certificates
ssl_certificate /etc/nginx/certs/ssl-cert-snakeoil.pem;
ssl_certificate_key /etc/nginx/certs/ssl-cert-snakeoil.key;

# My private client certificate
ssl_client_certificate /etc/nginx/certs/self-signed-client-public-ca.pem;
ssl_verify_client optional;

server {
	listen 443 ssl default_server;
	listen [::]:443 ssl default_server;

	root /var/www/html;

	index index.html index.htm index.nginx-debian.html;

	server_name _;

	location / {
		try_files $uri $uri/ =404;
	}
}

server {
	listen 443 ssl;
	listen [::]:443 ssl;

	if ($ssl_client_verify != SUCCESS) {
		return 301 https://www.example.com;
	}

	server_name "~^(?<name>kuard|prometheus|grafana|alertmanager)\.example\.com$";

	location / {
        	proxy_pass http://$name;
		proxy_set_header Host $host;
		proxy_set_header X-Real-IP $remote_addr;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header X-Forwarded-Proto $scheme;
	}
}
