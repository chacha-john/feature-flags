package com.example.flags;

import org.springframework.context.annotation.Profile;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

/** PostgreSQL-backed store, active with the "postgres" profile. */
@Service
@Profile("postgres")
public class JdbcFlagService implements FlagService {

    private static final RowMapper<Flag> FLAG_MAPPER = (rs, rowNum) -> new Flag(
            rs.getString("name"),
            rs.getBoolean("enabled"),
            rs.getString("description"),
            rs.getTimestamp("updated_at").toInstant());

    private final JdbcClient jdbc;

    public JdbcFlagService(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public List<Flag> findAll() {
        return jdbc.sql("SELECT name, enabled, description, updated_at FROM flags ORDER BY name")
                .query(FLAG_MAPPER)
                .list();
    }

    @Override
    public Optional<Flag> find(String name) {
        return jdbc.sql("SELECT name, enabled, description, updated_at FROM flags WHERE name = :name")
                .param("name", name)
                .query(FLAG_MAPPER)
                .optional();
    }

    @Override
    public UpsertResult upsert(String name, boolean enabled, String description) {
        // Single atomic statement. "xmax = 0" is true only for a freshly inserted row,
        // which is how we tell "created" (201) from "updated" (200).
        // CAST (not ::) because ':' is the named-parameter marker.
        return jdbc.sql("""
                        INSERT INTO flags (name, enabled, description, updated_at)
                        VALUES (:name, :enabled, COALESCE(CAST(:description AS TEXT), ''), now())
                        ON CONFLICT (name) DO UPDATE
                           SET enabled     = EXCLUDED.enabled,
                               description = COALESCE(CAST(:description AS TEXT), flags.description),
                               updated_at  = now()
                        RETURNING name, enabled, description, updated_at, (xmax = 0) AS created
                        """)
                .param("name", name)
                .param("enabled", enabled)
                .param("description", description)
                .query((rs, rowNum) -> new UpsertResult(FLAG_MAPPER.mapRow(rs, rowNum), rs.getBoolean("created")))
                .single();
    }
}
