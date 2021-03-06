#Requires -PSEdition Core
$TESTING = $true

$book = [System.IO.File]::ReadAllBytes("*.epub")
[System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression')
$zipStream = New-Object System.IO.Memorystream
$zipStream.Write($book, 0, $book.Count) | Out-Null
$zipFile = [System.IO.Compression.ZipArchive]::new($zipStream)
$htmlFiles = $zipFile.Entries | Where-Object -Property FullName -Match "ch\d+\.html"
foreach ($htmlFile in $htmlFiles) {
    $chapter = $zipFile.GetEntry($htmlFile)
    $chapter.Open().Read(($chContentBytes = [byte[]]::new($chapter.Length)), 0, $($chapter.Length)) | Out-Null
    $chContentStr = [System.Text.Encoding]::Default.GetString($chContentBytes)
    $HTML = New-Object -Com "HTMLFile"
    $HTML.write([ref]$chContentStr) | Out-Null
    $chNum = (Select-String -InputObject $htmlFile.Name -Pattern "(\d+)").Matches.Value
    $README_md = "chapter_$chNum\README.md"
    # $chTitle has XPath //*[@id="ch$chNum"]/strong[2]
    $chTitle = (Get-Culture).TextInfo.ToTitleCase($HTML.getElementById("ch$chNum").getElementsByTagName('strong')[1].innerHTML.ToLowerInvariant())
    $TryItYourselfs = $HTML.getElementsByClassName('sidebar')
    $i = 0
    $outStr = Out-String -InputObject ("<H1>" + $chTitle + "</H1>`n" | pandoc @("--from=HTML", "--to=markdown_mmd+backtick_code_blocks+fenced_code_blocks+autolink_bare_uris"))
    $outStr = @"
---
layout: default
title: $chTitle
---

$outStr

"@

    if ($TESTING) {
        $tempFile = New-TemporaryFile
        Out-File -InputObject $outStr -FilePath  $tempFile -Encoding utf8
        Get-Content $README_md | Out-File -FilePath $tempFile -Append
        Move-Item -Path $tempFile -Destination $README_md -Force
    }
    else {
        Out-File -InputObject $outStr -FilePath  $README_md -Append -Encoding utf8
    }
    foreach ($TryItYourself in $TryItYourselfs) {
        $i++
        $outStr = Out-String -InputObject (("<BR/>" + (Out-String -InputObject $TryItYourself.innerHTML) -creplace '<STRONG>TRY IT YOURSELF</STRONG>', "<H2>TRY IT YOURSELF &#35;$i</H2>" -replace '<([^>\s]+)\s*class="?programs"?>([\s\S]+?)<\/\1>', '<pre class="python"><code>$2</code></pre>' -replace '<span\s*class="?literal"?>([\s\S]+?)</span>', '<code>$1</code>' | pandoc @("--from=HTML", "--to=markdown_mmd+backtick_code_blocks+fenced_code_blocks+autolink_bare_uris")) -replace 'ch(\d+)\.html', '../chapter_$1/README.md')

        if($TESTING){
            Out-Host -InputObject $outStr
            pause
        } else{
            Out-File -InputObject $outStr -FilePath  $README_md -Append -Encoding utf8
        }
    }
}