#!/bin/bash
# ============================================================
# setup.sh — Instalación / reinicio completo del sistema
# TFG S/MIME Monitor — luparo.com.ar
# Ejecutar como root: bash setup.sh
# ============================================================
set -e

APP_DIR="/opt/smime-monitor"
REPO="https://github.com/zonalez/tfg-smime-monitor.git"

echo "============================================"
echo " TFG S/MIME Monitor — Setup completo"
echo " $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================"

# ── 1. Limpiar instalación anterior ─────────────────────────
echo ""
echo "[1/7] Limpiando instalación anterior..."

# Detener y eliminar contenedores
if command -v docker &>/dev/null; then
  docker ps -aq 2>/dev/null | xargs -r docker rm -f
  docker network prune -f 2>/dev/null || true
fi

# Eliminar directorio anterior
if [ -d "$APP_DIR" ]; then
  rm -rf "$APP_DIR"
  echo "      Directorio $APP_DIR eliminado."
fi

echo "      ✓ Limpieza completada."

# ── 2. Instalar dependencias del sistema ────────────────────
echo ""
echo "[2/7] Verificando dependencias del sistema..."

apt-get update -qq

# Docker
if ! command -v docker &>/dev/null; then
  echo "      Instalando Docker..."
  curl -fsSL https://get.docker.com | sh
fi

# Docker Compose (plugin)
if ! docker compose version &>/dev/null 2>&1; then
  echo "      Instalando Docker Compose plugin..."
  apt-get install -y -qq docker-compose-plugin
fi

# Git y herramientas básicas
apt-get install -y -qq git openssl curl

echo "      ✓ Dependencias OK."
echo "      Docker: $(docker --version)"
echo "      Compose: $(docker compose version)"

# ── 3. Crear estructura de directorios ──────────────────────
echo ""
echo "[3/7] Creando estructura del proyecto en $APP_DIR..."

mkdir -p "$APP_DIR"
mkdir -p "$APP_DIR/n8n_data"
mkdir -p "$APP_DIR/api/data"
mkdir -p "$APP_DIR/api/templates"

echo "      ✓ Directorios creados."

# ── 4. Copiar archivos del proyecto ─────────────────────────
echo ""
echo "[4/7] Copiando archivos de la aplicación..."

# Los archivos se copian desde el mismo directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cp "$SCRIPT_DIR/docker-compose.yml"   "$APP_DIR/"
cp -r "$SCRIPT_DIR/api/"              "$APP_DIR/api/"

# Ajustar permisos
chown -R 1000:1000 "$APP_DIR/n8n_data"
chmod -R 755 "$APP_DIR/api"

echo "      ✓ Archivos copiados."

# ── 5. Inicializar la base de datos ─────────────────────────
echo ""
echo "[5/7] Inicializando base de datos SQLite..."

if command -v sqlite3 &>/dev/null; then
  sqlite3 "$APP_DIR/api/data/tfg_security.db" "
  CREATE TABLE IF NOT EXISTS CERTIFICADOS (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      sujeto_cn     TEXT NOT NULL,
      emisor        TEXT NOT NULL,
      serie         TEXT NOT NULL,
      vence         DATE NOT NULL,
      estado        TEXT DEFAULT 'valido',
      email         TEXT,
      huella_sha256 TEXT,
      fuente        TEXT,
      UNIQUE(sujeto_cn),
      UNIQUE(serie)
  );
  CREATE TABLE IF NOT EXISTS EVENTOS_CORREO (
      id              INTEGER PRIMARY KEY AUTOINCREMENT,
      remitente       TEXT,
      destinatario    TEXT,
      msg_id          TEXT NOT NULL,
      fecha_hora      DATETIME DEFAULT CURRENT_TIMESTAMP,
      firmado         BOOLEAN DEFAULT 0,
      firma_valida    BOOLEAN DEFAULT 0,
      cifrado         BOOLEAN DEFAULT 0,
      descifrado_ok   BOOLEAN DEFAULT 0,
      error_codigo    TEXT,
      fuente          TEXT,
      subject         TEXT,
      UNIQUE(msg_id)
  );
  "
  echo "      ✓ Base de datos creada en $APP_DIR/api/data/tfg_security.db"
else
  echo "      sqlite3 no disponible — la API la creará al iniciar."
fi

# ── 6. Construir y levantar contenedores ────────────────────
echo ""
echo "[6/7] Construyendo imágenes y levantando servicios..."

cd "$APP_DIR"
docker compose build --no-cache
docker compose up -d

echo "      ✓ Contenedores levantados."
echo ""
docker compose ps

# ── 7. Verificación final ────────────────────────────────────
echo ""
echo "[7/7] Verificación de salud (esperar 10 s)..."
sleep 10

API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/health || echo "000")
N8N_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5678/ || echo "000")

echo ""
echo "============================================"
echo " INSTALACIÓN COMPLETADA"
echo "============================================"
echo ""
echo " API Flask:    http://luparo.com.ar:5000/dashboard   [HTTP $API_STATUS]"
echo " Asistente:    http://luparo.com.ar:5000/asistente"
echo " n8n:          http://luparo.com.ar:5678             [HTTP $N8N_STATUS]"
echo ""
echo " PRÓXIMOS PASOS:"
echo "   1. Abrir n8n en http://luparo.com.ar:5678"
echo "   2. Seguir las instrucciones del README para configurar"
echo "      el workflow Email Trigger (IMAP) → HTTP Request"
echo "   3. Verificar el dashboard en http://luparo.com.ar:5000/dashboard"
echo ""
