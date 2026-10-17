<?php
/**
 * importar-bd.php
 * Importa un respaldo .sql (mysqldump) en la base MySQL de Clever Cloud.
 * Alternativa a phpMyAdmin cuando el cliente mysql de XAMPP no puede
 * autenticarse contra MySQL 8.4.
 *
 * Uso con el PHP de XAMPP:
 *   C:\xampp\php\php.exe deploy\importar-bd.php HOST PUERTO USUARIO PASSWORD BASE archivo.sql
 *
 * Conexion: primero normal; si el servidor exige TLS (error 3159),
 * reintenta con SSL.
 */
if ($argc < 7) {
    fwrite(STDERR, "Uso: php importar-bd.php HOST PUERTO USUARIO PASSWORD BASE archivo.sql\n");
    exit(1);
}
$host    = $argv[1];
$port    = (int) $argv[2];
$user    = $argv[3];
$pass    = $argv[4];
$base    = $argv[5];
$archivo = $argv[6];

if (!is_file($archivo)) {
    fwrite(STDERR, "ERROR: no existe el archivo: {$archivo}\n");
    exit(1);
}
$sql = file_get_contents($archivo);
if ($sql === false || trim($sql) === '') {
    fwrite(STDERR, "ERROR: no se pudo leer el archivo\n");
    exit(1);
}

function conectarBd($host, $port, $user, $pass, $base, $flags)
{
    $m = mysqli_init();
    if (!$m->real_connect($host, $user, $pass, $base, $port, null, $flags)) {
        return array(null, $m->connect_errno, $m->connect_error);
    }
    return array($m, 0, '');
}

list($con, $errno, $error) = conectarBd($host, $port, $user, $pass, $base, 0);
if ($con === null) {
    echo "La conexion normal fallo (codigo {$errno}); reintentando con SSL/TLS...\n";
    list($con2, $errno2, $error2) = conectarBd($host, $port, $user, $pass, $base, MYSQLI_CLIENT_SSL);
    if ($con2 !== null) {
        $con = $con2;
    } else {
        fwrite(STDERR, "ERROR al conectar.\n  Intento normal: [{$errno}] {$error}\n  Intento SSL:    [{$errno2}] {$error2}\n");
        exit(1);
    }
}

$con->set_charset('utf8mb4');
echo "Conectado a {$host}:{$port}/{$base}. Importando...\n";

if (!$con->multi_query($sql)) {
    fwrite(STDERR, "ERROR: {$con->error}\n");
    exit(1);
}

$n = 0;
do {
    if ($res = $con->store_result()) {
        $res->free();
    }
    $n++;
    if (!$con->more_results()) {
        break;
    }
    if (!$con->next_result()) {
        fwrite(STDERR, "ERROR tras {$n} resultados: {$con->error}\n");
        exit(1);
    }
} while (true);

echo "OK: {$n} resultados procesados. Importacion terminada.\n";
