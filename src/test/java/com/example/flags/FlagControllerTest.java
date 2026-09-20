package com.example.flags;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.hasItem;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class FlagControllerTest {

    @Autowired
    private MockMvc mvc;

    // The store is shared across tests, so each test uses its own flag name.

    @Test
    void listReturnsSeededFlags() throws Exception {
        mvc.perform(get("/flags"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[*].name", hasItem("dark-mode")))
                .andExpect(jsonPath("$[*].name", hasItem("new-checkout")));
    }

    @Test
    void getUnknownFlagReturns404() throws Exception {
        mvc.perform(get("/flags/does-not-exist"))
                .andExpect(status().isNotFound());
    }

    @Test
    void putCreatesThenUpdates() throws Exception {
        mvc.perform(put("/flags/test-toggle")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"enabled\":true,\"description\":\"A test flag\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.enabled").value(true));

        mvc.perform(put("/flags/test-toggle")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"enabled\":false}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.enabled").value(false))
                .andExpect(jsonPath("$.description").value("A test flag"));

        mvc.perform(get("/flags/test-toggle"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.enabled").value(false));
    }

    @Test
    void putWithoutEnabledReturns400() throws Exception {
        mvc.perform(put("/flags/test-missing-enabled")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void putWithInvalidNameReturns400() throws Exception {
        mvc.perform(put("/flags/UPPERCASE")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"enabled\":true}"))
                .andExpect(status().isBadRequest());
    }
}
