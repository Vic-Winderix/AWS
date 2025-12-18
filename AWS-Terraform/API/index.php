<?php
include("connect.php");
$bucketName = 'terraform-vicwin-uploads';
$region = 'eu-west-1'; // bv. us-east-1

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['file'])) {

    $tmpFile = $_FILES['file']['tmp_name'];
    $fileName = basename($_FILES['file']['name']);
    $description = $_POST['description'] ?? '';

    // Upload naar S3
    $cmd = escapeshellcmd(
        "$awsPath s3 cp " . escapeshellarg($tmpFile) .
        " s3://$bucketName/" . escapeshellarg($fileName) .
        " --region $region"
    );

    exec($cmd . " 2>&1", $output, $return_var);

    if ($return_var === 0) {

        // Opslaan in database
        $stmt = $pdo->prepare(
            "INSERT INTO files (filename, description) VALUES (:filename, :description)"
        );

        $stmt->execute([
            ':filename' => $fileName,
            ':description' => $description
        ]);

        echo "<p><strong>Bestand succesvol geüpload!</strong></p>";
        echo "<p>Bestand: " . htmlspecialchars($fileName) . "</p>";
        echo "<p>Omschrijving: " . htmlspecialchars($description) . "</p>";

    } else {
        echo "<p><strong>Fout bij uploaden.</strong></p>";
        echo "<pre>" . implode("\n", $output) . "</pre>";
    }

} else {
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
                <textarea name="description" rows="4" cols="50" placeholder="Omschrijving van het bestand"></textarea>
            </p>

            <button type="submit">Upload</button>
        </form>
    </body>
    </html>';
}
?>