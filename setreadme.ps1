$TESTING = $false

$book = [System.IO.File]::ReadAllBytes("C:\Users\MavaddatJavid\Calibre Portable\Calibre Library\Eric Matthes\Python Crash Course_ A Hands-On, Pr (112)\Python Crash Course_ A Hands-On - Eric Matthes.epub")
[System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression')
$zipStream = New-Object System.IO.Memorystream
$zipStream.Write($book,0,$book.Count) | Out-Null
$zipFile = [System.IO.Compression.ZipArchive]::new($zipStream)
$htmlFiles = $zipFile.Entries | Where-Object -Property FullName -Match "ch\d+\.html"
foreach($htmlFile in $htmlFiles){
    $chapter  = $zipFile.GetEntry($htmlFile)
    $chapter.Open().Read(($chContentBytes = [byte[]]::new($chapter.Length)),0,$($chapter.Length)) | Out-Null
    $chContentStr = [System.Text.Encoding]::Default.GetString($chContentBytes)
    $HTML = New-Object -Com "HTMLFile"
    $HTML.write([ref]$chContentStr) | Out-Null
    $chNum = (Select-String -InputObject $htmlFile.Name -Pattern "(\d+)").Matches.Value
    $README_md = "chapter_$chNum\README.md"
    $TryItYourselfs = $HTML.getElementsByClassName('sidebar')
    $i = 0
    foreach($TryItYourself in $TryItYourselfs){
        $i++
        $outStr = Out-String -InputObject (("<BR/>" + (Out-String -InputObject $TryItYourself.innerHTML) -creplace '<STRONG>TRY IT YOURSELF</STRONG>',"<H2>TRY IT YOURSELF &#35;$i</H2>" -replace '<([^>\s]+)\s*class="programs">([\s\S]+?)<\/\1>','<pre class="python"><code>$2</code></pre>' -replace '<span\s*class="?literal"?>([\s\S]+?)</span>','<code>$1</code>'| pandoc @("--from=HTML", "--to=markdown_mmd+backtick_code_blocks+fenced_code_blocks+autolink_bare_uris")) -replace 'ch(\d+)\.html','../chapter_$1/README.md')

        if($TESTING){
            Out-Host -InputObject $outStr
            pause
        } else{
            Out-File -InputObject $outStr -FilePath  $README_md -Append -Encoding utf8
        }
    }
}