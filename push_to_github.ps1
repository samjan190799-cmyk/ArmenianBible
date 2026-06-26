param(
    [Parameter(Mandatory=$true)]
    [string]$Token
)

$owner = "samjan190799-cmyk"
$repo = "ArmenianBible"
$branch = "main"

# 1. Создание репозитория на GitHub через API (если не существует)
$headers = @{
    Authorization = "Bearer $Token"
    Accept = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
    "Content-Type" = "application/json"
}

$apiUrl = "https://api.github.com/user/repos"
$body = @{
    name = $repo
    private = $false
    description = "Armenian Bible LockScreen app and widget for AltStore"
} | ConvertTo-Json

Write-Host "Создание репозитория на GitHub..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Post -Body $body -ErrorAction Stop
    Write-Host "✅ Репозиторий успешно создан на GitHub!" -ForegroundColor Green
} catch {
    # Обработка ошибки, если репозиторий уже создан
    if ($_.Exception.Response -and $_.Exception.Response.StatusCode -eq "Conflict") {
        Write-Host "ℹ️ Репозиторий уже существует на GitHub." -ForegroundColor Yellow
    } else {
        Write-Host "❌ Предупреждение/ошибка при создании репозитория: $_" -ForegroundColor Yellow
    }
}

# 2. Настройка remote с авторизацией по токену и отправка кода
Write-Host "Настройка Git remote и отправка коммита..." -ForegroundColor Cyan

# Проверяем и удаляем старый remote origin, если есть
$existingRemote = git remote get-url origin 2>$null
if ($existingRemote) {
    git remote remove origin
}

# Формируем URL с токеном для беспарольной авторизации при push
$remoteUrl = "https://$owner`:$Token@github.com/$owner/$repo.git"
git remote add origin $remoteUrl

Write-Host "Выполнение git push..." -ForegroundColor Cyan
git push -u origin main --force

# Сбрасываем URL remote на безопасный (без токена в открытом виде)
git remote set-url origin "https://github.com/$owner/$repo.git"

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Все файлы проекта отправлены на GitHub!" -ForegroundColor Green
Write-Host "  Сборка IPA начнется автоматически через GitHub Actions:" -ForegroundColor Green
Write-Host "  https://github.com/$owner/$repo/actions" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
