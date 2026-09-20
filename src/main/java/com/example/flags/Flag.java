package com.example.flags;

import java.time.Instant;

/** A single feature flag. */
public record Flag(String name, boolean enabled, String description, Instant updatedAt) {
}
