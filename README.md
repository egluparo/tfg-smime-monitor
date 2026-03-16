# TFG: Control de Seguridad en Correo Electrónico con Cifrado y Monitoreo Automatizado

## (Emiliano González Luparo - VLSI000745)

Este repositorio contiene el prototipo funcional para el Trabajo Final de Grado (TFG) de la Licenciatura en Seguridad Informática (Universidad Siglo 21).

El objetivo es demostrar un sistema de **Control De Seguridad En Correo Electrónico Con Cifrado y Monitoreo Automatizado**, implementando S/MIME (firma y cifrado) con verificación automática de correos entrantes, registro centralizado de eventos y un dashboard de KPIs con alertas.

---

### Stack Tecnológico

* **API Backend:** Python 3 con Flask
* **Criptografía y certificados:** manejo de X.509 mediante la librería cryptography (Python library).
* **Verificación Criptográfica:** uso de OpenSSL vía CLI para pruebas y validación en laboratorio.
* **Automatización:** n8n (corriendo en Docker)
* **Base de Datos:** SQLite 3
* **Dashboard & Frontend:** HTML/CSS y Chart.js
* **Correo entrante:** Zoho Mail vía IMAP.
* **Comandos de prueba:** Simulación de casos de uso vía CLI utilizando el comando `curl`.
* **Infraestructura:** Linode VPS + Docker Compose + dominio propio.

---

### Casos de uso implementados

* **TEXTO_PLANO** — correo sin firma ni cifrado (genera alerta en dashboard)
* **FIRMADO_VALIDO** — correo con firma S/MIME verificada por OpenSSL
* **FIRMADO_INVALIDO** — firma presente pero la verificación falla
* **CIFRADO** — correo con `content-type: application/pkcs7-mime; smime-type=enveloped-data`
* **CIFRADO+FIRMADO_VALIDO** — combinación de ambos controles

---

### Estructura del proyecto

```
/opt/smime-monitor/
├── docker-compose.yml
├── n8n_data/              ← volumen persistente de n8n
├── setup.sh
├── reset.sh
└── api/
    ├── Dockerfile
    ├── requirements.txt
    ├── app.py
    ├── data/              ← base de datos SQLite
    └── templates/
        ├── dashboard.html
        └── asistente.html
```

---

### Instrucciones de despliegue (Linode / Ubuntu)

#### 1. Prerequisitos

```bash
apt-get update && apt-get upgrade -y
curl -fsSL https://get.docker.com | sh
apt-get install -y docker-compose-plugin git curl openssl
```

#### 2. Clonar el repositorio

```bash
git clone https://github.com/egluparo/tfg-smime-monitor.git /opt/smime-monitor
cd /opt/smime-monitor
```

#### 3. Crear directorios y permisos

```bash
mkdir -p /opt/smime-monitor/n8n_data /opt/smime-monitor/api/data
chown -R 1000:1000 /opt/smime-monitor/n8n_data
```

#### 4. Levantar los servicios

```bash
cd /opt/smime-monitor
docker compose build --no-cache
docker compose up -d
```

#### 5. Verificar estado

```bash
docker compose ps
```

---

### Accesos y URLs

| Servicio               | URL                                   |
| ---------------------- | ------------------------------------- |
| Dashboard principal    | `http://luparo.com.ar:5000/dashboard` |
| Asistente certificados | `http://luparo.com.ar:5000/asistente` |
| API health check       | `http://luparo.com.ar:5000/health`    |
| n8n (automatización)   | `http://luparo.com.ar:5678`           |

---

### Comandos de Prueba (Simulación `curl`)

Estos comandos simulan los 3 casos de uso principales.

```bash
# TEST A: Correo NO Firmado (Texto Plano)
curl -X POST http://luparo.com.ar:5000/verify-email \
  -H "Content-Type: application/json" \
  -d '{"remitente":"test@ejemplo.com","content-type":"text/plain","subject":"Test plano"}'

# TEST B: Correo FIRMADO (Necesita 'test_email.eml')
curl -X POST -H "Content-Type: application/octet-stream" \
  --data-binary "@test_email.eml" \
  "http://luparo.com.ar:5000/verify-email"

# TEST C: Correo FIRMADO y CIFRADO (Necesita 'test_cifrado.eml')
curl -X POST -H "Content-Type: application/octet-stream" \
  --data-binary "@test_cifrado.eml" \
  "http://luparo.com.ar:5000/verify-email"
```

---

### Configuración de n8n

Workflow de 2 nodos: **Email Trigger (IMAP) → HTTP Request**

* **Nodo Email Trigger:** conectar a `imap.zoho.com:993` con las credenciales de la casilla de correo que recibirá cada disparador.
* **Nodo HTTP Request:** `POST` a `http://api-smime:5000/verify-email`, `Body Content Type` = `JSON`

---

### Limpiar todo y empezar desde cero

```bash
# Detener y eliminar contenedores
docker ps -q | xargs -r docker stop
docker ps -aq | xargs -r docker rm -f
docker network prune -f

# Eliminar el directorio completo (⚠ borra la DB y todos los datos)
rm -rf /opt/smime-monitor
```

> **Backup previo recomendado:**
> 
> ```bash
> cp /opt/smime-monitor/api/data/tfg_security.db ~/backup_tfg_$(date +%Y%m%d).db
> ```

