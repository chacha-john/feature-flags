package com.example.flags;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.regex.Pattern;

@RestController
@RequestMapping("/flags")
public class FlagController {

    /** Lowercase letters, digits, '-' and '_'; max 64 chars; must start with a letter or digit. */
    private static final Pattern VALID_NAME = Pattern.compile("^[a-z0-9][a-z0-9_-]{0,63}$");

    /** Request body for PUT. {@code enabled} is required; {@code description} is optional. */
    public record FlagUpdate(Boolean enabled, String description) {
    }

    private final FlagService service;

    public FlagController(FlagService service) {
        this.service = service;
    }

    @GetMapping
    public List<Flag> list() {
        return service.findAll();
    }

    @GetMapping("/{name}")
    public Flag get(@PathVariable("name") String name) {
        return service.find(name)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Flag '" + name + "' not found"));
    }

    @PutMapping("/{name}")
    public ResponseEntity<Flag> put(@PathVariable("name") String name,
                                    @RequestBody FlagUpdate body) {
        if (!VALID_NAME.matcher(name).matches()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Flag name must match " + VALID_NAME.pattern());
        }
        if (body.enabled() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "'enabled' is required");
        }

        FlagService.UpsertResult result = service.upsert(name, body.enabled(), body.description());
        HttpStatus status = result.created() ? HttpStatus.CREATED : HttpStatus.OK;
        return ResponseEntity.status(status).body(result.flag());
    }
}
