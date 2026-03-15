#!/bin/bash
# ============================================================
# reset.sh — Elimina TODA la instalación anterior
# Usar antes de setup.sh para empezar desde cero
# Ejecutar como root: bash reset.sh
# ============================================================
set -e

APP_DIR="/opt/smime-monitor"

echo "============================================"
echo " RESET COMPLETO — TFG S/MIME Monitor"
echo "============================================"
echo ""
echo "⚠  ATENCIÓN: Esto eliminará:"
echo "   - Todos los contenedores Docker del sistema"
echo "   - El directorio $APP_DIR (base de datos incluida)"
echo "   - Imágenes Docker sin uso"
echo ""
read -p "¿Confirmar reset completo? [s/N] " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
  echo "Operación cancelada."
  exit 0
fi

echo ""
echo "[1/4] Deteniendo y eliminando contenedores..."
if command -v docker &>/dev/null; then
  # Stop all running containers
  docker ps -q 2>/dev/null | xargs -r docker stop
  # Remove ALL containers
  docker ps -aq 2>/dev/null | xargs -r docker rm -f
  echo "      ✓ Contenedores eliminados."
else
  echo "      Docker no encontrado, saltando."
fi

echo ""
echo "[2/4] Eliminando redes Docker sin uso..."
docker network prune -f 2>/dev/null && echo "      ✓ Redes limpiadas." || true

echo ""
echo "[3/4] Eliminando imágenes sin uso (opcional, puede tardar)..."
docker image prune -f 2>/dev/null && echo "      ✓ Imágenes sin uso eliminadas." || true

echo ""
echo "[4/4] Eliminando directorio de la aplicación: $APP_DIR..."
if [ -d "$APP_DIR" ]; then
  rm -rf "$APP_DIR"
  echo "      ✓ $APP_DIR eliminado."
else
  echo "      El directorio no existía."
fi

echo ""
echo "============================================"
echo " RESET COMPLETADO — Sistema en estado limpio"
echo " Ejecutá: bash setup.sh para reinstalar"
echo "============================================"
