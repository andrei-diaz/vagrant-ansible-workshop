# SOLUCIÓN A PROBLEMAS COMUNES

*Este archivo se completará con problemas reales encontrados durante las pruebas.*

---

## FASE 1: Problemas de Preparación

### Windows + VirtualBox

*Los problemas específicos del taller aparecerán aquí durante las pruebas...*

#### ℹ️ Nota: Requisitos previos

Antes de comenzar con el taller, asegúrate de tener instalados:
- VirtualBox 7.0+
- Vagrant 2.4.0+
- Git

Puedes verificar con:
```bash
vagrant --version
VBoxManage --version
```

Si no están instalados, consulta el README.md para instrucciones de instalación.

---

## FASE 2: Problemas durante el arranque de VMs

### Database VM (PostgreSQL)

*Los problemas específicos aparecerán aquí...*

### Web Server VM (PHP + CakePHP)

*Los problemas específicos aparecerán aquí...*

### Load Balancer VM (Nginx)

*Los problemas específicos aparecerán aquí...*

### Monitoring VM (Grafana + Prometheus)

*Los problemas específicos aparecerán aquí...*

---

## FASE 3: Problemas de Conectividad

*Los problemas de red entre VMs aparecerán aquí...*

---

## FASE 4: Problemas de Aplicación

*Los problemas funcionales de la aplicación aparecerán aquí...*

---

## Comandos Útiles para Diagnóstico

### Verificar estado general:
```powershell
# Ver todas las VMs del proyecto
vagrant status

# Ver todas las VMs del sistema
vagrant global-status --prune
```

### Reset completo (si todo falla):
```powershell
# 1. Destruir todo
vagrant destroy -f

# 2. Limpiar cache
rm -rf .vagrant/
vagrant global-status --prune

# 3. Empezar de nuevo
vagrant up
```

---

## Checklist Pre-Arranque

Antes de ejecutar `vagrant up`, verifica:

- [ ] VirtualBox instalado y funcionando
- [ ] Vagrant instalado
- [ ] Estás en el directorio correcto (`vagrant-ansible-workshop`)
- [ ] Tienes espacio en disco (mínimo 8GB)
- [ ] Tienes RAM disponible (mínimo 6GB)
- [ ] No hay otras VMs de Vagrant corriendo

---

*Este archivo se irá actualizando con los problemas reales que encontremos durante las pruebas.*
