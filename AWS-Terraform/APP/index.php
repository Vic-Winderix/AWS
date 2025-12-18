<?php
include("connect.php"); // je mysqli connectie
$bucketName = 'terraform-vicwin-uploads';
$region = 'eu-west-1';

// ========================
// Download script
// ========================
if (isset($_GET['file'])) {
    $fileName = $_GET['file'];
    $tmpFile = tempnam(sys_get_temp_dir(), 's3_');

    // Download het bestand tijdelijk van S3
    $cmd = escapeshellcmd("aws s3 cp s3://$bucketName/" . escapeshellarg($fileName) . " " . escapeshellarg($tmpFile) . " --region $region");

    exec($cmd . " 2>&1", $output, $return_var);

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
        echo "Fout bij downloaden van S3.";
        echo "<pre>" . implode("\n", $output) . "</pre>";
        exit;
    }
}

// ========================
// Lijst van bestanden tonen
// ========================
$result = $conn->query("SELECT filename, description FROM bestanden ORDER BY created_at DESC");

echo '<!DOCTYPE html>
<html>
<head>
    <title>Bestanden overzicht</title>
    <style>
        table { border-collapse: collapse; width: 80%; }
        th, td { border: 1px solid #ccc; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        a.button { text-decoration: none; padding: 5px 10px; background-color: #4CAF50; color: white; border-radius: 4px; }
    </style>
</head>
<body>
<h1>Bestanden in de database</h1>';

if ($result && $result->num_rows > 0) {
    echo '<table>
        <tr>
            <th>Bestandsnaam</th>
            <th>Omschrijving</th>
            <th>Download</th>
        </tr>';
    
    while ($row = $result->fetch_assoc()) {
        $file = htmlspecialchars($row['filename']);
        $desc = htmlspecialchars($row['description']);
        echo '<tr>
            <td>' . $file . '</td>
            <td>' . $desc . '</td>
            <td><a class="button" href="?file=' . urlencode($row['filename']) . '">Download</a></td>
        </tr>';
    }

    echo '</table>';
} else {
    echo '<p>Geen bestanden gevonden in de database.</p>';
}

echo '</body></html>';
?>
