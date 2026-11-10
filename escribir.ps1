# Escribe letras al azar y las borra, una y otra vez.
#   Q = empezar a escribir
#   Z = detener
#   Cerrar esta ventana = salir del programa
#
# IMPORTANTE: escribe en la ventana que este activa (donde este el cursor).
# Abre un Bloc de notas y deja el cursor ahi antes de presionar Q.

Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class Teclado {
    [StructLayout(LayoutKind.Sequential)]
    struct KEYBDINPUT { public ushort wVk; public ushort wScan; public uint dwFlags; public uint time; public IntPtr dwExtraInfo; }

    [StructLayout(LayoutKind.Sequential)]
    struct INPUT { public uint type; public KEYBDINPUT ki; public long pad; }

    [DllImport("user32.dll", SetLastError = true)]
    static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);

    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);

    const uint INPUT_KEYBOARD   = 1;
    const uint KEYEVENTF_KEYUP  = 0x0002;
    const uint KEYEVENTF_UNICODE = 0x0004;
    const ushort VK_BACK = 0x08;

    static void Send(INPUT[] inp) {
        SendInput((uint)inp.Length, inp, Marshal.SizeOf(typeof(INPUT)));
    }

    public static void Letra(char c) {
        INPUT[] inp = new INPUT[2];
        inp[0].type = INPUT_KEYBOARD; inp[0].ki.wScan = c; inp[0].ki.dwFlags = KEYEVENTF_UNICODE;
        inp[1].type = INPUT_KEYBOARD; inp[1].ki.wScan = c; inp[1].ki.dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP;
        Send(inp);
    }

    public static void Borrar() {
        INPUT[] inp = new INPUT[2];
        inp[0].type = INPUT_KEYBOARD; inp[0].ki.wVk = VK_BACK;
        inp[1].type = INPUT_KEYBOARD; inp[1].ki.wVk = VK_BACK; inp[1].ki.dwFlags = KEYEVENTF_KEYUP;
        Send(inp);
    }

    public static bool Presionada(int vKey) {
        return (GetAsyncKeyState(vKey) & 0x8000) != 0;
    }
}
"@

$VK_Q = 0x51
$VK_Z = 0x5A

# Letras que puede escribir (sin q ni z para que no se active/detenga solo)
$letras = "abcdefghijklmnoprstuvwxy".ToCharArray()

$escribiendo = $false
$rnd = New-Object System.Random

function Revisar-Teclas {
    if (-not $script:escribiendo -and [Teclado]::Presionada($VK_Q)) {
        $script:escribiendo = $true
        Write-Host "$(Get-Date -Format HH:mm:ss)  ESCRIBIENDO (Q)" -ForegroundColor Green
        Start-Sleep -Milliseconds 300
        [Teclado]::Borrar()   # borra la "q" que tu escribiste
    }
    elseif ($script:escribiendo -and [Teclado]::Presionada($VK_Z)) {
        $script:escribiendo = $false
        Write-Host "$(Get-Date -Format HH:mm:ss)  DETENIDO (Z)" -ForegroundColor Yellow
        Start-Sleep -Milliseconds 300
        [Teclado]::Borrar()   # borra la "z" que tu escribiste
    }
}

# Espera ms milisegundos revisando las teclas; devuelve $false si se detuvo
function Esperar($ms) {
    $fin = (Get-Date).AddMilliseconds($ms)
    while ((Get-Date) -lt $fin) {
        Revisar-Teclas
        if (-not $script:escribiendo) { return $false }
        Start-Sleep -Milliseconds 20
    }
    return $true
}

Write-Host "Listo. Pon el cursor en un Bloc de notas." -ForegroundColor Cyan
Write-Host "Q = empezar a escribir y borrar   |   Z = detener" -ForegroundColor Cyan
Write-Host "Cierra esta ventana para salir." -ForegroundColor DarkGray

while ($true) {
    Revisar-Teclas

    if ($escribiendo) {
        # Escribe una "palabra" al azar de 3 a 10 letras
        $largo = $rnd.Next(3, 11)
        $escritas = 0
        for ($i = 0; $i -lt $largo; $i++) {
            [Teclado]::Letra($letras[$rnd.Next($letras.Length)])
            $escritas++
            if (-not (Esperar ($rnd.Next(80, 250)))) { break }
        }

        # Pausa corta y luego borra lo que escribio
        Esperar ($rnd.Next(400, 1200)) | Out-Null
        for ($i = 0; $i -lt $escritas; $i++) {
            [Teclado]::Borrar()
            Start-Sleep -Milliseconds ($rnd.Next(50, 150))
        }

        # Pausa antes de la siguiente palabra
        Esperar ($rnd.Next(1000, 3000)) | Out-Null
    }
    else {
        Start-Sleep -Milliseconds 50
    }
}
