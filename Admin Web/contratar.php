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
    <img src="logo_sin_texto.png" class="logo">
    </div>
    <div class="formulario">
    <form action="procesar_contratacion.php" method="post">
    <h2 class="titulo_contrata">Formulario de Contratación</h2>
    <label for="nombre" class="label_contrata">Nombre Completo:</label>
    <input type="text" id="nombre" name="nombre" class="input_contrata"><br><br>
    <label for="email" class="label_contrata">Correo Electrónico:</label>
    <input type="email" id="email" name="email" class="input_contrata"><br><br>
    <label for="empresa" class="label_contrata">Empresa:</label>
    <input type="text" id="empresa" name="empresa" class="input_contrata"><br><br>
    <label for="pago" class="label_contrata">Método de pago:</label>  
    <select id="pago" name="pago" required>
        <option value="alojamiento">Trajeta de débito/crédito</option>
        <option value="optimizacion">PayPal</option>
        <option value="seguridad">Transferencia bancaria</option>
    </select><br><br>
    <label for="mensaje" class="label_contrata">Mensaje Adicional:</label><br>
    <textarea id="mensaje" name="mensaje" class="textarea_contrata" rows="4" cols="50" placeholder="Detalla lo que necesites:"></textarea><br><br>
    <input type="submit" value="Enviar Solicitud" class="boton_contrata">   
    </form>
    </div>
    </body>
<footer class="pie">
    <p>© 2026 EDID Solutions. Todos los derechos reservados.</p>
</footer>
<?php
?>