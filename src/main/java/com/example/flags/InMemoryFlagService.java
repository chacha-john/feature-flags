package com.example.flags;

import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * In-memory store used when no profile is active (IDE runs, unit tests).
 * Flags are lost on restart.
 */
@Service
@Profile("!postgres")
public class InMemoryFlagService implements FlagService {

    private final ConcurrentMap<String, Flag> flags = new ConcurrentHashMap<>();

    public InMemoryFlagService() {
        upsert("dark-mode", false, "Dark theme for the web UI");
        upsert("new-checkout", true, "Redesigned checkout flow");
    }

    @Override
    public List<Flag> findAll() {
        return flags.values().stream()
                .sorted(Comparator.comparing(Flag::name))
                .toList();
    }

    @Override
    public Optional<Flag> find(String name) {
        return Optional.ofNullable(flags.get(name));
    }

    @Override
    public UpsertResult upsert(String name, boolean enabled, String description) {
        AtomicBoolean created = new AtomicBoolean(false);
        Flag saved = flags.compute(name, (key, existing) -> {
            created.set(existing == null);
            String text = description != null
                    ? description
                    : (existing != null ? existing.description() : "");
            return new Flag(key, enabled, text, Instant.now());
        });
        return new UpsertResult(saved, created.get());
    }
}
