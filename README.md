# Vespa Player Site

Site institucional estático do Vespa Player.

## Sincronizar downloads

A pasta `C:\Users\FRONTIERS-1\Documents\Thadeu\Brazuca_Player free\downloads`
é a fonte dos arquivos publicados em `dist/downloads`. Para espelhá-la e preparar
as alterações para commit, execute no PowerShell, a partir da raiz do repositório:

```powershell
.\scripts\Sync-Downloads.ps1 -Stage
```

O comando remove do site os arquivos que não existem mais na origem e configura o
Git LFS automaticamente para cada arquivo acima de 100 MB. Para conferir as
alterações sem copiar ou remover arquivos, use `-WhatIf`.

## Publicação

O site é publicado pelo GitHub Pages. O workflow em
`.github/workflows/deploy-pages.yml` envia a pasta `dist/` sempre que há um
push na branch `main`.

No repositório do GitHub, habilite **Settings → Pages → Build and deployment →
GitHub Actions** uma única vez. Depois disso, o endereço será:

`https://thadeuj.github.io/Vespa_Player_Site/`
