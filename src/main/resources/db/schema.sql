CREATE TABLE IF NOT EXISTS flags (
    name        VARCHAR(64)  PRIMARY KEY,
    enabled     BOOLEAN      NOT NULL,
    description TEXT         NOT NULL DEFAULT '',
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

INSERT INTO flags (name, enabled, description) VALUES
    ('dark-mode', FALSE, 'Dark theme for the web UI'),
    ('new-checkout', TRUE, 'Redesigned checkout flow')
ON CONFLICT (name) DO NOTHING;
