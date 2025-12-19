# Política de Privacidad de Bici Taxi

**Última actualización:** 19 de diciembre de 2024

---

## 1. Introducción

Bienvenido a **Bici Taxi**. Esta Política de Privacidad describe cómo recopilamos, usamos, almacenamos y protegemos tu información personal cuando utilizas nuestras aplicaciones móviles: **Bici Taxi** (para pasajeros) y **Bici Taxi Conductor** (para conductores).

Nos comprometemos a proteger tu privacidad y a ser completamente transparentes sobre el manejo de tus datos. **No vendemos, alquilamos ni compartimos tu información personal con terceros para fines de marketing o publicidad.**

---

## 2. Stack Tecnológico

Para brindar nuestro servicio, utilizamos las siguientes tecnologías:

### 2.1 Plataformas de Desarrollo
- **Flutter**: Framework de desarrollo multiplataforma para las aplicaciones móviles (Android e iOS)
- **Dart**: Lenguaje de programación utilizado en las aplicaciones

### 2.2 Servicios de Backend
- **Firebase Authentication**: Para la gestión segura de cuentas de usuario y autenticación
- **Cloud Firestore**: Base de datos en tiempo real para almacenar información de usuarios, viajes y solicitudes
- **Firebase Cloud Messaging (FCM)**: Para el envío de notificaciones push relacionadas con el servicio

### 2.3 Servicios de Ubicación
- **Google Maps Platform**: Para visualización de mapas y ubicaciones
- **Servicios de Geolocalización del dispositivo**: Para obtener la ubicación GPS del usuario

### 2.4 Infraestructura
- **Google Cloud Platform (GCP)**: Infraestructura de servidores que aloja los servicios de Firebase
- Los servidores están ubicados en Estados Unidos y cumplen con estándares internacionales de seguridad

---

## 3. Información que Recopilamos

### 3.1 Información de Registro de Cuenta

Cuando creas una cuenta, recopilamos:

| Dato | Propósito | Obligatorio |
|------|-----------|-------------|
| **Correo electrónico** | Identificación de cuenta, recuperación de contraseña, comunicaciones del servicio | Sí |
| **Nombre** | Identificación entre usuarios (pasajeros y conductores) | Sí |
| **Contraseña** | Seguridad de la cuenta (almacenada de forma encriptada) | Sí |

### 3.2 Información de Ubicación

Para el funcionamiento del servicio, recopilamos:

| Dato | Propósito | Cuándo se recopila |
|------|-----------|-------------------|
| **Ubicación GPS en tiempo real** | Conectar pasajeros con conductores cercanos | Solo mientras la app está activa |
| **Última ubicación conocida** | Mostrar conductores disponibles en el mapa | Actualizada periódicamente mientras está en línea |
| **Geo-células (celdas geográficas)** | Optimizar búsquedas de conductores por zona | Durante el uso activo |

### 3.3 Información de Viajes

Para cada solicitud de viaje, registramos:

- **Ubicación de solicitud**: Punto donde el pasajero solicitó el viaje
- **Hora de solicitud**: Marca de tiempo de la solicitud
- **Estado del viaje**: Pendiente, aceptado, en curso, completado, cancelado
- **ID del conductor asignado**: Para vincular pasajero con conductor

### 3.4 Información del Dispositivo

Recopilamos información técnica limitada:

- **Identificador único del dispositivo**: Para envío de notificaciones push
- **Sistema operativo**: Android o iOS
- **Versión de la aplicación**: Para soporte técnico

### 3.5 Información que NO Recopilamos

Queremos ser claros sobre lo que **NO** recopilamos:

- ❌ Información de tarjetas de crédito o métodos de pago
- ❌ Historial de navegación web
- ❌ Contactos del teléfono
- ❌ Mensajes de texto o llamadas
- ❌ Fotos o archivos personales
- ❌ Información de otras aplicaciones
- ❌ Datos biométricos
- ❌ Información de redes sociales

---

## 4. Cómo Usamos tu Información

Utilizamos tu información **exclusivamente** para:

### 4.1 Operación del Servicio
- ✅ Conectar pasajeros con conductores de bicitaxi cercanos
- ✅ Mostrar conductores disponibles en el mapa
- ✅ Procesar y gestionar solicitudes de viaje
- ✅ Enviar notificaciones sobre el estado de viajes

### 4.2 Seguridad y Soporte
- ✅ Verificar identidad de usuarios
- ✅ Prevenir fraude y abuso del servicio
- ✅ Resolver disputas entre usuarios
- ✅ Proporcionar soporte técnico

### 4.3 Mejoras del Servicio
- ✅ Analizar patrones de uso anónimos para mejorar la aplicación
- ✅ Identificar y corregir errores técnicos

---

## 5. Lo que NO Hacemos con tu Información

Nos comprometemos a **NUNCA**:

### 5.1 Venta de Datos
- ❌ **NO vendemos** tu información personal a terceros bajo ninguna circunstancia
- ❌ **NO vendemos** tus datos de ubicación a empresas de datos
- ❌ **NO vendemos** información agregada o anonimizada

### 5.2 Marketing y Publicidad
- ❌ **NO usamos** tus datos para mostrarte anuncios personalizados
- ❌ **NO compartimos** tu información con redes publicitarias
- ❌ **NO creamos** perfiles de marketing basados en tu comportamiento
- ❌ **NO enviamos** correos de marketing o promocionales de terceros

