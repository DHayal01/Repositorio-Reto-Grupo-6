<html>
    <head>
    <meta charset="UTF-8">
    </head>
    <link rel="stylesheet" href="web.css">
    <body>
    <div class="cabecera">
    <h1 class="arriba">Bienvenido a EDID Solutions</h1>
    <a href="index.html">
    <button type="button" class="inicio">Inicio</button>
    </a>
    <a href="contratar.php">
    <button type="button" class="contrata">Contrátanos</button>
    </a>
    <a href="quienes_somos.html">
    <button type="button" class="quienes_somos">Quiénes somos</button>
    </a>
    <img src="logo_sin_texto.png" class="logo">
    </div>
    <div class="formulario">
    <form action="procesar_contratacion.php" method="post">
    <h2 class="titulo_contrata">Formulario de Contratación</h2>
    <label for="nombre" class="label_contrata">Nombre Completo:</label>
    <input type="text" id="nombre" name="nombre" class="input_contrata" required><br><br>
    <label for="email" class="label_contrata">Correo Electrónico:</label>
    <input type="email" id="email" name="email" class="input_contrata" required><br><br>
    <label for="pago" class="label_contrata">Método de pago:</label>  
    <select id="pago" name="pago" required>
        <option value="alojamiento">Trajeta de débito/crédito</option>
        <option value="optimizacion">PayPal</option>
        <option value="seguridad">Transferencia bancaria</option>
    </select><br><br>
    <label for="mensaje" class="label_contrata">Mensaje Adicional:</label><br>
    <textarea id="mensaje" name="mensaje" class="textarea_contrata" rows="4" cols="50"></textarea><br><br>
    <input type="submit" value="Enviar Solicitud" class="boton_contrata">   
    </form>
    </div>
    </body>
</html>
<?php
?>