<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Database connectie (1x)
include("connect.php");

// =======================
// CONFIG
// =======================
$bucketName = 'terraform-vicwin-uploads';
$region = 'eu-west-1';

// =======================
// FORM VERWERKING
// =======================
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['file'])) {

    $tmpFile = $_FILES['file']['tmp_name'];
    $fileName = basename($_FILES['file']['name']);
    $description = $_POST['description'] ?? '';

    // Upload naar S3
    $cmd = escapeshellcmd(
        "aws s3 cp " . escapeshellarg($tmpFile) .
        " s3://$bucketName/" . escapeshellarg($fileName) .
        " --region $region"
    );

    exec($cmd . " 2>&1", $output, $return_var);

    if ($return_var === 0) {

        // Prepared statement (mysqli)
        $stmt = $conn->prepare(
            "INSERT INTO files (filename, description) VALUES (?, ?)"
        );

        if (!$stmt) {
            die("Prepare failed: " . $conn->error);
        }

        $stmt->bind_param("ss", $fileName, $description);
        $stmt->execute();
        $stmt->close();

        echo "<p><strong>Bestand succesvol geüpload!</strong></p>";
        echo "<p>Bestand: " . htmlspecialchars($fileName) . "</p>";
        echo "<p>Omschrijving: " . htmlspecialchars($description) . "</p>";

    } else {
        echo "<p><strong>Fout bij uploaden.</strong></p>";
        echo "<pre>" . implode("\n", $output) . "</pre>";
    }

} else {
    // =======================
    // HTML FORMULIER
    // =======================
    echo '<!DOCTYPE html>
    <html>
    <body>
        <h1>Upload je file</h1>

        <form method="post" enctype="multipart/form-data">
            <p>
                <input type="file" name="file" required>
            </p>

            <p>
                <label>Beschrijving:</label><br>
                <textarea name="description" rows="4" cols="50"></textarea>
            </p>

            <button type="submit">Upload</button>
        </form>
    </body>
    </html>';
}
?>