### 5.3 Compartición con Terceros
- ❌ **NO compartimos** tu información con empresas de análisis de datos
- ❌ **NO proporcionamos** acceso a tus datos a socios comerciales
- ❌ **NO vendemos** listas de usuarios o contactos

---

## 6. Almacenamiento y Seguridad de Datos

### 6.1 Dónde se Almacenan tus Datos
- Los datos se almacenan en servidores seguros de **Google Cloud Platform**
- Los servidores están ubicados en **Estados Unidos**
- Firebase cumple con certificaciones de seguridad: SOC 1, SOC 2, SOC 3, ISO 27001

### 6.2 Medidas de Seguridad
Implementamos las siguientes medidas de seguridad:

- **Encriptación en tránsito**: Todos los datos se transmiten usando HTTPS/TLS
- **Encriptación en reposo**: Los datos almacenados están encriptados
- **Contraseñas hasheadas**: Las contraseñas nunca se almacenan en texto plano
- **Reglas de seguridad de Firestore**: Acceso a datos restringido por usuario
- **Autenticación segura**: Tokens de sesión con expiración automática

### 6.3 Retención de Datos
- **Datos de cuenta**: Se mantienen mientras la cuenta esté activa
- **Datos de ubicación**: Se sobrescriben con cada actualización (no se almacena historial)
- **Historial de viajes**: Se mantiene por 12 meses para fines de soporte
- **Datos eliminados**: Se borran permanentemente dentro de 30 días tras la solicitud

---

## 7. Tus Derechos como Usuario

Tienes los siguientes derechos sobre tus datos:

### 7.1 Derecho de Acceso
- Puedes solicitar una copia de toda la información que tenemos sobre ti

### 7.2 Derecho de Rectificación
- Puedes actualizar tu nombre y otros datos de perfil desde la aplicación
- Puedes solicitar correcciones de información incorrecta

### 7.3 Derecho de Eliminación
- Puedes eliminar tu cuenta en cualquier momento desde la aplicación
- Al eliminar tu cuenta, todos tus datos personales serán borrados permanentemente

### 7.4 Derecho de Portabilidad
- Puedes solicitar una exportación de tus datos en formato legible

### 7.5 Cómo Ejercer tus Derechos
Para ejercer cualquiera de estos derechos, contáctanos a:
- **Correo electrónico**: zarabandadev@gmail.com

---

## 8. Uso de la Ubicación

### 8.1 Por qué Necesitamos tu Ubicación
La ubicación es esencial para el funcionamiento de Bici Taxi:

- **Pasajeros**: Para encontrar conductores cercanos y solicitar viajes
- **Conductores**: Para aparecer disponibles en el mapa y recibir solicitudes

### 8.2 Cuándo se Accede a la Ubicación
- **Solo cuando la app está en uso activo** (foreground)
- **Conductores en línea**: La ubicación se actualiza periódicamente mientras están disponibles
- **No rastreamos** la ubicación cuando la app está cerrada

### 8.3 Precisión de la Ubicación
- Utilizamos GPS del dispositivo para ubicación precisa
- No almacenamos historial de ubicaciones pasadas
- La ubicación se sobrescribe con cada actualización

### 8.4 Control del Usuario
- Puedes desactivar los permisos de ubicación en cualquier momento desde la configuración de tu dispositivo
- Sin acceso a ubicación, algunas funciones de la app no estarán disponibles

---

## 9. Notificaciones Push

### 9.1 Tipos de Notificaciones
Enviamos notificaciones únicamente relacionadas con el servicio:

- **Pasajeros**: Conductor encontrado, viaje aceptado, conductor en camino
- **Conductores**: Nueva solicitud de viaje disponible

### 9.2 Gestión de Notificaciones
- Puedes desactivar las notificaciones desde la configuración de tu dispositivo
- No enviamos notificaciones promocionales o de marketing

---

## 10. Menores de Edad

Bici Taxi no está dirigido a menores de 18 años. No recopilamos intencionalmente información de menores. Si descubrimos que hemos recopilado datos de un menor, los eliminaremos inmediatamente.

---

## 11. Cambios a esta Política

Podemos actualizar esta Política de Privacidad ocasionalmente. En caso de cambios significativos:

- Publicaremos la nueva política en la aplicación
- Actualizaremos la fecha de "Última actualización"
- Para cambios materiales, te notificaremos por correo electrónico o notificación en la app

Te recomendamos revisar esta política periódicamente.

---

## 12. Información de Contacto

Si tienes preguntas, comentarios o solicitudes relacionadas con esta Política de Privacidad o el manejo de tus datos, puedes contactarnos:

- **Correo electrónico**: zarabandadev@gmail.com
- **Desarrollador**: José L. Zarabanda

---

## 13. Jurisdicción y Ley Aplicable

Esta Política de Privacidad se rige por las leyes de México. Cualquier disputa relacionada con esta política se resolverá en los tribunales competentes de México.

---

## 14. Consentimiento

Al utilizar Bici Taxi, aceptas los términos de esta Política de Privacidad. Si no estás de acuerdo con alguno de los términos, por favor no utilices nuestras aplicaciones.

---

**Bici Taxi** - Transporte ecológico al alcance de un toque 🚲

*Esta política aplica tanto a la aplicación Bici Taxi (pasajeros) como a Bici Taxi Conductor (conductores).*
