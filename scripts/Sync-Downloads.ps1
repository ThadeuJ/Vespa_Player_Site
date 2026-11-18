[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$SourcePath = 'C:\Users\FRONTIERS-1\Documents\Thadeu\Brazuca_Player free\downloads',
    [switch]$Stage,
    [long]$LargeFileLimitBytes = 100MB
)

$ErrorActionPreference = 'Stop'

$repositoryPath = Split-Path -Parent $PSScriptRoot
$destinationPath = Join-Path $repositoryPath 'dist\downloads'

if (-not (Test-Path -LiteralPath $SourcePath -PathType Container)) {
    throw "A pasta de origem não foi encontrada: $SourcePath"
}

if (-not (Test-Path -LiteralPath (Join-Path $repositoryPath '.git') -PathType Container)) {
    throw "O repositório Git não foi encontrado em: $repositoryPath"
}

$sourceFiles = @(Get-ChildItem -LiteralPath $SourcePath -File)
$sourceNames = @($sourceFiles.Name)

if ($PSCmdlet.ShouldProcess($destinationPath, 'Criar a pasta de downloads')) {
    New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
}

foreach ($sourceFile in $sourceFiles) {
    $destinationFile = Join-Path $destinationPath $sourceFile.Name
    $needsCopy = -not (Test-Path -LiteralPath $destinationFile -PathType Leaf)

    if (-not $needsCopy) {
        $destinationInfo = Get-Item -LiteralPath $destinationFile
        $needsCopy = $sourceFile.Length -ne $destinationInfo.Length

        if (-not $needsCopy) {
            $needsCopy = (Get-FileHash -LiteralPath $sourceFile.FullName -Algorithm SHA256).Hash -ne
                (Get-FileHash -LiteralPath $destinationFile -Algorithm SHA256).Hash
        }
    }

    if ($needsCopy -and $PSCmdlet.ShouldProcess($destinationFile, "Copiar $($sourceFile.Name)")) {
        Copy-Item -LiteralPath $sourceFile.FullName -Destination $destinationFile -Force
    }
}

foreach ($destinationFile in Get-ChildItem -LiteralPath $destinationPath -File) {
    if ($destinationFile.Name -notin $sourceNames -and $PSCmdlet.ShouldProcess($destinationFile.FullName, 'Remover arquivo que não existe na origem')) {
        Remove-Item -LiteralPath $destinationFile.FullName -Force
    }
}

Push-Location $repositoryPath
try {
    & git lfs install | Out-Host

    foreach ($sourceFile in $sourceFiles | Where-Object Length -gt $LargeFileLimitBytes) {
        $relativePath = "dist/downloads/$($sourceFile.Name)"
        $attribute = & git check-attr filter -- $relativePath

        if ($attribute -notmatch 'filter: lfs' -and $PSCmdlet.ShouldProcess($relativePath, 'Adicionar ao Git LFS')) {
            & git lfs track -- $relativePath | Out-Host
        }
    }

    if ($Stage -and $PSCmdlet.ShouldProcess('downloads e .gitattributes', 'Adicionar alterações ao Git')) {
        & git add -A -- .gitattributes dist/downloads
    }
}
finally {
    Pop-Location
}

Write-Host "Sincronização concluída. Origem: $SourcePath"
Write-Host "Destino: $destinationPath"

if (-not $Stage) {
    Write-Host 'Para preparar o commit, execute novamente com -Stage ou use: git add -A -- .gitattributes dist/downloads'
}
