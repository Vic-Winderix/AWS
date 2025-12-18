<?php
$bucketName = 'terraform-vicwin-uploads';
$region = 'eu-west-1'; // bv. us-east-1

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['file'])) {
    $tmpFile = $_FILES['file']['tmp_name'];
    $fileName = basename($_FILES['file']['name']);

    // Upload naar S3 via AWS CLI
    $cmd = escapeshellcmd("aws s3 cp " . escapeshellarg($tmpFile) . " s3://$bucketName/$fileName --region $region");
    exec($cmd, $output, $return_var);

    if ($return_var === 0) {
        echo "Bestand succesvol geüpload: $fileName";
    } else {
        echo "Fout bij uploaden.";
        echo "<pre>" . implode("\n", $output) . "</pre>";
    }
} else {
    // Simpel HTML uploadformulier
    echo '<!DOCTYPE html>
    <html>
    <body>
    <H1>Upload je file hier</H1>
        <form method="post" enctype="multipart/form-data">
            <input type="file" name="file" required>
            <button type="submit">Upload</button>
        </form>
    </body>
    </html>';
}
?>