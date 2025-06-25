
package com.example;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

public class StringUtilsTest {

    @Test
    public void testIsEmpty() {
        assertTrue(StringUtils.isEmpty(""));
        assertTrue(StringUtils.isEmpty("   "));
        assertFalse(StringUtils.isEmpty("hello"));
    }
}
