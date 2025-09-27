# GUÍA PASO A PASO (Windows + VirtualBox)

## Objetivo
Ejecutar el taller completo en Windows 10/11 usando Vagrant + VirtualBox, con 5 VMs simultáneas y aprovisionamiento automático con Ansible.

---

## FASE 1: PREPARACIÓN INICIAL (Windows)

### Paso 1.0: Instalar dependencias (PowerShell como Administrador)
```powershell
# Instalar Chocolatey (si no lo tienes)
Set-ExecutionPolicy Bypass -Scope Process -Force; `
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; `
iwr https://community.chocolatey.org/install.ps1 -UseBasicParsing | iex

# Instalar VirtualBox, Vagrant y Git
choco install -y virtualbox vagrant git

# (Opcional) Cliente psql para pruebas
choco install -y postgresql
```

### Paso 1.1: Verificar instalación y ubicación
```powershell
# Directorio del proyecto
Get-Location

# Versiones
vagrant --version
VBoxManage --version
```

### Paso 1.2: Configuración del Vagrantfile
**El Vagrantfile ya está configurado para Windows + VirtualBox**

**Características principales:**
- Usa `ubuntu/jammy64` (x86_64) compatible con VirtualBox
- Configuración optimizada de VirtualBox para Windows
- Clonado automático desde GitHub
- Todos los providers configurados para VirtualBox
- Configuración de SSH adaptada para Windows

**Aplicación integrada:**
No necesitas descargar ni configurar nada manualmente. El Vagrantfile:
- Clona automáticamente desde: `https://github.com/andrei-diaz/examenes_sistema.git`
- Instala en la VM webserver en: `/var/www/examenes_sistema`
- Configura permisos automáticamente para el usuario `www-data`

Si quieres usar otro repositorio, modifica la URL en la línea 76 del Vagrantfile.

### Paso 1.3: Verificar la configuración

Puedes revisar el Vagrantfile actual para verificar todas las configuraciones.

### Paso 1.3: Entender el inventario de Ansible (NO necesitas crear nada)

**IMPORTANTE: El inventario ya existe en `ansible/inventory/hosts` y funciona automáticamente.**

Para tu referencia, así es como Ansible identifica las máquinas virtuales:

**Estructura del inventario:**
```ini
[loadbalancer]        # Grupo para el balanceador de carga
examenes-lb ansible_host=192.168.56.10

[webservers]          # Grupo para servidores web
examenes-web ansible_host=192.168.56.20

[database]            # Grupo para base de datos
examenes-db ansible_host=192.168.56.30

[monitoring]          # Grupo para monitoreo
examenes-monitoring ansible_host=192.168.56.40

[orchestrator]        # Grupo para orquestador
examenes-orchestrator ansible_host=192.168.56.50
```

**¿Qué significa esto?**
- Cada VM tiene una IP fija en la red privada 192.168.56.x
- Ansible usa estas IPs para configurar los servicios automáticamente
- Los "grupos" permiten aplicar configuración a tipos de servidores
- Por ejemplo: `[webservers]` recibe la configuración de PHP y Nginx

**No necesitas modificar nada** - Vagrant y Ansible manejan esto automáticamente.

---

## FASE 2: INICIO DE LA INFRAESTRUCTURA

### Paso 2.1: Levantar la Base de Datos
```powershell
vagrant up database
```

**Mensaje esperado al finalizar:**
```
==> database: Running provisioner: ansible...
==> database: PLAY RECAP *********************************************************************
==> database: examenes-db              : ok=XX   changed=XX   unreachable=0    failed=0
```

#### Verificaciones de la VM Database:

**1. Verificar que PostgreSQL está corriendo:**
```powershell
vagrant ssh database -c "sudo systemctl status postgresql --no-pager"
```
**Resultado esperado:** `Active: active (running)`

**2. Verificar que la base de datos fue creada:**
```powershell
vagrant ssh database -c "sudo -u postgres psql -d examenes_db -c \"\\dt\""
```
**Resultado esperado:** Lista de tablas del sistema de exámenes

**3. Probar acceso desde Windows (port forwarding):**
```powershell
Test-NetConnection -ComputerName 127.0.0.1 -Port 5433
```
**Resultado esperado:** `TcpTestSucceeded : True`

