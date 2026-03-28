# Hospedado no GitHub - Ariel Tech
# Para rodar: irm https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPO/main/ativar.ps1 | iex

# =============================================
#              BANNER ARIEL TECH
# =============================================

Clear-Host

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║                                              ║" -ForegroundColor Cyan
Write-Host "  ║           A R I E L   T E C H               ║" -ForegroundColor Green
Write-Host "  ║                                              ║" -ForegroundColor Cyan
Write-Host "  ║      Ferramenta de Ativacao Win / Office     ║" -ForegroundColor White
Write-Host "  ║                                              ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  >> Iniciando Microsoft Activation Scripts..." -ForegroundColor Yellow
Write-Host ""
Start-Sleep -Seconds 2

# =============================================
#         MICROSOFT ACTIVATION SCRIPTS
# =============================================

if (-not $args) {
    Write-Host ''
    Write-Host 'Precisa de ajuda? Acesse: ' -NoNewline
    Write-Host 'https://massgrave.dev' -ForegroundColor Green
    Write-Host ''
}

& {
    $psv = (Get-Host).Version.Major
    $troubleshoot = 'https://massgrave.dev/troubleshoot'

    if ($ExecutionContext.SessionState.LanguageMode.value__ -ne 0) {
        $ExecutionContext.SessionState.LanguageMode
        Write-Host "O PowerShell nao esta sendo executado no Modo de Linguagem Completa."
        Write-Host "Ajuda - https://massgrave.dev/fix_powershell" -ForegroundColor White -BackgroundColor Blue
        return
    }

    try {
        [void][System.AppDomain]::CurrentDomain.GetAssemblies()
        [void][System.Math]::Sqrt(144)
    }
    catch {
        Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "O PowerShell nao conseguiu carregar o comando .NET."
        Write-Host "Ajuda - https://massgrave.dev/in-place_repair_upgrade" -ForegroundColor White -BackgroundColor Blue
        return
    }

    function Check3rdAV {
        $cmd = if ($psv -ge 3) { 'Get-CimInstance' } else { 'Get-WmiObject' }
        $avList = & $cmd -Namespace root\SecurityCenter2 -Class AntiVirusProduct |
            Where-Object { $_.displayName -notlike '*windows*' } |
            Select-Object -ExpandProperty displayName

        if ($avList) {
            Write-Host 'Um antivirus de terceiros pode estar bloqueando o script - ' -ForegroundColor White -BackgroundColor Blue -NoNewline
            Write-Host " $($avList -join ', ')" -ForegroundColor DarkRed -BackgroundColor White
        }
    }

    function CheckFile {
        param ([string]$FilePath)
        if (-not (Test-Path $FilePath)) {
            Check3rdAV
            Write-Host "Falha ao criar o arquivo MAS na pasta temporaria, abortando!"
            Write-Host "Ajuda - $troubleshoot" -ForegroundColor White -BackgroundColor Blue
            throw
        }
    }

    try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

    $URLs = @(
        'https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/4fdefbc0d58befbe824440af39ed424c6386f65f/MAS/All-In-One-Version-KL/MAS_AIO.cmd',
        'https://dev.azure.com/massgrave/Microsoft-Activation-Scripts/_apis/git/repositories/Microsoft-Activation-Scripts/items?path=/MAS/All-In-One-Version-KL/MAS_AIO.cmd&versionType=Commit&version=4fdefbc0d58befbe824440af39ed424c6386f65f',
        'https://git.activated.win/Microsoft-Activation-Scripts/plain/MAS/All-In-One-Version-KL/MAS_AIO.cmd?id=4fdefbc0d58befbe824440af39ed424c6386f65f'
    )

    Write-Progress -Activity "Baixando..." -Status "Aguarde"
    $errors = @()

    foreach ($URL in $URLs | Sort-Object { Get-Random }) {
        try {
            if ($psv -ge 3) {
                $response = Invoke-RestMethod $URL
            }
            else {
                $w = New-Object Net.WebClient
                $response = $w.DownloadString($URL)
            }
            break
        }
        catch {
            $errors += $_
        }
    }

    Write-Progress -Activity "Baixando..." -Status "Concluido" -Completed

    if (-not $response) {
        Check3rdAV
        foreach ($err in $errors) {
            Write-Host "Erro: $($err.Exception.Message)" -ForegroundColor Red
        }
        Write-Host "Falha ao recuperar o MAS de qualquer um dos repositorios disponiveis, abortando!"
        Write-Host "Verifique se o antivirus ou firewall esta bloqueando a conexao."
        Write-Host "Ajuda - $troubleshoot" -ForegroundColor White -BackgroundColor Blue
        return
    }

    # Verificar a integridade do script
    $releaseHash = 'C731BB797994B7185944E8B6075646EBDC2CEF87960B4B2F437306CB4CE28F03'
    $stream = New-Object IO.MemoryStream
    $writer = New-Object IO.StreamWriter $stream
    $writer.Write($response)
    $writer.Flush()
    $stream.Position = 0
    $hash = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($stream)) -replace '-'

    if ($hash -ne $releaseHash) {
        Write-Warning "Incompatibilidade de hash ($hash), abortando!`nReporte este problema em $troubleshoot"
        $response = $null
        return
    }

    # Verificar registro AutoRun que pode causar problemas com CMD
    $paths = "HKCU:\SOFTWARE\Microsoft\Command Processor", "HKLM:\SOFTWARE\Microsoft\Command Processor"
    foreach ($path in $paths) {
        if (Get-ItemProperty -Path $path -Name "Autorun" -ErrorAction SilentlyContinue) {
            Write-Warning "Registro Autorun encontrado, o CMD pode travar!`nCopie e cole manualmente o comando abaixo para corrigir...`nRemove-ItemProperty -Path '$path' -Name 'Autorun'"
        }
    }

    $rand = [Guid]::NewGuid().Guid
    $isAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')
    $FilePath = if ($isAdmin) { "$env:SystemRoot\Temp\MAS_$rand.cmd" } else { "$env:USERPROFILE\AppData\Local\Temp\MAS_$rand.cmd" }

    Set-Content -Path $FilePath -Value "@::: $rand `r`n$response"
    CheckFile $FilePath

    $env:ComSpec = "$env:SystemRoot\system32\cmd.exe"
    $chkcmd = & $env:ComSpec /c "echo CMD esta funcionando"

    if ($chkcmd -notcontains "CMD esta funcionando") {
        Write-Warning "cmd.exe nao esta funcionando. Relate este problema em $troubleshoot"
    }

    if ($psv -lt 3) {
        if (Test-Path "$env:SystemRoot\Sysnative") {
            Write-Warning "O comando esta sendo executado com o PowerShell x86. Execute-o com o PowerShell x64."
            return
        }
        $p = Start-Process -FilePath $env:ComSpec -ArgumentList "/c """"$FilePath"" -el -qedit $args""" -Verb RunAs -PassThru
        $p.WaitForExit()
    }
    else {
        Start-Process -FilePath $env:ComSpec -ArgumentList "/c """"$FilePath"" -el $args""" -Wait -Verb RunAs
    }

    CheckFile $FilePath
    Remove-Item -Path $FilePath

} @args