const services = [
    { name: "Home", port: 7575, icon: "homepage.png" }, // simple house logo
    { name: "Grafana", port: 3000, icon: "grafana.png" },
    { name: "Prometheus", port: 9090, icon: "prometheus.png" },
    { name: "Alertmanager", port: 9093, icon: "prometheus.png" },
    { name: "cAdvisor", port: 8080, icon: "docker.png" },
    { name: "Node Exporter", port: 9100, icon: "prometheus.png" },
    { name: "Jellyfin", port: 8096, icon: "jellyfin.png" },
    { name: "Overseerr", port: 5055, icon: "overseerr.png" },
    { name: "Maintainerr", port: 6246, icon: "maintainerr.png" },
    { name: "qBittorrent", port: 18181, icon: "qbittorrent.png" },
    { name: "Sonarr", port: 8989, icon: "sonarr.png" },
    { name: "Radarr", port: 7878, icon: "radarr.png" },
    { name: "Prowlarr", port: 9696, icon: "prowlarr.png" },
    { name: "Bazarr", port: 6767, icon: "bazarr.png" },
    { name: "Navidrome", port: 4533, icon: "navidrome.png" },
    { name: "Navidrome (Karine)", port: 4534, icon: "navidrome.png" },
    { name: "Lidarr", port: 8686, icon: "lidarr.png" },
    { name: "spotDL", port: 8888, icon: "spotify.png" },
    { name: "Music App", port: 5000, icon: "headphones.png" },
    { name: "PhotoPrism", port: 2342, icon: "photoprism.png" },
    { name: "Portfolio", port: 80, icon: "nginx.png" }
];

const iconBase = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/";

const baseUrlInput = document.getElementById("base-url");
const dashboard = document.getElementById("dashboard");

const savedUrl = localStorage.getItem("homelabBaseUrl");
if (savedUrl) {
    baseUrlInput.value = savedUrl;
} else {
    baseUrlInput.value = window.location.protocol + "//" + window.location.hostname;
}

function render() {
    let baseUrl = baseUrlInput.value.replace(/\/$/, "");
    localStorage.setItem("homelabBaseUrl", baseUrl);

    dashboard.innerHTML = "";
    services.forEach(service => {
        const link = document.createElement("a");
        link.className = "service-card";
        
        // If it's port 80, we don't necessarily need the port, but keeping it for consistency
        let portStr = service.port === 80 ? "" : `:${service.port}`;
        link.href = `${baseUrl}${portStr}`;
        link.target = "_blank";

        const img = document.createElement("img");
        img.src = iconBase + service.icon;
        img.alt = service.name;
        img.onerror = function() {
            this.src = 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100"><rect width="100" height="100" rx="12" fill="%23334155"/><text x="50%" y="50%" font-family="Arial" font-size="30" font-weight="bold" fill="%23f8fafc" dominant-baseline="central" text-anchor="middle">' + service.name.charAt(0) + '</text></svg>';
        };

        const title = document.createElement("div");
        title.className = "service-title";
        title.innerText = service.name;
        
        const port = document.createElement("div");
        port.className = "service-port";
        port.innerText = portStr === "" ? "Port 80" : portStr;

        link.appendChild(img);
        link.appendChild(title);
        link.appendChild(port);

        dashboard.appendChild(link);
    });
}

baseUrlInput.addEventListener("input", render);

render();