**4. Verificar usuario y base de datos:**
```powershell
vagrant ssh database -c "sudo -u postgres psql -c \"\\du\""
```
**Resultado esperado:** Usuario `examenes_user` debe aparecer en la lista

### Paso 2.2: Levantar el Servidor Web
```powershell
vagrant up webserver
```

**Mensaje esperado al finalizar:**
```
==> webserver: Running provisioner: shell...
==> webserver: Aplicación clonada desde GitHub exitosamente
==> webserver: PLAY RECAP *********************************************************************
==> webserver: examenes-web            : ok=XX   changed=XX   unreachable=0    failed=0
```

#### Verificaciones de la VM Web Server:

**1. Verificar que Nginx está corriendo:**
```powershell
vagrant ssh webserver -c "sudo systemctl status nginx --no-pager"
```
**Resultado esperado:** `Active: active (running)`

**2. Verificar que PHP-FPM está corriendo:**
```powershell
vagrant ssh webserver -c "sudo systemctl status php8.3-fpm --no-pager"
```
**Resultado esperado:** `Active: active (running)`

**3. Verificar que la aplicación se clonó correctamente:**
```powershell
vagrant ssh webserver -c "ls -la /var/www/examenes_sistema/"
```
**Resultado esperado:** Archivos del proyecto CakePHP (src/, config/, webroot/, etc.)

**4. Verificar configuración de base de datos:**
```powershell
vagrant ssh webserver -c "cat /var/www/examenes_sistema/config/app_local.php"
```
**Resultado esperado:** Configuración con host `192.168.56.30` y usuario `examenes_user`

**5. Probar respuesta HTTP interna:**
```powershell
vagrant ssh webserver -c "curl -s -o /dev/null -w '%{http_code}' http://localhost/"
```
**Resultado esperado:** Código `200` o `302`

### Paso 2.3: Levantar el Load Balancer
```powershell
vagrant up loadbalancer
```

**Mensaje esperado al finalizar:**
```
==> loadbalancer: PLAY RECAP *********************************************************************
==> loadbalancer: examenes-lb           : ok=XX   changed=XX   unreachable=0    failed=0
```

#### Verificaciones de la VM Load Balancer:

**1. Verificar que Nginx está corriendo:**
```powershell
vagrant ssh loadbalancer -c "sudo systemctl status nginx --no-pager"
```
**Resultado esperado:** `Active: active (running)`

**2. Verificar configuración del proxy:**
```powershell
vagrant ssh loadbalancer -c "sudo nginx -t"
```
**Resultado esperado:** `nginx: configuration file /etc/nginx/nginx.conf test is successful`

**3. Verificar que puede conectar al webserver:**
```powershell
vagrant ssh loadbalancer -c "curl -s -o /dev/null -w '%{http_code}' http://192.168.56.20/"
```
**Resultado esperado:** Código `200` o `302`

**4. Probar desde Windows:**
```powershell
Invoke-WebRequest -UseBasicParsing -Uri http://localhost:8080 | Select-Object -ExpandProperty StatusCode
```
**Resultado esperado:** `200`

**5. Abrir en navegador:**
```powershell
start http://localhost:8080
```
**Resultado esperado:** Página de inicio del sistema de exámenes

### Paso 2.4: Levantar Monitoreo
```powershell
vagrant up monitoring
```

**Mensaje esperado al finalizar:**
```
==> monitoring: PLAY RECAP *********************************************************************
==> monitoring: examenes-monitoring     : ok=XX   changed=XX   unreachable=0    failed=0
```

#### Verificaciones de la VM Monitoring:

**1. Verificar que Grafana está corriendo:**
```powershell
vagrant ssh monitoring -c "sudo systemctl status grafana-server --no-pager"
```
**Resultado esperado:** `Active: active (running)`

**2. Verificar que Prometheus está corriendo:**
```powershell
vagrant ssh monitoring -c "sudo systemctl status prometheus --no-pager"
```
**Resultado esperado:** `Active: active (running)`

**3. Verificar que Node Exporter está corriendo:**
```powershell
vagrant ssh monitoring -c "sudo systemctl status node_exporter --no-pager"
```
**Resultado esperado:** `Active: active (running)`

**4. Probar Grafana desde Windows:**
```powershell
Invoke-WebRequest -UseBasicParsing -Uri http://localhost:3000 | Select-Object -ExpandProperty StatusCode
```
**Resultado esperado:** `200`

