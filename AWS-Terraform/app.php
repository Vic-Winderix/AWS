<?php
$bucketName = 'terraform-vicwin-uploads';
$region = 'eu-west-1';

// Download script: als er een 'file' parameter is, download het bestand
if (isset($_GET['file'])) {
    $fileName = $_GET['file'];
    $tmpFile = tempnam(sys_get_temp_dir(), 's3_');

    // Download het bestand tijdelijk
    $cmd = escapeshellcmd("aws s3 cp s3://$bucketName/$fileName $tmpFile --region $region");
    exec($cmd, $output, $return_var);

    if ($return_var === 0) {
        header('Content-Description: File Transfer');
        header('Content-Type: application/octet-stream');
        header('Content-Disposition: attachment; filename="' . basename($fileName) . '"');
        header('Expires: 0');
        header('Cache-Control: must-revalidate');
        header('Pragma: public');
        header('Content-Length: ' . filesize($tmpFile));
        readfile($tmpFile);
        unlink($tmpFile);
        exit;
    } else {
        echo "Fout bij downloaden.";
        echo "<pre>" . implode("\n", $output) . "</pre>";
        exit;
    }
}

// Anders: lijst van bestanden tonen
$cmd = escapeshellcmd("aws s3 ls s3://$bucketName --region $region");
exec($cmd, $output, $return_var);

echo '<!DOCTYPE html><html><body>';
echo '<h1>Bestanden in S3 bucket</h1>';

if ($return_var === 0 && !empty($output)) {
    echo '<ul>';
    foreach ($output as $line) {
        // De regel van aws s3 ls heeft format: YYYY-MM-DD HH:MM:SS    SIZE FILENAME
        $parts = preg_split('/\s+/', $line, 4);
        if (isset($parts[3])) {
            $fileName = $parts[3];
            echo '<li><a href="?file=' . urlencode($fileName) . '">' . htmlspecialchars($fileName) . '</a></li>';
        }
    }
    echo '</ul>';
} else {
    echo '<p>Geen bestanden gevonden of fout bij ophalen.</p>';
}

echo '</body></html>';
?>
