// Thrown when a duplicate resource is detected (409).
package com.smartpark.exception;

public class DuplicateResourceException extends RuntimeException {

    public DuplicateResourceException(String message) {
        super(message);
    }
}