**5. Probar Prometheus desde Windows:**
```powershell
Invoke-WebRequest -UseBasicParsing -Uri http://localhost:9090 | Select-Object -ExpandProperty StatusCode
```
**Resultado esperado:** `200`

**6. Abrir Grafana en navegador:**
```powershell
start http://localhost:3000
```
**Resultado esperado:** Pantalla de login de Grafana (admin/admin)

**7. Abrir Prometheus en navegador:**
```powershell
start http://localhost:9090
```
**Resultado esperado:** Interfaz de Prometheus con métricas

---

## FASE 3: PRUEBAS DE CONECTIVIDAD ENTRE VMs

### 3.1 Probar conectividad entre Web Server y Database
```powershell
vagrant ssh webserver -c "nc -zv -w3 192.168.56.30 5432"
```
**Resultado esperado:** `Connection to 192.168.56.30 5432 port [tcp/postgresql] succeeded!`

### 3.2 Probar conectividad entre Load Balancer y Web Server  
```powershell
vagrant ssh loadbalancer -c "nc -zv -w3 192.168.56.20 80"
```
**Resultado esperado:** `Connection to 192.168.56.20 80 port [tcp/http] succeeded!`

### 3.3 Probar conectividad de Monitoring a otras VMs
```powershell
vagrant ssh monitoring -c "nc -zv -w3 192.168.56.10 80"  # Load Balancer
vagrant ssh monitoring -c "nc -zv -w3 192.168.56.20 80"  # Web Server
vagrant ssh monitoring -c "nc -zv -w3 192.168.56.30 5432" # Database
```
**Resultado esperado:** Todas las conexiones deben ser exitosas

---

## FASE 4: PRUEBAS FUNCIONALES DE LA APLICACIÓN

### 4.1 Probar Base de Datos desde Windows

**Conectar usando psql (requiere PostgreSQL client instalado):**
```powershell
$env:PGPASSWORD = 'examenes_password_123'
psql -h 127.0.0.1 -p 5433 -U examenes_user -d examenes_db -c "\\dt"
```
**Resultado esperado:** Lista de tablas como `users`, `especialidades`, `examenes`, etc.

**Verificar datos de prueba:**
```powershell
$env:PGPASSWORD = 'examenes_password_123'
psql -h 127.0.0.1 -p 5433 -U examenes_user -d examenes_db -c "SELECT email FROM users LIMIT 3;"
```
**Resultado esperado:** 
```
              email               
----------------------------------
 admin@examenes.com
 profesor@examenes.com
 estudiante@examenes.com
```

### 4.2 Pruebas de la Aplicación Web

**1. Abrir la aplicación:**
```powershell
start http://localhost:8080
```
**Resultado esperado:** Página de inicio del Sistema de Exámenes Médicos

**2. Probar login con credenciales de administrador:**
- URL: `http://localhost:8080/login`
- Email: `admin@examenes.com`
- Password: `admin123`

**Resultado esperado:** Acceso al panel de administración

**3. Probar login con credenciales de profesor:**
- Email: `profesor@examenes.com`
- Password: `profesor123`

**Resultado esperado:** Acceso al panel de profesor

**4. Verificar que la aplicación puede conectar a la base de datos:**
```powershell
vagrant ssh webserver -c "cd /var/www/examenes_sistema && php bin/cake.php migrations status"
```
**Resultado esperado:** Estado de las migraciones (deberían estar aplicadas)

### 4.3 Pruebas del Sistema de Monitoreo

**1. Abrir Grafana:**
```powershell
start http://localhost:3000
```
- Login: `admin` / `admin`
**Resultado esperado:** Dashboard de Grafana con métricas del sistema

**2. Abrir Prometheus:**
```powershell
start http://localhost:9090
```
**Resultado esperado:** Interfaz de Prometheus
- Ir a Status > Targets
- Verificar que los targets estén "UP"

**3. Verificar métricas específicas en Prometheus:**
- Query: `up` - Debe mostrar todas las VMs
- Query: `node_memory_MemTotal_bytes` - Memoria de las VMs
- Query: `node_cpu_seconds_total` - CPU usage

### 4.4 Prueba de Balanceador de Carga

