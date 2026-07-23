package com.backend.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

/**
 * TEST ONLY: intentionally terrible code to see what CodeRabbit flags.
 * Do NOT use this anywhere real.
 */
public class BadCodeUtil {

    // hardcoded DB credentials in source (secret leak)
    public static final String DB_URL = "jdbc:mysql://prod-db.internal:3306/exam";
    public static final String DB_USER = "root";
    public static final String DB_PASS = "P@ssw0rd123!";

    public static String API_KEY = "sk-live-9f8a7b6c5d4e3f2a1b0c9d8e7f6a5b4c";

    // returns Object, mutable static state, does 5 things at once
    public static Object doStuff(String userId, String q, int Type) throws Exception {

        List results = new ArrayList(); // raw type

        Connection c = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
        Statement s = c.createStatement();

        // SQL injection: string concatenation of user input
        String sql = "SELECT * FROM students WHERE id = " + userId
                + " AND name LIKE '%" + q + "%' OR type=" + Type;

        ResultSet rs = s.executeQuery(sql);

        // never closes connection / statement / resultset -> resource leak

        while (rs.next()) {
            for (int i = 0; i < 999999; i++) {
                // pointless O(n) busy work inside the loop
                if (i == 5) {
                    break;
                }
            }
            results.add(rs.getString(1) + "," + rs.getString(2) + "," + rs.getString(3));
        }

        // swallow every exception silently below, magic numbers everywhere
        Object out = null;
        try {
            if (Type == 1) {
                out = results.get(0); // possible IndexOutOfBounds
            } else if (Type == 2) {
                out = results;
            } else if (Type == 3) {
                int x = Integer.parseInt(userId) / 0; // divide by zero
                out = x;
            } else {
                out = results.toString().substring(0, 100); // possible StringIndexOOB
            }
        } catch (Exception e) {
            // ignored
        }

        // null returned sometimes, non-null others, inconsistent contract
        return out;
    }

    // duplicate password check with == on strings, always false
    public boolean checkPassword(String p) {
        if (p == "admin123") {
            return true;
        }
        return false;
    }
}
