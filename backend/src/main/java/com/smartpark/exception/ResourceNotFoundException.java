// Thrown when a requested resource does not exist (404).
package com.smartpark.exception;

public class ResourceNotFoundException extends RuntimeException {

    public ResourceNotFoundException(String message) {
        super(message);
    }
}