#!/bin/bash
# install_thehive.sh
# Instalador de Migración para TheHive 4 (Modo Standalone / Manual)

set -e
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}🔹 Iniciando instalación de TheHive Legacy...${NC}"

# 1. Instalar Java 8 (Requerido para TheHive 4)
echo -e "${GREEN}☕ Instalando OpenJDK 8...${NC}"
sudo apt-get update
sudo apt-get install -y openjdk-8-jre-headless tar curl

# 2. Crear usuario de sistema
echo -e "${GREEN}bust_in_silhouette Creando usuario 'thehive'...${NC}"
if ! id "thehive" &>/dev/null; then
    sudo useradd -r -d /opt/thehive -s /bin/bash thehive
fi

# 3. Desplegar Binarios (Restauración manual)
echo -e "${GREEN}📦 Descomprimiendo aplicación...${NC}"
# Limpiar instalación previa si existe para evitar conflictos
if [ -d "/opt/thehive" ]; then
    echo "   ⚠️ La carpeta /opt/thehive ya existe. Respaldando..."
    sudo mv /opt/thehive /opt/thehive.bak.$(date +%s)
fi

if [ -f ./binarios/thehive_binary.tar.gz ]; then
    # Extraemos en la raíz porque el tar ya contiene la ruta /opt/thehive
    sudo tar -xzvf ./binarios/thehive_binary.tar.gz -C /
else
    echo "❌ Error: No se encuentra ./binarios/thehive_binary.tar.gz"
    exit 1
fi

# 4. Crear directorios de datos locales (BerkeleyDB & Lucene)
echo -e "${GREEN}📂 Creando estructura de datos local...${NC}"
sudo mkdir -p /opt/thp/thehive/index
sudo mkdir -p /opt/thp/thehive/data
sudo mkdir -p /var/log/thehive

# 5. Configuración
echo -e "${GREEN}⚙️ Instalando configuración...${NC}"
sudo mkdir -p /etc/thehive
sudo cp ./configs/application.conf /etc/thehive/application.conf

# Generar nueva llave secreta para esta instalación
echo -e "${GREEN}🔐 Generando nueva llave de seguridad...${NC}"
NEW_SECRET=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
# Si existe la línea, la reemplaza. Si no, la añade.
if grep -q "play.http.secret.key" /etc/thehive/application.conf; then
    sudo sed -i 's/play.http.secret.key=.*/play.http.secret.key="'$NEW_SECRET'"/' /etc/thehive/application.conf
else
    echo 'play.http.secret.key="'$NEW_SECRET'"' | sudo tee -a /etc/thehive/application.conf
fi

# 6. Servicio Systemd
echo -e "${GREEN}🔧 Registrando servicio...${NC}"
sudo cp ./system/thehive.service /etc/systemd/system/
sudo systemctl daemon-reload

# 7. Permisos Finales
echo -e "${GREEN}🔒 Corrigiendo permisos...${NC}"
sudo chown -R thehive:thehive /opt/thehive
sudo chown -R thehive:thehive /opt/thp
sudo chown -R thehive:thehive /var/log/thehive
sudo chown -R thehive:thehive /etc/thehive

# 8. Arrancar
echo -e "${GREEN}🚀 Iniciando TheHive...${NC}"
sudo systemctl enable thehive
sudo systemctl restart thehive

echo -e "${GREEN}✅ Instalación Finalizada.${NC}"
echo "   Espere 1 minuto para la inicialización de la DB local."
