# Taller Vagrant + Ansible: Sistema de Exámenes Médicos
🆕 **Ahora Compatible con Windows + VirtualBox**

## 📋 Descripción del Proyecto

Este taller demuestra el poder de Vagrant + Ansible creando una infraestructura completa para desplegar automáticamente tu Sistema de Exámenes Médicos (CakePHP 5 + PostgreSQL) en múltiples máquinas virtuales con orquestación completa.

### 🔧 Compatibilidad Multiplataforma
- ✅ **Windows 10/11** + VirtualBox (configuración actual)
- ✅ **macOS** (Intel/M1/M2) + QEMU
- ✅ **Linux** + VirtualBox/QEMU

### Objetivos del Taller
- Demostrar aprovisionamiento automático con Vagrant
- Implementar orquestación avanzada con Ansible
- Desplegar aplicación PHP real (CakePHP 5)
- Configurar infraestructura completa de producción
- Mostrar integración de monitoreo y balanceadores de carga

## Arquitectura del Sistema

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Load Balancer  │    │   Web Server    │    │    Database     │
│    (Nginx)      │────│ PHP 8.3 + Nginx │────│   PostgreSQL    │
│  192.168.56.10  │    │  192.168.56.20  │    │  192.168.56.30  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                       ┌─────────────────┐    ┌─────────────────┐
                       │   Monitoring    │    │  Orchestrator   │
                       │ Grafana+Prome.  │    │   (Control)     │
                       │  192.168.56.40  │    │  192.168.56.50  │
                       └─────────────────┘    └─────────────────┘
```

### Máquinas Virtuales

| VM                | Hostname              | IP            | Servicios                 | Memoria | CPU |
|-------------------|-----------------------|---------------|---------------------------|---------|-----|
|   Load Balancer   | examenes-lb           | 192.168.56.10 | Nginx (Proxy Reverso)     | 512MB   | 1   |
|   Web Server      | examenes-web          | 192.168.56.20 | PHP 8.3, Nginx, CakePHP 5 | 2GB     | 2   |
|   Database        | examenes-db           | 192.168.56.30 | PostgreSQL 15             | 1.5GB   | 2   |
|   Monitoring      |  examenes-monitoring  | 192.168.56.40 | Grafana, Prometheus       | 1GB     | 2   |
|   Orchestrator    | examenes-orchestrator | 192.168.56.50 | Ansible Control Node      | 512MB   | 1   |

##  Requisitos Previos

### Windows 10/11 (recomendado para este taller)
- ✅ Vagrant 2.4.9+
- ✅ VirtualBox 7+
- ✅ Git
- ⚠️ Ansible NO es requerido en el host (usamos ansible_local dentro de las VMs)

### 💿 Instalación en Windows (PowerShell como Administrador)
```powershell
# Instalar Chocolatey (si no lo tienes)
Set-ExecutionPolicy Bypass -Scope Process -Force; `
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; `
iwr https://community.chocolatey.org/install.ps1 -UseBasicParsing | iex

# Instalar VirtualBox y Vagrant
choco install -y virtualbox vagrant git

# (Opcional) Cliente psql para pruebas
choco install -y postgresql
```

### Verificación de Componentes
```bash
# Verificar versiones
vagrant --version
qemu-system-aarch64 --version
vagrant plugin list | grep vagrant-qemu
ansible --version
```

##  Inicio Rápido

### 1. Aplicación Integrada 🚀
✅ **¡No necesitas clonar nada manualmente!**

El Vagrantfile ahora clona automáticamente tu aplicación desde GitHub:
- **Repo:** `https://github.com/andrei-diaz/examenes_sistema.git`
- **Ubicación:** `/var/www/examenes_sistema` en la VM del webserver
- **Permisos:** Configurados automáticamente

### 2. Iniciar la Infraestructura Completa
```bash
cd /Users/andreidiazrosario/Documents/School/vagrant-ansible-workshop

# Levantar TODAS las VMs con aprovisionamiento automático
vagrant up

# O levantar una VM específica
vagrant up loadbalancer
vagrant up webserver
vagrant up database
```

### 3. Verificar el Despliegue
Una vez completado el proceso (15-20 minutos), tendrás acceso a:

| Servicio                 | URL                   | Credenciales                          |
|--------------------------|-----------------------|---------------------------------------|
|   Aplicación Principal   | http://localhost:8080 | admin@examenes.com / admin123         |
|   Acceso Directo Web     | http://192.168.56.20  | -                                     |
|   Grafana Monitoring     | http://localhost:3000 | admin / admin                         |
|   PostgreSQL             | localhost:5433        | examenes_user / examenes_password_123 |

## Estructura del Proyecto

```
vagrant-ansible-workshop/
├── Vagrantfile                    # Configuración de VMs
├── README.md                      # Esta documentación
└── ansible/
    ├── inventory/
    │   └── hosts                  # Inventario de servidores
    ├── site.yml                   # Playbook principal
    ├── database.yml               # Configuración PostgreSQL
    ├── web_server.yml            # Configuración PHP+Nginx
    ├── load_balancer.yml         # Configuración Nginx LB
    ├── monitoring.yml            # Grafana + Prometheus
    └── group_vars/
        └── all.yml               # Variables globales
```

## Características Avanzadas del Taller

