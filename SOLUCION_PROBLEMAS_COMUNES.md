# 🚨 SOLUCIÓN A PROBLEMAS COMUNES

## Problema 1: "Forwarded port to 50022 is already in use"

### ¿Por qué pasa?
Este error ocurre cuando ya tienes otra VM de Vagrant corriendo que está usando el puerto SSH 50022.

### ✅ SOLUCIÓN:
```bash
# 1. Ver todas las VMs activas
vagrant global-status

# 2. Destruir VM conflictiva (usar el ID que aparezca)
vagrant destroy [ID_DE_LA_VM] -f

# Ejemplo si el ID es "00ef45a":
vagrant destroy 00ef45a -f

# 3. O detener TODAS las VMs de una vez
vagrant global-status --prune
for id in $(vagrant global-status | grep running | awk '{print $1}'); do
  vagrant destroy $id -f
done

# 4. Limpiar el cache de Vagrant
vagrant global-status --prune

# 5. Reintentar
vagrant up database
```

---

## Problema 2: "The Ansible software could not be found"

### ¿Por qué pasa?
Vagrant necesita que Ansible esté instalado en tu Mac (host) para poder ejecutar los playbooks de aprovisionamiento.

### ✅ SOLUCIÓN:
```bash
# 1. Instalar Ansible con Homebrew
brew install ansible

# 2. Verificar que se instaló correctamente
ansible --version
# Debe mostrar: ansible [core 2.19.x]

# 3. Si la VM ya está corriendo, solo re-aprovisionar
vagrant provision database

# 4. Si falla el provision, destruir y recrear
vagrant destroy database -f
vagrant up database
```

---

## Problema 3: QEMU Warning "high-level network configurations will be silently ignored"

### ¿Por qué pasa?
Es una advertencia normal de QEMU. Las configuraciones de red de Vagrant se ignoran parcialmente, pero las IPs privadas funcionan correctamente.

### ✅ SOLUCIÓN:
**No requiere acción** - Es solo una advertencia. Las VMs funcionarán correctamente con las IPs privadas (COMUNICACIÓN ENTRE VMs):
- database: 192.168.56.30
- webserver: 192.168.56.20  
- loadbalancer: 192.168.56.10
- monitoring: 192.168.56.40

Nota importante (macOS + qemu en Apple Silicon): desde tu Mac (host) la red privada host-only puede no ser accesible directamente. Usa SIEMPRE el port forwarding para acceder a servicios desde el host:
- PostgreSQL (database): localhost:5433 -> 192.168.56.30:5432
- Load Balancer (web): http://localhost:8080 -> 192.168.56.10:80

---

## Problema 4: "Connection reset. Retrying..." durante el arranque

### ¿Por qué pasa?
Es normal durante el primer arranque mientras la VM inicializa SSH.

### ✅ SOLUCIÓN:
**Esperar pacientemente** - La VM completará el arranque automáticamente. El proceso toma 2-5 minutos.

---

## ⚡ COMANDOS DE VERIFICACIÓN RÁPIDA (Windows)

### Verificar estado general:
```powershell
# Ver todas las VMs del proyecto
vagrant status

# Ver todas las VMs del sistema
vagrant global-status --prune

# Probar puerto PostgreSQL forwardeado
Test-NetConnection -ComputerName 127.0.0.1 -Port 5433
```

### Si todo falla, reset completo:
```bash
# 1. Destruir todo
vagrant destroy -f

# 2. Limpiar cache
rm -rf .vagrant/
vagrant global-status --prune

# 3. Verificar Ansible
ansible --version

# 4. Empezar de nuevo
vagrant up database
```

---

## 📋 CHECKLIST PRE-ARRANQUE

Antes de ejecutar `vagrant up`, verifica:

- [ ] ✅ `ansible --version` funciona
- [ ] ✅ `vagrant global-status` no muestra VMs en conflicto  
- [ ] ✅ Estás en el directorio correcto (`vagrant-ansible-workshop`)
- [ ] ✅ Tienes espacio en disco (mínimo 8GB)
- [ ] ✅ Tienes RAM disponible (mínimo 6GB)

---

## 🎯 FLUJO RECOMENDADO TRAS ERRORES

1. **Leer el error completo** - No te asustes por los warnings
2. **Verificar pre-requisitos** - Especialmente Ansible
3. **Limpiar conflictos** - Destruir VMs anteriores si es necesario
4. **Intentar de nuevo** - La mayoría de errores se resuelven así
5. **Si persiste** - Seguir las soluciones específicas de arriba

---

## Problema 5: Ansible no conecta correctamente con QEMU

### ¿Por qué pasa?
QEMU en Mac M2 no soporta completamente las configuraciones de red avanzadas de Vagrant, causando problemas de conectividad con Ansible.

### ✅ SOLUCIÓN ALTERNATIVA - Shell Provisioning:
```bash
# Si Ansible falla, usar shell provisioning directo
vagrant ssh database -c "sudo bash -s" < provision_database.sh

# Verificar que funcionó
vagrant ssh database -c "sudo systemctl status postgresql"
vagrant ssh database -c "sudo -u postgres psql -d examenes_db -c 'SELECT COUNT(*) FROM users;'"
```

### ✅ Para continuar con el taller:
1. La VM database ya está configurada con PostgreSQL
2. Puedes seguir con las otras VMs usando shell scripts similares
3. O enfocarte en aprender los conceptos de Vagrant + automatización

---

## Problema 6: No puedo conectar a 192.168.56.30:5432 desde mi Mac

### ¿Por qué pasa?
En macOS con qemu (Mac M1/M2/M3), la interfaz privada (host-only) de las VMs a veces no es alcanzable desde el host. Esto afecta pruebas como `nc -zv 192.168.56.30 5432` o conexiones `psql` directas a esa IP.

### ✅ SOLUCIÓN (recomendado): usar port forwarding
```bash
# Verificar el puerto forwardeado de PostgreSQL
nc -zv 127.0.0.1 5433

# Conectar con psql usando variable de entorno para la contraseña
export EXAMENES_DB_PASSWORD='tu_password_segura'
PGPASSWORD=$EXAMENES_DB_PASSWORD psql -h 127.0.0.1 -p 5433 -U examenes_user -d examenes_db -c "\\dt"
```

### Opcional: ¿Quieres habilitar acceso por IP privada de verdad?
Solo si realmente lo necesitas (por ejemplo, para conexiones desde otra máquina en la misma red host-only):
1) Asegura que PostgreSQL escuche en todas las interfaces dentro de la VM (esto suele ya estar OK para el forward):
```bash
sudo -u postgres psql -c "SHOW listen_addresses;"
# Si devuelve 'localhost', puedes cambiar a '*':
sudo sed -i "s/^#\?listen_addresses.*/listen_addresses = '*'/'" /etc/postgresql/*/main/postgresql.conf
sudo systemctl reload postgresql
```
2) Asegura que pg_hba.conf permite tu subred host-only (192.168.56.0/24):
```bash
sudo sh -c 'echo "host    all    all    192.168.56.0/24    md5" >> /etc/postgresql/*/main/pg_hba.conf'
sudo systemctl reload postgresql
```
3) Revisa firewall en la VM (si aplica):
```bash
sudo ufw status || true
sudo ufw allow 5432/tcp || true
```

> Aun con estos cambios, en macOS + qemu puede no funcionar el acceso desde el host a 192.168.56.30:5432. Por eso se recomienda el port forwarding.

---

**💡 TIP**: La mayoría de problemas se deben a VMs anteriores corriendo o Ansible no instalado. ¡Estos dos checks resuelven el 90% de los casos!
