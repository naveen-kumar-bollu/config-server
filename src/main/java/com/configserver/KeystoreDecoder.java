package com.configserver;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.env.EnvironmentPostProcessor;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.stereotype.Component;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Base64;

/**
 * Decodes Base64-encoded keystore before Spring Boot initialization.
 * This runs as an EnvironmentPostProcessor to ensure the keystore is available
 * before Spring Cloud Config tries to initialize encryption.
 */
@Component
public class KeystoreDecoder implements EnvironmentPostProcessor {

    @Override
    public void postProcessEnvironment(ConfigurableEnvironment environment, SpringApplication application) {
        String keystoreBase64 = environment.getProperty("KEYSTORE_BASE64", "");
        String keystoreTempPath = environment.getProperty("KEYSTORE_TEMP_PATH", "/tmp/server.jks");

        if (keystoreBase64 != null && !keystoreBase64.trim().isEmpty()) {
            try {
                System.out.println("Decoding keystore from KEYSTORE_BASE64 environment variable...");
                
                // Decode Base64 to bytes
                byte[] keystoreBytes = Base64.getDecoder().decode(keystoreBase64.trim());

                // Ensure temp directory exists
                Path tempPath = Paths.get(keystoreTempPath);
                if (tempPath.getParent() != null) {
                    Files.createDirectories(tempPath.getParent());
                }

                // Write to temp file
                try (FileOutputStream fos = new FileOutputStream(keystoreTempPath)) {
                    fos.write(keystoreBytes);
                }

                System.out.println("✓ Keystore successfully decoded and written to: " + keystoreTempPath);
                
                // Update the environment to point to the decoded keystore
                System.setProperty("encrypt.key-store.location", "file:" + keystoreTempPath);
                
            } catch (IllegalArgumentException e) {
                System.err.println("ERROR: Invalid Base64 encoding in KEYSTORE_BASE64");
                throw new RuntimeException("Failed to decode keystore: Invalid Base64 encoding", e);
            } catch (IOException e) {
                System.err.println("ERROR: Failed to write keystore to " + keystoreTempPath);
                throw new RuntimeException("Failed to write keystore file", e);
            }
        } else {
            System.out.println("ℹ No KEYSTORE_BASE64 provided. Encryption will be disabled or use default keystore.");
        }
    }
}