### Aprovisionamiento Automático
- Vagrant: Gestión de VMs y networking
- Ansible: Configuración de software y servicios
- Orquestación: Dependencias entre servicios
- Verificación: Health checks automáticos

### Aplicación Real Integrada
- CakePHP 5: Framework PHP moderno
- PostgreSQL 15: Base de datos robusta
- Datos de Prueba: Reactivos médicos precargados
- Autenticación: Sistema de usuarios completo

### Monitoreo y Observabilidad
- Grafana: Dashboard de métricas
- Prometheus: Recolección de métricas
- Logs Centralizados: Agregación de logs
- Alertas: Notificaciones automáticas

### Alta Disponibilidad
- Load Balancer: Nginx como proxy reverso
- Separación de Servicios: Microservicios approach
- Backup Automático: Base de datos
- Health Checks: Verificación de servicios

## Comandos Útiles

### Gestión de VMs
```bash
# Ver estado de todas las VMs
vagrant status

# Conectar por SSH a una VM específica
vagrant ssh webserver
vagrant ssh database

# Reiniciar una VM
vagrant reload webserver --provision

# Suspender/reanudar
vagrant suspend
vagrant resume

# Destruir todo
vagrant destroy -f
```

### Ansible Manual
```bash
# Ejecutar playbook específico
ansible-playbook -i ansible/inventory/hosts ansible/database.yml

# Verificar conectividad
ansible -i ansible/inventory/hosts all -m ping

# Ejecutar comando en todas las VMs
ansible -i ansible/inventory/hosts examenes_infrastructure -a "uptime"
```

### Debugging
```bash
# Logs de Vagrant
VAGRANT_LOG=info vagrant up

# Modo verbose de Ansible
ansible-playbook -vvv -i ansible/inventory/hosts ansible/site.yml

# Ver procesos en las VMs
vagrant ssh webserver -c "sudo systemctl status nginx php8.3-fpm"
```

## Casos de Uso del Taller

### 1. Demo de DevOps Completo
- Muestra pipeline completo desde código hasta producción
- Infraestructura como código (IaC)
- Configuración automática de servicios

### 2. Entrenamiento en Herramientas
- Vagrant para gestión de VMs
- Ansible para configuración
- Networking entre servicios
- Monitoreo y observabilidad

### 3. Despliegue de Aplicación Real
- Sistema funcional de exámenes médicos
- Base de datos con datos de prueba
- Interfaz web completa
- Autenticación y autorización

## Troubleshooting

### Problemas Comunes

#### VM No Inicia
```bash
# Verificar QEMU
qemu-system-aarch64 --version

# Limpiar cache de Vagrant
vagrant destroy -f && rm -rf .vagrant
```

#### Error: "Forwarded port to 50022 is already in use"
```bash
# Ver todas las VMs activas
vagrant global-status

# Destruir VM conflictiva (usar el ID mostrado)
vagrant destroy [ID] -f

# O detener todas las VMs
vagrant global-status | grep running | awk '{print $1}' | xargs -I {} vagrant destroy {} -f
```

#### Error: "Ansible software could not be found"
```bash
# Instalar Ansible
brew install ansible

# Verificar instalación
ansible --version

# Re-intentar aprovisionamiento
vagrant provision [vm_name]
```

#### Error de Red
```bash
# Verificar interfaces de red
sudo ifconfig | grep 192.168.56

# Reiniciar networking
vagrant reload --provision
```

#### Falla de Aprovisionamiento
```bash
# Re-ejecutar solo Ansible
vagrant provision webserver

# Modo debug
ANSIBLE_STDOUT_CALLBACK=debug vagrant provision
```

## Métricas del Taller

### Tiempo de Despliegue
- Inicial completo: ~15-20 minutos
- Re-provision: ~5-10 minutos
- VM individual: ~3-5 minutos

### Recursos Utilizados
- RAM Total: ~5.5GB
- Disk Space: ~8GB
- CPU: 4 cores virtuales
- Network: Red privada 192.168.56.0/24

## Lo Que Este Taller Demuestra

### Poder de Vagrant
- Gestión de múltiples VMs
- Networking automático
- Sincronización de archivos
- Integración con providers (QEMU)

### Poder de Ansible
- Configuración declarativa
- Orquestación de servicios
- Idempotencia
- Roles reutilizables

### Integración Perfecta
- Vagrant levanta infraestructura
- Ansible configura software
- Aplicación real desplegada
- Monitoreo incluido

## Próximos Pasos

1. Explorar cada VM con `vagrant ssh`
2. Probar la aplicación en http://localhost:8080
3. Ver métricas en Grafana
4. Modificar playbooks y re-ejecutar
5. Experimentar con scaling horizontal

---

## Conclusión

Este taller demuestra que Vagrant + Ansible es una combinación poderosa para:

- Automatización completa de infraestructura
- Reproducibilidad de entornos
- Escalabilidad de servicios
- Gestión de configuración avanzada
- Integración de aplicaciones reales

¡Tu Sistema de Exámenes Médicos ahora tiene una infraestructura de clase mundial! 

---

Autor: Andrei Erik Rodrigo Díaz Rosario, Pablo Iaín Garza García
Fecha: Septiembre 2024  
Tecnologías: Vagrant 2.4.9, Ansible, QEMU/UTM, CakePHP 5, PostgreSQL 15