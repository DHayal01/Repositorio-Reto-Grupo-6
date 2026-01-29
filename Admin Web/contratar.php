<html>
    <head>
    <meta charset="UTF-8">
    </head>
    <link rel="stylesheet" href="web.css">
    <body>
    <div class="cabecera">
    <h1 class="arriba">EDID Solutions</h1>
    <a href="index.html">
    <button type="button" class="inicio">Inicio</button>
    </a>
    <a href="contratar.php">
    <button type="button" class="contrata">Contrátanos</button>
    </a>
    <a href="quienes_somos.html">
    <button type="button" class="quienes_somos">Quiénes somos</button>
    </a>
    <a href="soporte.html">
    <button type="button" class="soporte">Soporte</button>
    </a>
    <img src="imagenes/logo_sin_texto.png" class="logo">
    </div>
    <div class="formulario">
    <form action="" method="post" class="formulario1">
    <h2 class="titulo_contrata">Formulario de Contratación</h2>
    <p class="p">Agenda tu cita para poder contratar nuestros servicios.</p>
    <label for="nombre" class="label_contrata">Nombre Completo:</label>
    <input type="text" id="nombre" name="nombre"><br><br>
    <label for="email" class="label_contrata">Correo Electrónico:</label>
    <input type="email" id="email" name="email"><br><br>
    <label for="empresa" class="label_contrata">Empresa:</label>
    <input type="text" id="empresa" name="empresa"><br><br>
    <label for="fecha_hora" class="label_contrata">Fecha y hora:</label>
    <input type="datetime-local" id="fecha_hora" name="fecha_hora" class="input_contrata"><br><br>
    <label for="mensaje" class="label_contrata">Mensaje Adicional:</label><br>
    <textarea id="mensaje" name="mensaje" rows="4" cols="50" placeholder="Detalla lo que necesites:"></textarea>
    <input type="submit" value="Enviar Solicitud" class="boton_contrata">   
    </form>
    </div>
    </body>
<footer class="pie">
    <p>© 2026 EDID Solutions. Todos los derechos reservados.</p>
</footer>
<?php
?>