**Verificar que el Load Balancer distribuye correctamente:**
```powershell
# Hacer múltiples requests
for($i=1; $i -le 5; $i++) {
    Invoke-WebRequest -UseBasicParsing -Uri http://localhost:8080 | Select-Object StatusCode
    Start-Sleep 1
}
```
**Resultado esperado:** Todas las respuestas deben ser 200

**Verificar logs del Load Balancer:**
```powershell
vagrant ssh loadbalancer -c "sudo tail -f /var/log/nginx/access.log"
```
**Resultado esperado:** Requests siendo loggeados en tiempo real

---

## RESUMEN DE PUERTOS Y SERVICIOS

| Servicio | VM | IP Interna | Puerto | Acceso desde Windows | Estado Esperado |
|---|---|---|---|---|---|
| PostgreSQL | database | 192.168.56.30 | 5432 | localhost:5433 | Active (running) |
| App Web | webserver | 192.168.56.20 | 80 | vía LB localhost:8080 | Active (running) |
| Load Balancer | loadbalancer | 192.168.56.10 | 80 | http://localhost:8080 | Active (running) |
| Grafana | monitoring | 192.168.56.40 | 3000 | http://localhost:3000 | Active (running) |
| Prometheus | monitoring | 192.168.56.40 | 9090 | http://localhost:9090 | Active (running) |
| Node Exporter | monitoring | 192.168.56.40 | 9100 | Interno | Active (running) |

---

## CHECKLIST DE VERIFICACIÓN COMPLETA

### Database VM (192.168.56.30)
- [ ] PostgreSQL service active
- [ ] Base de datos `examenes_db` creada
- [ ] Usuario `examenes_user` existe
- [ ] Puerto 5433 accesible desde Windows
- [ ] Tablas del sistema creadas
- [ ] Datos de prueba insertados (3 usuarios)

### Web Server VM (192.168.56.20)
- [ ] Nginx service active
- [ ] PHP 8.3-FPM service active
- [ ] Aplicación clonada en `/var/www/examenes_sistema`
- [ ] Configuración de base de datos correcta
- [ ] Permisos de archivos configurados
- [ ] Respuesta HTTP 200/302 local

### Load Balancer VM (192.168.56.10)
- [ ] Nginx service active
- [ ] Configuración de proxy correcta
- [ ] Conectividad al webserver
- [ ] Puerto 8080 accesible desde Windows
- [ ] Página de la aplicación carga correctamente

### Monitoring VM (192.168.56.40)
- [ ] Grafana service active
- [ ] Prometheus service active
- [ ] Node Exporter service active
- [ ] Puerto 3000 accesible (Grafana)
- [ ] Puerto 9090 accesible (Prometheus)
- [ ] Targets "UP" en Prometheus
- [ ] Login Grafana funcional (admin/admin)

### Pruebas de Integración
- [ ] Conectividad entre VMs verificada
- [ ] Login en aplicación con admin@examenes.com
- [ ] Login en aplicación con profesor@examenes.com
- [ ] Métricas visibles en Prometheus
- [ ] Dashboards funcionales en Grafana
- [ ] Consultas a base de datos desde Windows

### Lo que debes ver al final:
1. **http://localhost:8080** - Sistema de Exámenes funcionando
2. **http://localhost:3000** - Grafana con dashboards
3. **http://localhost:9090** - Prometheus con métricas
4. **localhost:5433** - PostgreSQL accesible
5. **VirtualBox** - 4 VMs corriendo (database, webserver, loadbalancer, monitoring)

---

## TROUBLESHOOTING (Windows)

**Ver puertos en uso:**
```powershell
netstat -ano | findstr :8080
netstat -ano | findstr :5433
netstat -ano | findstr :3000
```

**Probar conectividad a puertos:**
```powershell
Test-NetConnection -ComputerName 127.0.0.1 -Port 5433  # PostgreSQL
Test-NetConnection -ComputerName 127.0.0.1 -Port 8080  # Load Balancer
Test-NetConnection -ComputerName 127.0.0.1 -Port 3000  # Grafana
```

**Reiniciar una VM con re-aprovisionamiento:**
```powershell
vagrant reload database --provision
vagrant reload webserver --provision
```

**Ver logs de una VM:**
```powershell
vagrant ssh database -c "sudo journalctl -u postgresql -f"
vagrant ssh webserver -c "sudo tail -f /var/log/nginx/error.log"
```

**Verificar estado de todas las VMs:**
```powershell
vagrant status
```
