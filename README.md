# DDNS Updater (Android & Android TV)

## Visión General del Proyecto
Esta aplicación nace de una necesidad práctica: mantener actualizada la IP dinámica (DDNS) de una red doméstica sin depender de hardware costoso o difícil de conseguir (como una Raspberry Pi) o de routers con capacidades limitadas.

**La idea central** es reutilizar dispositivos que ya tenemos en casa, específicamente:
*   Celulares Android antiguos.
*   Dispositivos Android TV (que suelen estar siempre conectados y encendidos).

## El Reto Tecnológico
El desafío principal, especialmente en **Android TV**, es asegurar que la aplicación funcione de manera fiable en **segundo plano**. A diferencia de un celular que consultamos constantemente, un Android TV puede estar "durmiendo" o usándose para streaming, y nuestra aplicación debe ser capaz de despertar periódicamente, verificar la IP pública y actualizarla en el proveedor de DDNS si ha cambiado.

## Funcionalidad Actual
*   **Proveedor soportado incialmente**: DuckDNS (por su flexibilidad y simplicidad).
*   **Plataformas**: Android Móvil y Android TV.
*   **Mecanismo**: Servicio en segundo plano que monitoriza cambios en la IP pública.

## Futuro
Se planea expandir la lista de proveedores de DDNS soportados una vez consolidada la estabilidad del servicio en segundo plano.
