# Directorio de la Aplicación

Este directorio está configurado para sincronizarse con la máquina virtual del webserver.

## Instrucciones para Windows

1. Coloca aquí el código fuente de tu aplicación PHP/CakePHP
2. O cambia la ruta en el Vagrantfile (línea 70) para apuntar a tu proyecto existente

### Ejemplo de ruta para Windows:
```ruby
web.vm.synced_folder "C:/Users/TuUsuario/Documents/examenes_sistema", "/var/www/examenes_sistema"
```

### Estructura recomendada:
```
app/
├── src/
├── config/
├── public/
├── composer.json
└── ...
```