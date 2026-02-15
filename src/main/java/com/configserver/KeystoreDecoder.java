package com.configserver;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import jakarta.annotation.PostConstruct;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Base64;

@Component
public class KeystoreDecoder {

    @Value("${KEYSTORE_BASE64:}")
    private String keystoreBase64;

    @Value("${KEYSTORE_TEMP_PATH:/tmp/server.jks}")
    private String keystoreTempPath;

    @PostConstruct
    public void decodeKeystore() {
        if (keystoreBase64 != null && !keystoreBase64.isEmpty()) {
            try {
                // Decode Base64 to bytes
                byte[] keystoreBytes = Base64.getDecoder().decode(keystoreBase64);

                // Ensure temp directory exists
                Path tempPath = Paths.get(keystoreTempPath);
                Files.createDirectories(tempPath.getParent());

                // Write to temp file
                try (FileOutputStream fos = new FileOutputStream(keystoreTempPath)) {
                    fos.write(keystoreBytes);
                }

                System.out.println("Keystore decoded and written to: " + keystoreTempPath);
            } catch (IOException e) {
                throw new RuntimeException("Failed to decode and write keystore", e);
            }
        } else {
            System.out.println("No KEYSTORE_BASE64 provided, using default keystore location");
        }
    }
}