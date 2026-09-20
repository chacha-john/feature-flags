package com.example.flags;

import java.util.List;
import java.util.Optional;

/**
 * Storage-agnostic flag operations.
 * Implementations: {@link InMemoryFlagService} (default) and
 * {@link JdbcFlagService} (active with the "postgres" profile).
 */
public interface FlagService {

    record UpsertResult(Flag flag, boolean created) {
    }

    List<Flag> findAll();

    Optional<Flag> find(String name);

    /**
     * Creates the flag or replaces its state. If {@code description} is null,
     * the existing description is kept so a plain toggle doesn't wipe it.
     */
    UpsertResult upsert(String name, boolean enabled, String description);
}
